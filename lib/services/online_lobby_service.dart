import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/online_lobby.dart';
import '../utils/web_socket_message.dart';
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
  OnlineLobbyNotice? _notice;
  String? _statusMessage;
  String? _presenceSignature;
  OnlineInviteKind? _pendingInviteKind;
  String? _pendingInviteUsername;
  var _nextNoticeId = 1;
  bool _disposed = false;

  OnlineLobbyConnectionState get state => _state;
  List<OnlinePlayerPresence> get players => _players;
  OnlineInvite? get incomingInvite => _incomingInvite;
  OnlineSessionLaunch? get sessionLaunch => _sessionLaunch;
  OnlinePresetMessage? get latestMessage => _latestMessage;
  OnlineLobbyNotice? get notice => _notice;
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
      if (_disposed) {
        _channel = null;
        await channel.sink.close();
        return;
      }
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
      final failedChannel = _channel;
      _channel = null;
      try {
        await failedChannel?.sink.close();
      } catch (_) {}
      if (_disposed) return;
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
    OnlinePlayerPresence? target;
    for (final player in _players) {
      if (player.account.id == playerId) {
        target = player;
        break;
      }
    }
    _pendingInviteKind = kind;
    _pendingInviteUsername = target?.account.username;
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

  void clearNotice() {
    _notice = null;
    notifyListeners();
  }

  void _showNotice(String message, OnlineNoticeType type) {
    _notice = OnlineLobbyNotice(
      id: 'notice_${_nextNoticeId++}',
      message: message,
      type: type,
    );
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
    _notice = null;
    _presenceSignature = null;
    _state = OnlineLobbyConnectionState.disconnected;
    if (!_disposed) notifyListeners();
  }

  void _handleMessage(dynamic raw) {
    final data = decodeWebSocketMessage(raw);
    if (data == null) return;
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
        final kind = OnlineInviteKind.fromWire(
          data['kind'] as String? ?? _pendingInviteKind?.wireName ?? 'battle',
        );
        final username =
            data['targetUsername'] as String? ??
            _pendingInviteUsername ??
            'player';
        if (kind == OnlineInviteKind.trade) {
          _showNotice(
            'Trade sent to @$username successfully',
            OnlineNoticeType.success,
          );
        }
        _pendingInviteKind = null;
        _pendingInviteUsername = null;
      case 'inviteDeclined':
        final kind = OnlineInviteKind.fromWire(
          data['kind'] as String? ?? 'battle',
        );
        final username = data['username'] as String? ?? 'That player';
        _statusMessage = '@$username declined.';
        if (kind == OnlineInviteKind.trade) {
          _showNotice(
            '@$username declined the trade',
            OnlineNoticeType.failure,
          );
        }
      case 'sessionReady':
        _incomingInvite = null;
        _sessionLaunch = OnlineSessionLaunch.fromJson(data);
      case 'presetMessage':
        _latestMessage = OnlinePresetMessage.fromJson(data);
      case 'lobbyError':
        _statusMessage = data['message'] as String? ?? 'Online action failed.';
        if (_pendingInviteKind == OnlineInviteKind.trade ||
            data['kind'] == 'trade') {
          _showNotice('Trade Failed', OnlineNoticeType.failure);
        }
        _pendingInviteKind = null;
        _pendingInviteUsername = null;
    }
    if (!_disposed) notifyListeners();
  }

  void _handleDisconnect() {
    if (_disposed) return;
    _channel = null;
    _subscription = null;
    _players = const [];
    _notice = null;
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
