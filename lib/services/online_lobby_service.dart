import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/online_lobby.dart';
import '../utils/web_socket_message.dart';
import 'multiplayer_service.dart';

enum OnlineLobbyConnectionState { disconnected, connecting, online }

class OnlineLobbyService extends ChangeNotifier {
  OnlineLobbyService({
    Uri? serverUri,
    WebSocketChannel Function(Uri)? channelFactory,
  }) : serverUri = serverUri ?? MultiplayerService.defaultServerUri(),
       _channelFactory = channelFactory ?? WebSocketChannel.connect;

  final Uri serverUri;
  final WebSocketChannel Function(Uri) _channelFactory;
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
  String? _pendingPresence;
  var _connectionRevision = 0;
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
    if (_disposed) return;
    if (_channel != null) {
      updatePresence(presence);
      return;
    }
    final revision = ++_connectionRevision;
    _pendingPresence = jsonEncode(presence.toJson());
    _state = OnlineLobbyConnectionState.connecting;
    notifyListeners();
    try {
      final channel = _channelFactory(serverUri);
      _channel = channel;
      // Listen during the handshake too: failed sockets can emit both a ready
      // error and a stream error. Obsolete callbacks never own a newer socket.
      _subscription = channel.stream.listen(
        (raw) {
          if (_ownsConnection(revision)) _handleMessage(raw);
        },
        onDone: () => _handleDisconnect(revision),
        onError: (_) => _handleDisconnect(revision),
      );
      await channel.ready.timeout(const Duration(seconds: 4));
      if (!_ownsConnection(revision)) return;
      _state = OnlineLobbyConnectionState.online;
      _sendPendingPresence();
      _statusMessage = null;
      notifyListeners();
    } catch (_) {
      // The factory can throw before assigning a channel. That is still this
      // attempt's failure, unlike a callback from an already retired socket.
      if (_disposed || revision != _connectionRevision) return;
      _detachConnection();
      _statusMessage = 'Online lobby is unavailable.';
      notifyListeners();
    }
  }

  void updatePresence(OnlinePresenceSnapshot presence) {
    if (_disposed) return;
    final signature = jsonEncode(presence.toJson());
    if (_channel == null) {
      unawaited(connect(presence));
      return;
    }
    _pendingPresence = signature;
    if (_state == OnlineLobbyConnectionState.online) _sendPendingPresence();
  }

  bool _ownsConnection(int revision) =>
      !_disposed && revision == _connectionRevision && _channel != null;

  void _sendPendingPresence() {
    final signature = _pendingPresence;
    if (signature == null || signature == _presenceSignature) return;
    _channel!.sink.add(
      jsonEncode({
        'type': 'registerPresence',
        ...jsonDecode(signature) as Map<String, dynamic>,
      }),
    );
    _presenceSignature = signature;
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
    _detachConnection();
    _statusMessage = null;
    if (!_disposed) notifyListeners();
  }

  void _detachConnection() {
    // Retire ownership synchronously. A server/transport may never acknowledge
    // close; player switching must not await it or let it clear a new session.
    _connectionRevision++;
    final subscription = _subscription;
    final channel = _channel;
    _subscription = null;
    _channel = null;
    _players = const [];
    _incomingInvite = null;
    _sessionLaunch = null;
    _latestMessage = null;
    _notice = null;
    _presenceSignature = null;
    _pendingPresence = null;
    _pendingInviteKind = null;
    _pendingInviteUsername = null;
    _state = OnlineLobbyConnectionState.disconnected;
    // Both operations must start even if the other never completes. Catch
    // synchronous and asynchronous transport failures without exposing data.
    unawaited(_release(() => subscription?.cancel()));
    unawaited(_release(() => channel?.sink.close()));
  }

  Future<void> _release(Future<dynamic>? Function() close) async {
    try {
      await close();
    } catch (_) {
      // Retired connection; no player action or retry is needed here.
    }
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

  void _handleDisconnect(int revision) {
    if (!_ownsConnection(revision)) return;
    _detachConnection();
    _statusMessage = 'Online lobby connection was lost.';
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _detachConnection();
    super.dispose();
  }
}
