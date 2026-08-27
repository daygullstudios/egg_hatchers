import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/online_lobby.dart';
import 'multiplayer_service.dart';

enum OnlineLobbyConnectionState { disconnected, connecting, online }

class OnlineLobbyService extends ChangeNotifier {
  OnlineLobbyService({Uri? serverUri})
    : serverUri = serverUri ?? MultiplayerService.defaultServerUri();

  final Uri serverUri;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  OnlineLobbyConnectionState _state = OnlineLobbyConnectionState.disconnected;
  List<OnlinePlayerPresence> _players = const [];
  OnlineInvite? _incomingInvite;
  OnlineSessionLaunch? _sessionLaunch;
  OnlinePresetMessage? _latestMessage;
  String? _statusMessage;
  String? _presenceSignature;
  bool _disposed = false;

  OnlineLobbyConnectionState get state => _state;
  List<OnlinePlayerPresence> get players => _players;
  OnlineInvite? get incomingInvite => _incomingInvite;
  OnlineSessionLaunch? get sessionLaunch => _sessionLaunch;
  OnlinePresetMessage? get latestMessage => _latestMessage;
  String? get statusMessage => _statusMessage;

  Future<void> connect(OnlinePresenceSnapshot presence) async {
    final signature = jsonEncode(presence.toJson());
    if (_channel != null) {
      updatePresence(presence);
      return;
    }
    if (_disposed) return;
    _state = OnlineLobbyConnectionState.connecting;
    notifyListeners();
    try {
      final channel = WebSocketChannel.connect(serverUri);
      _channel = channel;
      await channel.ready.timeout(const Duration(seconds: 4));
      _subscription = channel.stream.listen(
        _handleMessage,
        onDone: _handleDisconnect,
        onError: (_) => _handleDisconnect(),
      );
      _presenceSignature = signature;
      channel.sink.add(
        jsonEncode({'type': 'registerPresence', ...presence.toJson()}),
      );
      _state = OnlineLobbyConnectionState.online;
      _statusMessage = null;
      notifyListeners();
    } catch (_) {
      _channel = null;
      _state = OnlineLobbyConnectionState.disconnected;
      _statusMessage = 'Online lobby is unavailable.';
      notifyListeners();
    }
  }

  void updatePresence(OnlinePresenceSnapshot presence) {
    final signature = jsonEncode(presence.toJson());
    if (_channel == null) {
      unawaited(connect(presence));
      return;
    }
    if (signature == _presenceSignature) return;
    _presenceSignature = signature;
    _channel!.sink.add(
      jsonEncode({'type': 'registerPresence', ...presence.toJson()}),
    );
  }

  void invite(String playerId, OnlineInviteKind kind) {
    _channel?.sink.add(
      jsonEncode({
        'type': 'sendInvite',
        'targetPlayerId': playerId,
        'kind': kind.wireName,
      }),
    );
  }

  void respondToInvite(bool accept) {
    final invite = _incomingInvite;
    if (invite == null) return;
    _channel?.sink.add(
      jsonEncode({
        'type': 'respondInvite',
        'inviteId': invite.id,
        'accept': accept,
      }),
    );
    _incomingInvite = null;
    notifyListeners();
  }

  void sendPresetMessage(String playerId, String tag) {
    if (!onlineMessageTags.containsKey(tag)) return;
    _channel?.sink.add(
      jsonEncode({
        'type': 'presetMessage',
        'targetPlayerId': playerId,
        'tag': tag,
      }),
    );
  }

  void clearSessionLaunch() => _sessionLaunch = null;

  void clearLatestMessage() {
    _latestMessage = null;
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _players = const [];
    _incomingInvite = null;
    _sessionLaunch = null;
    _latestMessage = null;
    _presenceSignature = null;
    _state = OnlineLobbyConnectionState.disconnected;
    if (!_disposed) notifyListeners();
  }

  void _handleMessage(dynamic raw) {
    if (raw is! String) return;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    switch (data['type']) {
      case 'presenceList':
        _players = (data['players'] as List<dynamic>? ?? const [])
            .map(
              (item) => OnlinePlayerPresence.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(growable: false);
      case 'inviteReceived':
        _incomingInvite = OnlineInvite.fromJson(data);
      case 'inviteSent':
        _statusMessage = 'Invitation sent.';
      case 'inviteDeclined':
        _statusMessage = '${data['displayName'] ?? 'That player'} declined.';
      case 'sessionReady':
        _incomingInvite = null;
        _sessionLaunch = OnlineSessionLaunch.fromJson(data);
      case 'presetMessage':
        _latestMessage = OnlinePresetMessage.fromJson(data);
      case 'lobbyError':
        _statusMessage = data['message'] as String? ?? 'Online action failed.';
    }
    if (!_disposed) notifyListeners();
  }

  void _handleDisconnect() {
    if (_disposed) return;
    _channel = null;
    _subscription = null;
    _players = const [];
    _state = OnlineLobbyConnectionState.disconnected;
    _statusMessage = 'Online lobby connection was lost.';
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
