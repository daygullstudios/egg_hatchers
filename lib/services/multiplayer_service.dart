import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/multiplayer.dart';

enum MultiplayerConnectionState {
  connecting,
  ready,
  searching,
  matched,
  offline,
}

class MultiplayerService extends ChangeNotifier {
  MultiplayerService({Uri? serverUri})
    : serverUri = serverUri ?? defaultServerUri();

  final Uri serverUri;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  MultiplayerConnectionState _state = MultiplayerConnectionState.connecting;
  MultiplayerPlayerSnapshot? _opponent;
  String? _matchId;
  String? _message;
  MultiplayerBattleState? _battleState;
  MultiplayerEnergySpawn? _energySpawn;
  bool _disposed = false;

  MultiplayerConnectionState get state => _state;
  MultiplayerPlayerSnapshot? get opponent => _opponent;
  String? get matchId => _matchId;
  String? get message => _message;
  MultiplayerBattleState? get battleState => _battleState;
  MultiplayerEnergySpawn? get energySpawn => _energySpawn;
  bool get isConnected =>
      _state != MultiplayerConnectionState.connecting &&
      _state != MultiplayerConnectionState.offline;

  static Uri defaultServerUri() {
    if (kIsWeb) {
      final host = Uri.base.host.isEmpty ? '127.0.0.1' : Uri.base.host;
      final localHost =
          host == '127.0.0.1' || host == 'localhost' || host == '::1';
      return Uri(
        scheme: Uri.base.scheme == 'https' ? 'wss' : 'ws',
        host: host,
        port: localHost ? 53218 : (Uri.base.hasPort ? Uri.base.port : null),
        path: '/ws',
      );
    }
    return Uri.parse('ws://127.0.0.1:53218/ws');
  }

  Future<void> connect() async {
    if (_channel != null || _disposed) return;
    _setState(MultiplayerConnectionState.connecting);
    try {
      final channel = WebSocketChannel.connect(serverUri);
      _channel = channel;
      await channel.ready.timeout(const Duration(seconds: 3));
      if (_disposed) {
        await channel.sink.close();
        return;
      }
      _subscription = channel.stream.listen(
        _handleMessage,
        onError: (_) => _handleDisconnect(),
        onDone: _handleDisconnect,
      );
      _message = null;
      _setState(MultiplayerConnectionState.ready);
    } catch (_) {
      _channel = null;
      _message = 'The local match server is not running.';
      _setState(MultiplayerConnectionState.offline);
    }
  }

  Future<void> retry() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    await connect();
  }

  void findMatch(MultiplayerPlayerSnapshot player) {
    if (_state != MultiplayerConnectionState.ready || _channel == null) return;
    _opponent = null;
    _matchId = null;
    _battleState = null;
    _energySpawn = null;
    _channel!.sink.add(
      jsonEncode({'type': 'queue', 'player': player.toJson()}),
    );
    _message = 'Looking for another player...';
    _setState(MultiplayerConnectionState.searching);
  }

  void joinInvitedMatch(String roomId, MultiplayerPlayerSnapshot player) {
    if (_state != MultiplayerConnectionState.ready || _channel == null) return;
    _opponent = null;
    _matchId = null;
    _battleState = null;
    _energySpawn = null;
    _channel!.sink.add(
      jsonEncode({
        'type': 'joinBattleInvite',
        'roomId': roomId,
        'player': player.toJson(),
      }),
    );
    _message = 'Joining invited battle...';
    _setState(MultiplayerConnectionState.searching);
  }

  void cancelSearch() {
    if (_state != MultiplayerConnectionState.searching || _channel == null) {
      return;
    }
    _channel!.sink.add(jsonEncode({'type': 'cancel'}));
    _message = null;
    _setState(MultiplayerConnectionState.ready);
  }

  void clearMatch() {
    _opponent = null;
    _matchId = null;
    _message = null;
    _battleState = null;
    _energySpawn = null;
    if (_channel != null) _setState(MultiplayerConnectionState.ready);
  }

  void enterBattle() => _sendMatchMessage('ready');

  void collectEnergy(int spawnId) {
    _sendMatchMessage('collectEnergy', {'spawnId': spawnId});
  }

  void useAbility(int abilityIndex) {
    _sendMatchMessage('ability', {'abilityIndex': abilityIndex});
  }

  void switchFighter(int fighterIndex) {
    _sendMatchMessage('switch', {'fighterIndex': fighterIndex});
  }

  void leaveBattle() => _sendMatchMessage('leave');

  void _sendMatchMessage(String type, [Map<String, dynamic>? payload]) {
    if (_channel == null || _matchId == null) return;
    _channel!.sink.add(
      jsonEncode({'type': type, 'matchId': _matchId, ...?payload}),
    );
  }

  void _handleMessage(dynamic raw) {
    if (raw is! String) return;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    switch (data['type']) {
      case 'queued':
        _message =
            data['message'] as String? ??
            'Waiting for a nearby-ranked player...';
        _setState(MultiplayerConnectionState.searching);
      case 'matched':
        _matchId = data['matchId'] as String;
        _opponent = MultiplayerPlayerSnapshot.fromJson(
          Map<String, dynamic>.from(data['opponent'] as Map),
        );
        _message = 'Opponent found!';
        _setState(MultiplayerConnectionState.matched);
      case 'battleState':
        _battleState = MultiplayerBattleState.fromJson(data);
        _message = _battleState!.message;
        notifyListeners();
      case 'energy':
        _energySpawn = MultiplayerEnergySpawn.fromJson(data);
        notifyListeners();
      case 'energyGone':
        final id = (data['id'] as num?)?.toInt();
        if (id == null || _energySpawn?.id == id) {
          _energySpawn = null;
          notifyListeners();
        }
      case 'error':
        _message = data['message'] as String? ?? 'Matchmaking failed.';
        _setState(MultiplayerConnectionState.ready);
    }
  }

  void _handleDisconnect() {
    if (_disposed) return;
    _subscription = null;
    _channel = null;
    _opponent = null;
    _matchId = null;
    _battleState = null;
    _energySpawn = null;
    _message = 'Connection to the match server was lost.';
    _setState(MultiplayerConnectionState.offline);
  }

  void _setState(MultiplayerConnectionState value) {
    _state = value;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
