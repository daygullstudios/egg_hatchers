import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:egg_hatchers/data/arena_ability_data.dart';
import 'package:egg_hatchers/models/arena.dart';
import 'package:egg_hatchers/utils/arena_combat_logic.dart';

const _defaultHost = '127.0.0.1';
const _defaultPort = 53218;

Future<void> main() async {
  final server = await LocalMultiplayerServer.start();
  stdout.writeln(
    'Egg Hatchers match server: ws://${server.host}:${server.port}/ws',
  );
}

class LocalMultiplayerServer {
  LocalMultiplayerServer._(this._server, this._matchmaker);

  final HttpServer _server;
  final _Matchmaker _matchmaker;
  StreamSubscription<HttpRequest>? _requests;

  String get host => _server.address.address;
  int get port => _server.port;

  static Future<LocalMultiplayerServer> start({
    String host = _defaultHost,
    int port = _defaultPort,
  }) async {
    final httpServer = await HttpServer.bind(host, port);
    final matchmaker = _Matchmaker();
    final server = LocalMultiplayerServer._(httpServer, matchmaker);
    server._requests = httpServer.listen(server._handleRequest);
    return server;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (request.uri.path == '/health') {
      request.response
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'status': 'ok',
            'waiting': _matchmaker.waitingCount,
            'matches': _matchmaker.matchCount,
          }),
        );
      await request.response.close();
      return;
    }
    if (request.uri.path != '/ws' ||
        !WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final socket = await WebSocketTransformer.upgrade(request);
    _matchmaker.attach(socket);
  }

  Future<void> close() async {
    _matchmaker.close();
    await _requests?.cancel();
    await _server.close(force: true);
  }
}

class _Matchmaker {
  final List<_QueuedPlayer> _waiting = [];
  final Map<WebSocket, _BattleMatch> _matchesBySocket = {};
  var _nextMatch = 1;

  int get waitingCount => _waiting.length;
  int get matchCount => _matchesBySocket.values.toSet().length;

  void attach(WebSocket socket) {
    socket.listen(
      (raw) => _handle(socket, raw),
      onDone: () => _remove(socket),
      onError: (_) => _remove(socket),
      cancelOnError: true,
    );
  }

  void _handle(WebSocket socket, dynamic raw) {
    if (raw is! String) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final type = data['type'] as String?;
      if (type == 'queue') {
        _queue(socket, Map<String, dynamic>.from(data['player'] as Map));
        return;
      }
      if (type == 'cancel') {
        _waiting.removeWhere((entry) => identical(entry.socket, socket));
        return;
      }
      _matchesBySocket[socket]?.handle(socket, data);
    } catch (_) {
      _send(socket, {'type': 'error', 'message': 'Invalid match request.'});
    }
  }

  void _queue(WebSocket socket, Map<String, dynamic> player) {
    _waiting.removeWhere((entry) => identical(entry.socket, socket));
    if (_matchesBySocket.containsKey(socket)) {
      _send(socket, {'type': 'error', 'message': 'Finish the current match.'});
      return;
    }
    final playerId = player['playerId'] as String?;
    if (playerId == null || (player['team'] as List?)?.length != 3) {
      _send(socket, {'type': 'error', 'message': 'A full team is required.'});
      return;
    }

    final opponentIndex = _waiting.indexWhere(
      (candidate) => candidate.player['playerId'] != playerId,
    );
    if (opponentIndex < 0) {
      _waiting.add(_QueuedPlayer(socket: socket, player: player));
      _send(socket, {'type': 'queued'});
      return;
    }

    final opponent = _waiting.removeAt(opponentIndex);
    final matchId =
        'local_match_${DateTime.now().microsecondsSinceEpoch}_${_nextMatch++}';
    late final _BattleMatch match;
    match = _BattleMatch(
      id: matchId,
      first: opponent,
      second: _QueuedPlayer(socket: socket, player: player),
      onFinished: () => _releaseMatch(match),
    );
    _matchesBySocket[opponent.socket] = match;
    _matchesBySocket[socket] = match;
    _send(socket, {
      'type': 'matched',
      'matchId': matchId,
      'opponent': opponent.player,
    });
    _send(opponent.socket, {
      'type': 'matched',
      'matchId': matchId,
      'opponent': player,
    });
  }

  void _releaseMatch(_BattleMatch match) {
    _matchesBySocket.removeWhere((_, value) => identical(value, match));
  }

  void _remove(WebSocket socket) {
    _waiting.removeWhere((entry) => identical(entry.socket, socket));
    _matchesBySocket[socket]?.disconnect(socket);
  }

  void close() {
    for (final match in _matchesBySocket.values.toSet()) {
      match.close();
    }
    for (final waiting in _waiting) {
      waiting.socket.close();
    }
    _waiting.clear();
    _matchesBySocket.clear();
  }

  void _send(WebSocket socket, Map<String, dynamic> message) {
    if (socket.readyState == WebSocket.open) socket.add(jsonEncode(message));
  }
}

class _BattleMatch {
  _BattleMatch({
    required this.id,
    required _QueuedPlayer first,
    required _QueuedPlayer second,
    required this.onFinished,
  }) : players = [_BattlePlayer(first), _BattlePlayer(second)];

  final String id;
  final List<_BattlePlayer> players;
  final VoidCallback onFinished;
  final Random _random = Random();
  var _started = false;
  var _finished = false;
  var _released = false;
  var _revision = 0;

  void handle(WebSocket socket, Map<String, dynamic> data) {
    final actor = _playerFor(socket);
    if (actor == null || data['matchId'] != id) return;
    switch (data['type']) {
      case 'ready':
        actor.ready = true;
        if (!_started && players.every((player) => player.ready)) _start();
      case 'collectEnergy':
        _collectEnergy(actor, (data['spawnId'] as num?)?.toInt());
      case 'ability':
        _useAbility(actor, (data['abilityIndex'] as num?)?.toInt());
      case 'switch':
        _switchFighter(actor, (data['fighterIndex'] as num?)?.toInt());
      case 'leave':
        disconnect(socket);
    }
  }

  void _start() {
    _started = true;
    _broadcastState('Collect energy and use your abilities!');
    for (final player in players) {
      _scheduleEnergy(player, initial: true);
    }
  }

  void _scheduleEnergy(_BattlePlayer player, {bool initial = false}) {
    player.spawnTimer?.cancel();
    if (_finished) return;
    final delay = initial ? 550 : 380 + _random.nextInt(420);
    player.spawnTimer = Timer(Duration(milliseconds: delay), () {
      if (_finished || player.socket.readyState != WebSocket.open) return;
      final spawnId = ++player.nextSpawnId;
      player.activeSpawnId = spawnId;
      final golden = _random.nextInt(10) == 0;
      player.activeSpawnGolden = golden;
      _send(player.socket, {
        'type': 'energy',
        'id': spawnId,
        'x': 0.12 + _random.nextDouble() * 0.76,
        'y': 0.15 + _random.nextDouble() * 0.70,
        'golden': golden,
      });
      player.expiryTimer = Timer(const Duration(milliseconds: 1150), () {
        if (_finished || player.activeSpawnId != spawnId) return;
        player.activeSpawnId = null;
        player.energyMisses++;
        _send(player.socket, {'type': 'energyGone', 'id': spawnId});
        _broadcastState('Energy missed');
        _scheduleEnergy(player);
      });
    });
  }

  void _collectEnergy(_BattlePlayer actor, int? spawnId) {
    if (!_started || _finished || actor.activeSpawnId != spawnId) return;
    actor.expiryTimer?.cancel();
    actor.activeSpawnId = null;
    final gain = actor.activeSpawnGolden ? 2 : 1;
    actor.energy = min(ArenaCombatLogic.maxEnergy, actor.energy + gain);
    actor.energyHits++;
    _send(actor.socket, {'type': 'energyGone', 'id': spawnId});
    _broadcastState(
      actor.activeSpawnGolden ? '+2 golden energy!' : '+1 energy',
      actorId: actor.id,
    );
    _scheduleEnergy(actor);
  }

  void _useAbility(_BattlePlayer actor, int? abilityIndex) {
    if (!_started || _finished || abilityIndex == null) return;
    final defender = _opponentOf(actor);
    final abilities = ArenaAbilityData.forAnimal(actor.activeFighter.animalId);
    if (abilityIndex < 0 || abilityIndex >= abilities.length) return;
    final ability = abilities[abilityIndex];
    if (actor.energy < ability.energyCost) return;

    actor.energy -= ability.energyCost;
    final damage = ArenaCombatLogic.attackDamage(
      attacker: actor.activeFighter,
      defender: defender.activeFighter,
      ability: ability,
      random: _random,
    );
    final absorbed = min(defender.shield, damage);
    defender.shield -= absorbed;
    final dealt = damage - absorbed;
    defender.health[defender.activeIndex] = max(
      0,
      defender.health[defender.activeIndex] - dealt,
    );
    _applyEffect(actor, defender, ability);

    var message = '${actor.name}: ${ability.name}  -$dealt';
    if (defender.health[defender.activeIndex] == 0) {
      final next = defender.health.indexWhere((health) => health > 0);
      if (next < 0) {
        _finish(actor, '${actor.name} wins the online battle!');
        return;
      }
      defender.activeIndex = next;
      defender.shield = 0;
      message = '$message  |  ${defender.name} sends in the next animal!';
    }
    _broadcastState(message, actorId: actor.id);
  }

  void _applyEffect(
    _BattlePlayer actor,
    _BattlePlayer defender,
    ArenaAbility ability,
  ) {
    final amount = ArenaCombatLogic.supportAmount(actor.activeFighter, ability);
    switch (ability.effect) {
      case ArenaAbilityEffect.damage:
        break;
      case ArenaAbilityEffect.shield:
        actor.shield += amount;
      case ArenaAbilityEffect.heal:
        actor.health[actor.activeIndex] = min(
          actor.activeFighter.maxHealth,
          actor.health[actor.activeIndex] + amount,
        );
      case ArenaAbilityEffect.drain:
        final drained = min(defender.energy, ability.effectScale.round());
        defender.energy -= drained;
        actor.energy = min(ArenaCombatLogic.maxEnergy, actor.energy + drained);
    }
  }

  void _switchFighter(_BattlePlayer actor, int? fighterIndex) {
    if (!_started ||
        _finished ||
        fighterIndex == null ||
        fighterIndex < 0 ||
        fighterIndex >= actor.fighters.length ||
        fighterIndex == actor.activeIndex ||
        actor.health[fighterIndex] <= 0 ||
        actor.energy < ArenaCombatLogic.switchEnergyCost) {
      return;
    }
    actor.energy -= ArenaCombatLogic.switchEnergyCost;
    actor.activeIndex = fighterIndex;
    actor.shield = 0;
    _broadcastState(
      '${actor.name} switched fighters  |  -1 energy',
      actorId: actor.id,
    );
  }

  void _finish(_BattlePlayer winner, String message) {
    if (_finished) return;
    _finished = true;
    for (final player in players) {
      player.cancelTimers();
    }
    _broadcastState(message, actorId: winner.id, winnerId: winner.id);
    _release();
  }

  void disconnect(WebSocket socket) {
    final leaving = _playerFor(socket);
    if (leaving == null) return;
    if (!_finished) {
      final winner = _opponentOf(leaving);
      _finish(winner, '${leaving.name} disconnected. ${winner.name} wins!');
    } else {
      _release();
    }
  }

  void _broadcastState(String message, {String? actorId, String? winnerId}) {
    _revision++;
    for (final player in players) {
      final opponent = _opponentOf(player);
      _send(player.socket, {
        'type': 'battleState',
        'matchId': id,
        'revision': _revision,
        'message': message,
        'lastActorId': actorId,
        'winnerId': winnerId,
        'self': player.toStateJson(),
        'opponent': opponent.toStateJson(),
      });
    }
  }

  _BattlePlayer? _playerFor(WebSocket socket) {
    for (final player in players) {
      if (identical(player.socket, socket)) return player;
    }
    return null;
  }

  _BattlePlayer _opponentOf(_BattlePlayer player) =>
      identical(players.first, player) ? players.last : players.first;

  void _release() {
    if (_released) return;
    _released = true;
    onFinished();
  }

  void close() {
    for (final player in players) {
      player.cancelTimers();
      player.socket.close();
    }
    _release();
  }

  void _send(WebSocket socket, Map<String, dynamic> message) {
    if (socket.readyState == WebSocket.open) socket.add(jsonEncode(message));
  }
}

class _BattlePlayer {
  _BattlePlayer(_QueuedPlayer queued)
    : socket = queued.socket,
      player = queued.player,
      fighters = (queued.player['team'] as List<dynamic>)
          .map((item) {
            final fighter = Map<String, dynamic>.from(item as Map);
            return ArenaFighter(
              animalId: fighter['animalId'] as String,
              mutationId: fighter['mutationId'] as String,
              level: (fighter['level'] as num).toInt(),
              power: (fighter['power'] as num).toInt(),
            );
          })
          .toList(growable: false) {
    health = fighters.map((fighter) => fighter.maxHealth).toList();
  }

  final WebSocket socket;
  final Map<String, dynamic> player;
  final List<ArenaFighter> fighters;
  late final List<int> health;
  bool ready = false;
  int activeIndex = 0;
  int energy = 0;
  int shield = 0;
  int energyHits = 0;
  int energyMisses = 0;
  int nextSpawnId = 0;
  int? activeSpawnId;
  bool activeSpawnGolden = false;
  Timer? spawnTimer;
  Timer? expiryTimer;

  String get id => player['playerId'] as String;
  String get name => player['displayName'] as String;
  ArenaFighter get activeFighter => fighters[activeIndex];

  Map<String, dynamic> toStateJson() => {
    'health': health,
    'activeIndex': activeIndex,
    'energy': energy,
    'shield': shield,
    'energyHits': energyHits,
    'energyMisses': energyMisses,
  };

  void cancelTimers() {
    spawnTimer?.cancel();
    expiryTimer?.cancel();
  }
}

class _QueuedPlayer {
  const _QueuedPlayer({required this.socket, required this.player});

  final WebSocket socket;
  final Map<String, dynamic> player;
}

typedef VoidCallback = void Function();
