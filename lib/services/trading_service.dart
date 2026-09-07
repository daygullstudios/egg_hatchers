import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/online_trade.dart';
import '../models/owned_animal.dart';
import '../utils/web_socket_message.dart';
import 'multiplayer_service.dart';
import 'online_identity_token_provider.dart';

enum TradingConnectionState {
  connecting,
  ready,
  searching,
  trading,
  completed,
  offline,
}

class TradingService extends ChangeNotifier {
  TradingService({
    Uri? serverUri,
    OnlineIdentityTokenProvider? identityTokenProvider,
    MultiplayerChannelFactory? channelFactory,
    bool? hostedTradingEnabled,
  }) : serverUri = serverUri ?? MultiplayerService.defaultServerUri(),
       _identityTokenProvider =
           identityTokenProvider ?? FirebaseOnlineIdentityTokenProvider(),
       _channelFactory = channelFactory ?? WebSocketChannel.connect,
       _hostedTradingEnabled =
           hostedTradingEnabled ?? MultiplayerService.hostedTradingBuildEnabled;

  final Uri serverUri;
  final OnlineIdentityTokenProvider _identityTokenProvider;
  final MultiplayerChannelFactory _channelFactory;
  final bool _hostedTradingEnabled;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  TradingConnectionState _state = TradingConnectionState.connecting;
  OnlineTradeState? _trade;
  OnlineTradeCompletion? _completion;
  String? _tradeId;
  String? _message;
  String? _cancellationMessage;
  List<OwnedAnimal>? _onlineInventory;
  int? _onlineInventoryRevision;
  String? _completionReceiptId;
  final List<TradeChatMessage> _chatMessages = [];
  var _disposed = false;

  TradingConnectionState get state => _state;
  OnlineTradeState? get trade => _trade;
  OnlineTradeCompletion? get completion => _completion;
  String? get message => _message;
  String? get cancellationMessage => _cancellationMessage;
  List<TradeChatMessage> get chatMessages => List.unmodifiable(_chatMessages);
  bool get isHostedServer => !MultiplayerService.isLocalServerUri(serverUri);
  List<OwnedAnimal>? get onlineInventory => _onlineInventory == null
      ? null
      : List<OwnedAnimal>.unmodifiable(_onlineInventory!);
  int? get onlineInventoryRevision => _onlineInventoryRevision;

  Future<void> connect() async {
    if (_channel != null || _disposed) return;
    _setState(TradingConnectionState.connecting);
    try {
      final channel = await _openChannel();
      _channel = channel;
      await channel.ready.timeout(const Duration(seconds: 3));
      if (_disposed) {
        _channel = null;
        await channel.sink.close();
        return;
      }
      _message = null;
      _setState(TradingConnectionState.ready);
      _subscription = channel.stream.listen(
        _handleMessage,
        onDone: _handleDisconnect,
        onError: (_) => _handleDisconnect(),
      );
      if (isHostedServer) {
        channel.sink.add(jsonEncode({'type': 'getInventory'}));
      }
    } catch (_) {
      final failedChannel = _channel;
      _channel = null;
      try {
        await failedChannel?.sink.close();
      } catch (_) {}
      if (_disposed) return;
      _message = 'The trading server is not available.';
      _setState(TradingConnectionState.offline);
    }
  }

  Future<WebSocketChannel> _openChannel() async {
    if (!isHostedServer) return _channelFactory(serverUri);
    if (!_hostedTradingEnabled) {
      throw StateError('Hosted trading is not released');
    }
    final token = await _identityTokenProvider.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('A restored cloud identity is required');
    }
    return _channelFactory(
      serverUri,
      protocols: ['nestarium-v1', 'firebase-auth.$token'],
    );
  }

  void findTrader(OnlineTraderSnapshot trader) {
    if (_state != TradingConnectionState.ready || _channel == null) return;
    _trade = null;
    _completion = null;
    _tradeId = null;
    _chatMessages.clear();
    _cancellationMessage = null;
    _completionReceiptId = null;
    _channel!.sink.add(jsonEncode({'type': 'queueTrade', ...trader.toJson()}));
    _message = 'Looking for another trader...';
    _setState(TradingConnectionState.searching);
  }

  void joinInvitedTrade(String roomId, OnlineTraderSnapshot trader) {
    if (_state != TradingConnectionState.ready || _channel == null) return;
    _trade = null;
    _completion = null;
    _tradeId = null;
    _chatMessages.clear();
    _cancellationMessage = null;
    _completionReceiptId = null;
    _channel!.sink.add(
      jsonEncode({
        'type': 'joinTradeInvite',
        'roomId': roomId,
        ...trader.toJson(),
      }),
    );
    _message = 'Joining invited trade...';
    _setState(TradingConnectionState.searching);
  }

  void cancelSearch() {
    if (_state != TradingConnectionState.searching) return;
    _channel?.sink.add(jsonEncode({'type': 'cancelTrade'}));
    _message = null;
    _setState(TradingConnectionState.ready);
  }

  void offer(OwnedAnimal animal) {
    _send('tradeOffer', {'animal': animal.copyWith(quantity: 1).toJson()});
  }

  void confirm() => _send('tradeConfirm');

  void sendChat(TradeChatTag tag) {
    if (tag == TradeChatTag.requestAnimal) return;
    _send('tradeChat', {'tag': tag.wireName});
  }

  void requestAnimal(OwnedAnimal animal) {
    _send('tradeChat', {
      'tag': TradeChatTag.requestAnimal.wireName,
      'animal': animal.copyWith(quantity: 1).toJson(),
    });
  }

  void leaveTrade() => _send('leaveTrade');

  void acknowledgeCompletion() {
    final receiptId = _completionReceiptId;
    if (receiptId == null || _channel == null) return;
    _channel!.sink.add(
      jsonEncode({'type': 'ackTrade', 'receiptId': receiptId}),
    );
    _completionReceiptId = null;
  }

  void reset() {
    _trade = null;
    _completion = null;
    _tradeId = null;
    _chatMessages.clear();
    _cancellationMessage = null;
    _completionReceiptId = null;
    _message = null;
    if (_channel != null) _setState(TradingConnectionState.ready);
  }

  void _send(String type, [Map<String, dynamic>? payload]) {
    if (_channel == null || _tradeId == null) return;
    _channel!.sink.add(
      jsonEncode({'type': type, 'tradeId': _tradeId, ...?payload}),
    );
  }

  void _handleMessage(dynamic raw) {
    final data = decodeWebSocketMessage(raw);
    if (data == null) return;
    switch (data['type']) {
      case 'tradeQueued':
        _message = 'Waiting for another trader...';
        _setState(TradingConnectionState.searching);
      case 'tradeState':
        _tradeId = data['tradeId'] as String;
        _trade = OnlineTradeState.fromJson(data);
        _message = _trade!.message;
        _setState(TradingConnectionState.trading);
      case 'tradeComplete':
        _completion = OnlineTradeCompletion.fromJson(data);
        _completionReceiptId = data['receiptId'] as String?;
        _message = 'Trade complete!';
        _setState(TradingConnectionState.completed);
      case 'onlineInventory':
        final items = data['items'];
        if (items is! List) return;
        try {
          _onlineInventory = items
              .map(
                (item) => OwnedAnimal.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(growable: false);
          _onlineInventoryRevision = (data['revision'] as num?)?.toInt();
          notifyListeners();
        } catch (_) {
          _message = 'Your Online Roster could not be verified.';
          notifyListeners();
        }
      case 'tradeChat':
        _chatMessages.add(TradeChatMessage.fromJson(data));
        if (_chatMessages.length > 20) _chatMessages.removeAt(0);
        notifyListeners();
      case 'tradeCancelled':
        _trade = null;
        _tradeId = null;
        _message = data['message'] as String? ?? 'The trade was cancelled.';
        _cancellationMessage = _message;
        _setState(TradingConnectionState.ready);
      case 'error':
        _message = data['message'] as String? ?? 'Trading failed.';
        if (_state == TradingConnectionState.searching) {
          _setState(TradingConnectionState.ready);
        } else {
          notifyListeners();
        }
    }
  }

  void _handleDisconnect() {
    if (_disposed) return;
    _channel = null;
    _subscription = null;
    _trade = null;
    _tradeId = null;
    _chatMessages.clear();
    _cancellationMessage = null;
    _message = 'Connection to the trading server was lost.';
    _setState(TradingConnectionState.offline);
  }

  void _setState(TradingConnectionState value) {
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
