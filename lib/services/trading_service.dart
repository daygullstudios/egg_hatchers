import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/online_trade.dart';
import '../models/owned_animal.dart';
import 'multiplayer_service.dart';

enum TradingConnectionState {
  connecting,
  ready,
  searching,
  trading,
  completed,
  offline,
}

class TradingService extends ChangeNotifier {
  TradingService({Uri? serverUri})
    : serverUri = serverUri ?? MultiplayerService.defaultServerUri();

  final Uri serverUri;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  TradingConnectionState _state = TradingConnectionState.connecting;
  OnlineTradeState? _trade;
  OnlineTradeCompletion? _completion;
  String? _tradeId;
  String? _message;
  var _disposed = false;

  TradingConnectionState get state => _state;
  OnlineTradeState? get trade => _trade;
  OnlineTradeCompletion? get completion => _completion;
  String? get message => _message;

  Future<void> connect() async {
    if (_channel != null || _disposed) return;
    _setState(TradingConnectionState.connecting);
    try {
      final channel = WebSocketChannel.connect(serverUri);
      _channel = channel;
      await channel.ready.timeout(const Duration(seconds: 3));
      _subscription = channel.stream.listen(
        _handleMessage,
        onDone: _handleDisconnect,
        onError: (_) => _handleDisconnect(),
      );
      _message = null;
      _setState(TradingConnectionState.ready);
    } catch (_) {
      _channel = null;
      _message = 'The trading server is not available.';
      _setState(TradingConnectionState.offline);
    }
  }

  void findTrader(OnlineTraderSnapshot trader) {
    if (_state != TradingConnectionState.ready || _channel == null) return;
    _trade = null;
    _completion = null;
    _tradeId = null;
    _channel!.sink.add(jsonEncode({'type': 'queueTrade', ...trader.toJson()}));
    _message = 'Looking for another trader...';
    _setState(TradingConnectionState.searching);
  }

  void joinInvitedTrade(String roomId, OnlineTraderSnapshot trader) {
    if (_state != TradingConnectionState.ready || _channel == null) return;
    _trade = null;
    _completion = null;
    _tradeId = null;
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

  void leaveTrade() => _send('leaveTrade');

  void reset() {
    _trade = null;
    _completion = null;
    _tradeId = null;
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
    if (raw is! String) return;
    final data = jsonDecode(raw) as Map<String, dynamic>;
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
        _message = 'Trade complete!';
        _setState(TradingConnectionState.completed);
      case 'tradeCancelled':
        _trade = null;
        _tradeId = null;
        _message = data['message'] as String? ?? 'The trade was cancelled.';
        _setState(TradingConnectionState.ready);
      case 'error':
        _message = data['message'] as String? ?? 'Trading failed.';
        notifyListeners();
    }
  }

  void _handleDisconnect() {
    if (_disposed) return;
    _channel = null;
    _subscription = null;
    _trade = null;
    _tradeId = null;
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
