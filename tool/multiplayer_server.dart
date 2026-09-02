import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:egg_hatchers/data/arena_ability_data.dart';
import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/models/arena.dart';
import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/utils/arena_combat_logic.dart';
import 'package:egg_hatchers/utils/battle_power_logic.dart';

const _defaultHost = '127.0.0.1';
const _defaultPort = 53218;

Future<void> main(List<String> args) async {
  final config = MultiplayerServerConfig.fromArgs(
    args,
    environment: Platform.environment,
  );
  final server = await LocalMultiplayerServer.start(
    host: config.host,
    port: config.port,
    webRoot: config.webRoot,
  );
  stdout.writeln(
    'Egg Hatchers match server: ws://${server.host}:${server.port}/ws',
  );
}

class MultiplayerServerConfig {
  const MultiplayerServerConfig({
    required this.host,
    required this.port,
    required this.webRoot,
  });

  final String host;
  final int port;
  final String webRoot;

  factory MultiplayerServerConfig.fromArgs(
    List<String> args, {
    Map<String, String> environment = const {},
  }) {
    final options = <String, String>{};
    for (var index = 0; index < args.length; index++) {
      final argument = args[index];
      if (!argument.startsWith('--')) {
        throw FormatException('Unexpected server argument: $argument');
      }
      final equalsIndex = argument.indexOf('=');
      if (equalsIndex > 2) {
        options[argument.substring(2, equalsIndex)] = argument.substring(
          equalsIndex + 1,
        );
        continue;
      }
      final name = argument.substring(2);
      if (index + 1 >= args.length || args[index + 1].startsWith('--')) {
        throw FormatException('Missing value for --$name');
      }
      options[name] = args[++index];
    }

    const supportedOptions = {'host', 'port', 'web-root'};
    final unknownOptions = options.keys.where(
      (name) => !supportedOptions.contains(name),
    );
    if (unknownOptions.isNotEmpty) {
      throw FormatException('Unknown server option: --${unknownOptions.first}');
    }

    final host =
        options['host'] ??
        environment['EGG_HATCHERS_HOST'] ??
        environment['HOST'] ??
        _defaultHost;
    final portValue =
        options['port'] ??
        environment['EGG_HATCHERS_PORT'] ??
        environment['PORT'] ??
        '$_defaultPort';
    final port = int.tryParse(portValue);
    if (port == null || port < 0 || port > 65535) {
      throw FormatException('Invalid server port: $portValue');
    }
    final webRoot =
        options['web-root'] ??
        environment['EGG_HATCHERS_WEB_ROOT'] ??
        environment['WEB_ROOT'] ??
        'build/web';
    if (host.trim().isEmpty || webRoot.trim().isEmpty) {
      throw const FormatException('Server host and web root cannot be empty.');
    }
    return MultiplayerServerConfig(
      host: host.trim(),
      port: port,
      webRoot: webRoot.trim(),
    );
  }
}

class LocalMultiplayerServer {
  LocalMultiplayerServer._(this._server, this._matchmaker, this._webRoot);

  final HttpServer _server;
  final _Matchmaker _matchmaker;
  final Directory _webRoot;
  StreamSubscription<HttpRequest>? _requests;

  String get host => _server.address.address;
  int get port => _server.port;

  static Future<LocalMultiplayerServer> start({
    String host = _defaultHost,
    int port = _defaultPort,
    String webRoot = 'build/web',
  }) async {
    final httpServer = await HttpServer.bind(host, port);
    final matchmaker = _Matchmaker();
    final server = LocalMultiplayerServer._(
      httpServer,
      matchmaker,
      Directory(webRoot).absolute,
    );
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
            'online': _matchmaker.onlineCount,
          }),
        );
      await request.response.close();
      return;
    }
    if (request.uri.path == '/ws' &&
        WebSocketTransformer.isUpgradeRequest(request)) {
      final socket = await WebSocketTransformer.upgrade(request);
      _matchmaker.attach(socket);
      return;
    }

    await _serveWebAsset(request);
  }

  Future<void> _serveWebAsset(HttpRequest request) async {
    if (request.method != 'GET' && request.method != 'HEAD') {
      request.response.statusCode = HttpStatus.methodNotAllowed;
      await request.response.close();
      return;
    }
    final segments = request.uri.pathSegments;
    if (segments.any(
      (segment) =>
          segment == '..' || segment.contains('\\') || segment.contains(':'),
    )) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }
    final relativePath = segments.isEmpty
        ? 'index.html'
        : segments.join(Platform.pathSeparator);
    var file = File('${_webRoot.path}${Platform.pathSeparator}$relativePath');
    if (!await file.exists() &&
        segments.isNotEmpty &&
        !segments.last.contains('.')) {
      file = File('${_webRoot.path}${Platform.pathSeparator}index.html');
    }
    if (!await file.exists()) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    request.response.headers
      ..contentType = _contentTypeFor(file.path)
      ..set(HttpHeaders.cacheControlHeader, 'no-cache');
    if (request.method == 'GET') {
      await request.response.addStream(file.openRead());
    }
    await request.response.close();
  }

  Future<void> close() async {
    _matchmaker.close();
    await _requests?.cancel();
    await _server.close(force: true);
  }
}

ContentType _contentTypeFor(String path) {
  final extension = path.split('.').last.toLowerCase();
  return switch (extension) {
    'html' => ContentType.html,
    'js' => ContentType('text', 'javascript', charset: 'utf-8'),
    'json' || 'map' => ContentType.json,
    'css' => ContentType('text', 'css', charset: 'utf-8'),
    'svg' => ContentType('image', 'svg+xml'),
    'png' => ContentType('image', 'png'),
    'jpg' || 'jpeg' => ContentType('image', 'jpeg'),
    'webp' => ContentType('image', 'webp'),
    'gif' => ContentType('image', 'gif'),
    'ico' => ContentType('image', 'x-icon'),
    'wasm' => ContentType('application', 'wasm'),
    'mp3' => ContentType('audio', 'mpeg'),
    'wav' => ContentType('audio', 'wav'),
    _ => ContentType.binary,
  };
}

class _Matchmaker {
  _Matchmaker() {
    _matchTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tryMatches(),
    );
  }

  final List<_QueuedPlayer> _waiting = [];
  final Map<WebSocket, _BattleMatch> _matchesBySocket = {};
  final List<_QueuedTrader> _tradeWaiting = [];
  final Map<WebSocket, _TradeSession> _tradesBySocket = {};
  final Map<WebSocket, _PresenceClient> _presenceBySocket = {};
  final Map<String, _LobbyInvite> _invites = {};
  final Map<String, _DirectRoom> _directRooms = {};
  late final Timer _matchTimer;
  var _nextMatch = 1;

  int get waitingCount => _waiting.length;
  int get matchCount => _matchesBySocket.values.toSet().length;
  int get onlineCount =>
      _presenceBySocket.values.map((entry) => entry.playerId).toSet().length;

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
      if (type == 'registerPresence') {
        _registerPresence(socket, data);
        return;
      }
      if (type == 'sendInvite') {
        _sendInvite(socket, data);
        return;
      }
      if (type == 'respondInvite') {
        _respondInvite(socket, data);
        return;
      }
      if (type == 'presetMessage') {
        _sendPresetMessage(socket, data);
        return;
      }
      if (type == 'joinBattleInvite') {
        _joinBattleInvite(
          socket,
          data['roomId'] as String?,
          Map<String, dynamic>.from(data['player'] as Map),
        );
        return;
      }
      if (type == 'joinTradeInvite') {
        _joinTradeInvite(
          socket,
          data['roomId'] as String?,
          Map<String, dynamic>.from(data['player'] as Map),
          (data['inventory'] as List<dynamic>)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList(growable: false),
        );
        return;
      }
      if (type == 'queue') {
        _queue(socket, Map<String, dynamic>.from(data['player'] as Map));
        return;
      }
      if (type == 'cancel') {
        _waiting.removeWhere((entry) => identical(entry.socket, socket));
        return;
      }
      if (type == 'queueTrade') {
        _queueTrade(
          socket,
          Map<String, dynamic>.from(data['player'] as Map),
          (data['inventory'] as List<dynamic>)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList(growable: false),
        );
        return;
      }
      if (type == 'cancelTrade') {
        _tradeWaiting.removeWhere((entry) => identical(entry.socket, socket));
        return;
      }
      final trade = _tradesBySocket[socket];
      if (trade != null) {
        trade.handle(socket, data);
        return;
      }
      _matchesBySocket[socket]?.handle(socket, data);
    } catch (_) {
      _send(socket, {'type': 'error', 'message': 'Invalid match request.'});
    }
  }

  void _registerPresence(WebSocket socket, Map<String, dynamic> data) {
    final account = _validatedAccount(data['account']);
    final team = _validatedTeam(data['team'], requireFullTeam: false);
    final animals = _validatedInventory(data['animals']);
    if (account == null || team == null || animals == null) {
      _send(socket, {
        'type': 'lobbyError',
        'message': 'Invalid player profile.',
      });
      return;
    }
    final player = <String, dynamic>{
      'account': account,
      'rating': _validatedRating(data['rating']),
      'team': team,
      'animals': animals,
    };
    _presenceBySocket[socket] = _PresenceClient(socket, player);
    _broadcastPresence();
  }

  void _broadcastPresence() {
    final latestByPlayer = <String, _PresenceClient>{};
    for (final client in _presenceBySocket.values) {
      latestByPlayer[client.playerId] = client;
    }
    for (final client in _presenceBySocket.values) {
      _send(client.socket, {
        'type': 'presenceList',
        'players': latestByPlayer.values
            .where((other) => other.playerId != client.playerId)
            .map((other) => other.player)
            .toList(growable: false),
      });
    }
  }

  _PresenceClient? _presenceForPlayer(String? playerId) {
    if (playerId == null) return null;
    for (final client in _presenceBySocket.values.toList().reversed) {
      if (client.playerId == playerId) return client;
    }
    return null;
  }

  void _sendInvite(WebSocket socket, Map<String, dynamic> data) {
    final sender = _presenceBySocket[socket];
    final target = _presenceForPlayer(data['targetPlayerId'] as String?);
    final kind = data['kind'] == 'trade' ? 'trade' : 'battle';
    if (sender == null ||
        target == null ||
        sender.playerId == target.playerId) {
      _send(socket, {
        'type': 'lobbyError',
        'kind': kind,
        'message': 'That player is no longer online.',
      });
      return;
    }
    final eligible = kind == 'battle'
        ? (target.player['team'] as List).length == 3
        : (target.player['animals'] as List).cast<Map<String, dynamic>>().any(
            _isTradableAnimal,
          );
    if (!eligible) {
      _send(socket, {
        'type': 'lobbyError',
        'kind': kind,
        'message': 'That player is not ready for this activity.',
      });
      return;
    }
    _invites.removeWhere(
      (_, invite) =>
          invite.sender.playerId == sender.playerId &&
          invite.target.playerId == target.playerId &&
          invite.kind == kind,
    );
    final inviteId =
        'invite_${DateTime.now().microsecondsSinceEpoch}_${_nextMatch++}';
    final invite = _LobbyInvite(inviteId, kind, sender, target);
    _invites[inviteId] = invite;
    _send(target.socket, {
      'type': 'inviteReceived',
      'inviteId': inviteId,
      'kind': kind,
      'from': sender.account,
    });
    _send(socket, {
      'type': 'inviteSent',
      'inviteId': inviteId,
      'kind': kind,
      'targetUsername': target.account['username'],
    });
  }

  void _respondInvite(WebSocket socket, Map<String, dynamic> data) {
    final invite = _invites.remove(data['inviteId'] as String?);
    if (invite == null || !identical(invite.target.socket, socket)) {
      _send(socket, {
        'type': 'lobbyError',
        'message': 'That invitation expired.',
      });
      return;
    }
    if (data['accept'] != true) {
      _send(invite.sender.socket, {
        'type': 'inviteDeclined',
        'displayName': invite.target.account['displayName'],
        'username': invite.target.account['username'],
        'kind': invite.kind,
      });
      return;
    }
    final roomId =
        'room_${DateTime.now().microsecondsSinceEpoch}_${_nextMatch++}';
    _directRooms[roomId] = _DirectRoom(roomId, invite.kind, {
      invite.sender.playerId,
      invite.target.playerId,
    });
    _sendSessionReady(invite.sender, invite.target, invite.kind, roomId);
    _sendSessionReady(invite.target, invite.sender, invite.kind, roomId);
  }

  void _sendSessionReady(
    _PresenceClient recipient,
    _PresenceClient opponent,
    String kind,
    String roomId,
  ) {
    _send(recipient.socket, {
      'type': 'sessionReady',
      'roomId': roomId,
      'kind': kind,
      'opponent': opponent.account,
    });
  }

  void _sendPresetMessage(WebSocket socket, Map<String, dynamic> data) {
    const allowedTags = {'hello', 'good_luck', 'nice_team', 'good_game'};
    final sender = _presenceBySocket[socket];
    final target = _presenceForPlayer(data['targetPlayerId'] as String?);
    final tag = data['tag'] as String?;
    if (sender == null || target == null || !allowedTags.contains(tag)) {
      _send(socket, {
        'type': 'lobbyError',
        'message': 'Message could not be sent.',
      });
      return;
    }
    _send(target.socket, {
      'type': 'presetMessage',
      'from': sender.account,
      'tag': tag,
    });
  }

  void _joinBattleInvite(
    WebSocket socket,
    String? roomId,
    Map<String, dynamic> player,
  ) {
    final room = _directRooms[roomId];
    final validatedPlayer = _validatedBattlePlayer(player);
    final playerId = validatedPlayer?['playerId'] as String?;
    if (room == null ||
        room.kind != 'battle' ||
        !room.playerIds.contains(playerId)) {
      _send(socket, {
        'type': 'error',
        'message': 'This battle invitation expired.',
      });
      return;
    }
    room.battlePlayers[playerId!] = _QueuedPlayer(
      socket: socket,
      player: validatedPlayer!,
      queuedAt: DateTime.now(),
    );
    _send(socket, {'type': 'queued', 'message': 'Joining invited battle...'});
    if (room.battlePlayers.length == 2) {
      final players = room.battlePlayers.values.toList(growable: false);
      _directRooms.remove(room.id);
      _createMatch(players[0], players[1]);
    }
  }

  void _joinTradeInvite(
    WebSocket socket,
    String? roomId,
    Map<String, dynamic> player,
    List<Map<String, dynamic>> inventory,
  ) {
    final room = _directRooms[roomId];
    final validatedPlayer = _validatedAccount(player);
    final validatedInventory = _validatedInventory(inventory);
    final playerId = validatedPlayer?['id'] as String?;
    final eligibleInventory = (validatedInventory ?? const [])
        .where(_isTradableAnimal)
        .toList(growable: false);
    if (room == null ||
        room.kind != 'trade' ||
        !room.playerIds.contains(playerId)) {
      _send(socket, {
        'type': 'error',
        'message': 'This trade invitation expired.',
      });
      return;
    }
    if (eligibleInventory.isEmpty) {
      _send(socket, {
        'type': 'error',
        'message': 'You need a tradable animal.',
      });
      return;
    }
    room.tradePlayers[playerId!] = _QueuedTrader(
      socket: socket,
      player: validatedPlayer!,
      inventory: eligibleInventory,
    );
    _send(socket, {'type': 'tradeQueued'});
    if (room.tradePlayers.length == 2) {
      final players = room.tradePlayers.values.toList(growable: false);
      _directRooms.remove(room.id);
      final tradeId =
          'trade_${DateTime.now().microsecondsSinceEpoch}_${_nextMatch++}';
      late final _TradeSession session;
      session = _TradeSession(
        id: tradeId,
        first: players[0],
        second: players[1],
        onFinished: () => _releaseTrade(session),
      );
      _tradesBySocket[players[0].socket] = session;
      _tradesBySocket[players[1].socket] = session;
      session.start();
    }
  }

  void _queueTrade(
    WebSocket socket,
    Map<String, dynamic> player,
    List<Map<String, dynamic>> inventory,
  ) {
    _tradeWaiting.removeWhere((entry) => identical(entry.socket, socket));
    if (_matchesBySocket.containsKey(socket) ||
        _tradesBySocket.containsKey(socket)) {
      _send(socket, {
        'type': 'error',
        'message': 'Finish your current online session first.',
      });
      return;
    }
    final validatedPlayer = _validatedAccount(player);
    final validatedInventory = _validatedInventory(inventory);
    final playerId = validatedPlayer?['id'] as String?;
    final eligibleInventory = (validatedInventory ?? const [])
        .where(_isTradableAnimal)
        .toList(growable: false);
    if (playerId == null || eligibleInventory.isEmpty) {
      _send(socket, {
        'type': 'error',
        'message': 'You need a tradable animal to enter.',
      });
      return;
    }
    final opponentIndex = _tradeWaiting.indexWhere(
      (candidate) => candidate.player['id'] != playerId,
    );
    final trader = _QueuedTrader(
      socket: socket,
      player: validatedPlayer!,
      inventory: eligibleInventory,
    );
    if (opponentIndex < 0) {
      _tradeWaiting.add(trader);
      _send(socket, {'type': 'tradeQueued'});
      return;
    }
    final opponent = _tradeWaiting.removeAt(opponentIndex);
    final tradeId =
        'trade_${DateTime.now().microsecondsSinceEpoch}_${_nextMatch++}';
    late final _TradeSession session;
    session = _TradeSession(
      id: tradeId,
      first: opponent,
      second: trader,
      onFinished: () => _releaseTrade(session),
    );
    _tradesBySocket[opponent.socket] = session;
    _tradesBySocket[socket] = session;
    session.start();
  }

  void _releaseTrade(_TradeSession session) {
    _tradesBySocket.removeWhere((_, value) => identical(value, session));
  }

  void _queue(WebSocket socket, Map<String, dynamic> player) {
    _waiting.removeWhere((entry) => identical(entry.socket, socket));
    if (_matchesBySocket.containsKey(socket)) {
      _send(socket, {'type': 'error', 'message': 'Finish the current match.'});
      return;
    }
    final validatedPlayer = _validatedBattlePlayer(player);
    final playerId = validatedPlayer?['playerId'] as String?;
    if (playerId == null) {
      _send(socket, {'type': 'error', 'message': 'A full team is required.'});
      return;
    }

    final rating = validatedPlayer!['rating'] as int;
    _waiting.add(
      _QueuedPlayer(
        socket: socket,
        player: validatedPlayer,
        queuedAt: DateTime.now(),
      ),
    );
    _send(socket, {
      'type': 'queued',
      'message': 'Searching near your $rating rating...',
    });
    _tryMatches();
  }

  void _tryMatches() {
    while (true) {
      var firstIndex = -1;
      var secondIndex = -1;
      var closestGap = 1 << 30;
      final now = DateTime.now();
      for (var i = 0; i < _waiting.length; i++) {
        for (var j = i + 1; j < _waiting.length; j++) {
          final first = _waiting[i];
          final second = _waiting[j];
          if (first.player['playerId'] == second.player['playerId']) continue;
          final gap = (first.rating - second.rating).abs();
          final allowedGap = min(
            _allowedRatingGap(first, now),
            _allowedRatingGap(second, now),
          );
          if (gap <= allowedGap && gap < closestGap) {
            firstIndex = i;
            secondIndex = j;
            closestGap = gap;
          }
        }
      }
      if (firstIndex < 0) return;
      final second = _waiting.removeAt(secondIndex);
      final first = _waiting.removeAt(firstIndex);
      _createMatch(first, second);
    }
  }

  int _allowedRatingGap(_QueuedPlayer player, DateTime now) {
    final steps = now.difference(player.queuedAt).inSeconds ~/ 5;
    return (100 + steps * 50).clamp(100, 400);
  }

  void _createMatch(_QueuedPlayer opponent, _QueuedPlayer challenger) {
    final socket = challenger.socket;
    final player = challenger.player;
    final matchId =
        'local_match_${DateTime.now().microsecondsSinceEpoch}_${_nextMatch++}';
    late final _BattleMatch match;
    match = _BattleMatch(
      id: matchId,
      first: opponent,
      second: challenger,
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
    _tradeWaiting.removeWhere((entry) => identical(entry.socket, socket));
    _matchesBySocket[socket]?.disconnect(socket);
    _tradesBySocket[socket]?.disconnect(socket);
    final presence = _presenceBySocket.remove(socket);
    if (presence != null) {
      _invites.removeWhere(
        (_, invite) =>
            invite.sender.playerId == presence.playerId ||
            invite.target.playerId == presence.playerId,
      );
      _broadcastPresence();
    }
  }

  void close() {
    _matchTimer.cancel();
    for (final match in _matchesBySocket.values.toSet()) {
      match.close();
    }
    for (final waiting in _waiting) {
      waiting.socket.close();
    }
    for (final trade in _tradesBySocket.values.toSet()) {
      trade.close();
    }
    for (final waiting in _tradeWaiting) {
      waiting.socket.close();
    }
    for (final client in _presenceBySocket.values) {
      client.socket.close();
    }
    _waiting.clear();
    _tradeWaiting.clear();
    _matchesBySocket.clear();
    _tradesBySocket.clear();
    _presenceBySocket.clear();
    _invites.clear();
    _directRooms.clear();
  }

  void _send(WebSocket socket, Map<String, dynamic> message) {
    if (socket.readyState == WebSocket.open) socket.add(jsonEncode(message));
  }
}

class _PresenceClient {
  const _PresenceClient(this.socket, this.player);

  final WebSocket socket;
  final Map<String, dynamic> player;

  String get playerId => account['id'] as String;
  Map<String, dynamic> get account =>
      Map<String, dynamic>.from(player['account'] as Map);
}

class _LobbyInvite {
  const _LobbyInvite(this.id, this.kind, this.sender, this.target);
  final String id;
  final String kind;
  final _PresenceClient sender;
  final _PresenceClient target;
}

class _DirectRoom {
  _DirectRoom(this.id, this.kind, this.playerIds);
  final String id;
  final String kind;
  final Set<String> playerIds;
  final Map<String, _QueuedPlayer> battlePlayers = {};
  final Map<String, _QueuedTrader> tradePlayers = {};
}

const _maxOnlineLevel = 1000000;
const _maxOnlineInventoryEntries = 512;

Map<String, dynamic>? _validatedAccount(dynamic raw) {
  if (raw is! Map) return null;
  final account = Map<String, dynamic>.from(raw);
  final id = account['id'];
  final displayName = account['displayName'];
  final username = account['username'];
  final avatarColorValue = account['avatarColorValue'];
  final createdAt = account['createdAt'];
  if (id is! String || id.isEmpty || id.length > 128) return null;
  if (displayName is! String ||
      displayName.trim().length < 2 ||
      displayName.trim().length > 20) {
    return null;
  }
  if (username is! String || !RegExp(r'^[a-z0-9_]{3,16}$').hasMatch(username)) {
    return null;
  }
  if (avatarColorValue is! num ||
      createdAt is! String ||
      DateTime.tryParse(createdAt) == null) {
    return null;
  }
  return {
    'id': id,
    'displayName': displayName.trim(),
    'username': username,
    'avatarColorValue': avatarColorValue.toInt(),
    'createdAt': createdAt,
  };
}

int _validatedRating(dynamic raw) =>
    ((raw as num?)?.toInt() ?? 1000).clamp(0, 100000);

Map<String, dynamic>? _validatedBattlePlayer(Map<String, dynamic> raw) {
  final playerId = raw['playerId'];
  final displayName = raw['displayName'];
  final username = raw['username'];
  final avatarColorValue = raw['avatarColorValue'];
  final team = _validatedTeam(raw['team'], requireFullTeam: true);
  if (playerId is! String || playerId.isEmpty || playerId.length > 128) {
    return null;
  }
  if (displayName is! String ||
      displayName.trim().length < 2 ||
      displayName.trim().length > 20) {
    return null;
  }
  if (username is! String || !RegExp(r'^[a-z0-9_]{3,16}$').hasMatch(username)) {
    return null;
  }
  if (avatarColorValue is! num || team == null) return null;
  return {
    'playerId': playerId,
    'displayName': displayName.trim(),
    'username': username,
    'avatarColorValue': avatarColorValue.toInt(),
    'rating': _validatedRating(raw['rating']),
    'team': team,
  };
}

List<Map<String, dynamic>>? _validatedTeam(
  dynamic raw, {
  required bool requireFullTeam,
}) {
  if (raw is! List || raw.length > 3) return null;
  if (requireFullTeam && raw.length != 3) return null;
  final team = <Map<String, dynamic>>[];
  for (final item in raw) {
    if (item is! Map) return null;
    final fighter = Map<String, dynamic>.from(item);
    final animalId = fighter['animalId'];
    final mutationId = fighter['mutationId'];
    final level = (fighter['level'] as num?)?.toInt();
    if (animalId is! String ||
        GameData.animalById(animalId) == null ||
        mutationId is! String ||
        GameData.mutationById(mutationId) == null ||
        level == null ||
        level < 1 ||
        level > _maxOnlineLevel) {
      return null;
    }
    final owned = OwnedAnimal(
      animalId: animalId,
      quantity: 1,
      level: level,
      mutationId: mutationId,
    );
    team.add({
      'animalId': animalId,
      'mutationId': mutationId,
      'level': level,
      'power': BattlePowerLogic.battlePowerForOwnedAnimal(owned),
    });
  }
  return team;
}

List<Map<String, dynamic>>? _validatedInventory(dynamic raw) {
  if (raw is! List || raw.length > _maxOnlineInventoryEntries) return null;
  final inventory = <Map<String, dynamic>>[];
  for (final item in raw) {
    if (item is! Map) return null;
    final animal = Map<String, dynamic>.from(item);
    final animalId = animal['animalId'];
    final mutationId = animal['mutationId'] ?? 'none';
    final quantity = (animal['quantity'] as num?)?.toInt();
    final level = (animal['level'] as num?)?.toInt() ?? 1;
    final sourceEggId = animal['sourceEggId'];
    if (animalId is! String ||
        GameData.animalById(animalId) == null ||
        mutationId is! String ||
        GameData.mutationById(mutationId) == null ||
        quantity == null ||
        quantity < 1 ||
        level < 1 ||
        level > _maxOnlineLevel ||
        (sourceEggId != null &&
            (sourceEggId is! String || sourceEggId.length > 128))) {
      return null;
    }
    inventory.add({
      'animalId': animalId,
      'quantity': quantity,
      'level': level,
      'mutationId': mutationId,
      'isProtected': animal['isProtected'] == true,
      'isSecretReward': animal['isSecretReward'] == true,
      'isEliteReward':
          animal['isEliteReward'] == true ||
          GameData.bossVictoryRewardAnimalIds.contains(animalId),
      'sourceEggId': ?sourceEggId,
    });
  }
  return inventory;
}

bool _isTradableAnimal(Map<String, dynamic> animal) {
  final quantity = (animal['quantity'] as num?)?.toInt() ?? 0;
  return quantity > 0 &&
      !GameData.bossVictoryRewardAnimalIds.contains(animal['animalId']) &&
      animal['isProtected'] != true &&
      animal['isSecretReward'] != true &&
      animal['isEliteReward'] != true;
}

bool _sameTradeAnimal(Map<String, dynamic> first, Map<String, dynamic> second) {
  return first['animalId'] == second['animalId'] &&
      (first['mutationId'] ?? 'none') == (second['mutationId'] ?? 'none') &&
      (first['level'] ?? 1) == (second['level'] ?? 1) &&
      first['sourceEggId'] == second['sourceEggId'];
}

Map<String, dynamic> _singleTradeAnimal(Map<String, dynamic> animal) => {
  ...animal,
  'quantity': 1,
  'isProtected': false,
  'isSecretReward': false,
  'isEliteReward': false,
};

class _TradeSession {
  _TradeSession({
    required this.id,
    required _QueuedTrader first,
    required _QueuedTrader second,
    required this.onFinished,
  }) : players = [_TradePlayer(first), _TradePlayer(second)];

  final String id;
  final List<_TradePlayer> players;
  final VoidCallback onFinished;
  var _finished = false;
  var _nextChatId = 1;

  void start() => _broadcast('Choose an animal to offer.');

  void handle(WebSocket socket, Map<String, dynamic> data) {
    if (_finished || data['tradeId'] != id) return;
    final actor = _playerFor(socket);
    if (actor == null) return;
    switch (data['type']) {
      case 'tradeOffer':
        final requested = Map<String, dynamic>.from(data['animal'] as Map);
        final inventoryIndex = actor.inventory.indexWhere(
          (animal) => _sameTradeAnimal(animal, requested),
        );
        if (inventoryIndex < 0) {
          _send(socket, {
            'type': 'error',
            'message': 'That animal is no longer available to trade.',
          });
          return;
        }
        actor.offer = _singleTradeAnimal(actor.inventory[inventoryIndex]);
        for (final player in players) {
          player.confirmed = false;
        }
        _broadcast('${actor.name} updated their offer.');
      case 'tradeConfirm':
        if (players.any((player) => player.offer == null)) return;
        actor.confirmed = true;
        if (players.every((player) => player.confirmed)) {
          _complete();
        } else {
          _broadcast('${actor.name} confirmed the trade.');
        }
      case 'tradeChat':
        _handleChat(actor, data);
      case 'leaveTrade':
        disconnect(socket);
    }
  }

  void _handleChat(_TradePlayer actor, Map<String, dynamic> data) {
    const allowedTags = {'yes', 'no', 'is_this_fair', 'request_animal'};
    final tag = data['tag'] as String?;
    if (!allowedTags.contains(tag)) {
      _send(actor.socket, {
        'type': 'error',
        'message': 'That trade message is not allowed.',
      });
      return;
    }
    Map<String, dynamic>? animal;
    if (tag == 'request_animal') {
      final rawAnimal = data['animal'];
      if (rawAnimal is! Map) return;
      final requested = Map<String, dynamic>.from(rawAnimal);
      final opponent = _opponentOf(actor);
      final index = opponent.inventory.indexWhere(
        (owned) => _sameTradeAnimal(owned, requested),
      );
      if (index < 0) {
        _send(actor.socket, {
          'type': 'error',
          'message': 'That animal is no longer available.',
        });
        return;
      }
      animal = _singleTradeAnimal(opponent.inventory[index]);
    }
    final chatId = '${id}_chat_${_nextChatId++}';
    for (final player in players) {
      _send(player.socket, {
        'type': 'tradeChat',
        'tradeId': id,
        'chatId': chatId,
        'tag': tag,
        'fromSelf': identical(player, actor),
        'animal': ?animal,
      });
    }
  }

  void _complete() {
    _finished = true;
    for (final player in players) {
      final opponent = _opponentOf(player);
      _send(player.socket, {
        'type': 'tradeComplete',
        'tradeId': id,
        'sent': player.offer,
        'received': opponent.offer,
      });
    }
    onFinished();
  }

  void _broadcast(String message) {
    for (final player in players) {
      final opponent = _opponentOf(player);
      _send(player.socket, {
        'type': 'tradeState',
        'tradeId': id,
        'opponent': opponent.player,
        'selfOffer': player.offer,
        'opponentOffer': opponent.offer,
        'selfConfirmed': player.confirmed,
        'opponentConfirmed': opponent.confirmed,
        'message': message,
        'opponentInventory': opponent.inventory
            .where(_isTradableAnimal)
            .map(_singleTradeAnimal)
            .toList(growable: false),
      });
    }
  }

  void disconnect(WebSocket socket) {
    if (_finished) return;
    _finished = true;
    final actor = _playerFor(socket);
    if (actor != null) {
      final opponent = _opponentOf(actor);
      _send(opponent.socket, {
        'type': 'tradeCancelled',
        'message': '@${actor.username} declined the trade.',
      });
    }
    onFinished();
  }

  _TradePlayer? _playerFor(WebSocket socket) {
    for (final player in players) {
      if (identical(player.socket, socket)) return player;
    }
    return null;
  }

  _TradePlayer _opponentOf(_TradePlayer player) =>
      identical(players.first, player) ? players.last : players.first;

  void close() {
    _finished = true;
    for (final player in players) {
      player.socket.close();
    }
    onFinished();
  }

  void _send(WebSocket socket, Map<String, dynamic> message) {
    if (socket.readyState == WebSocket.open) socket.add(jsonEncode(message));
  }
}

class _TradePlayer {
  _TradePlayer(_QueuedTrader queued)
    : socket = queued.socket,
      player = queued.player,
      inventory = queued.inventory;

  final WebSocket socket;
  final Map<String, dynamic> player;
  final List<Map<String, dynamic>> inventory;
  Map<String, dynamic>? offer;
  bool confirmed = false;

  String get name => player['displayName'] as String;
  String get username => player['username'] as String;
}

class _QueuedTrader {
  const _QueuedTrader({
    required this.socket,
    required this.player,
    required this.inventory,
  });

  final WebSocket socket;
  final Map<String, dynamic> player;
  final List<Map<String, dynamic>> inventory;
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
        player.combo = 0;
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
    actor.combo++;
    actor.bestCombo = max(actor.bestCombo, actor.combo);
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
  int combo = 0;
  int bestCombo = 0;
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
    'combo': combo,
    'bestCombo': bestCombo,
  };

  void cancelTimers() {
    spawnTimer?.cancel();
    expiryTimer?.cancel();
  }
}

class _QueuedPlayer {
  const _QueuedPlayer({
    required this.socket,
    required this.player,
    required this.queuedAt,
  });

  final WebSocket socket;
  final Map<String, dynamic> player;
  final DateTime queuedAt;

  int get rating => (player['rating'] as num?)?.toInt() ?? 1000;
}

typedef VoidCallback = void Function();
