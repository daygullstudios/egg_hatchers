import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:egg_hatchers/models/online_trade.dart';
import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/models/player_account.dart';
import 'package:egg_hatchers/services/trading_service.dart';
import 'package:egg_hatchers/services/online_identity_token_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/multiplayer_server.dart';
import 'support/controlled_lobby_channel.dart';

void main() {
  test(
    'hosted trading authenticates and consumes only server inventory',
    () async {
      final channel = ControlledLobbyChannel()..handshake.complete();
      Iterable<String>? openedProtocols;
      final service = TradingService(
        serverUri: Uri.parse(
          'wss://egg-hatchers-playtest.daygullstudios.com/ws',
        ),
        identityTokenProvider: _TokenProvider('firebase-token'),
        hostedTradingEnabled: true,
        channelFactory: (uri, {protocols}) {
          openedProtocols = protocols;
          return channel;
        },
      );
      addTearDown(() {
        service.dispose();
        channel.finish();
      });

      await service.connect();
      expect(openedProtocols, ['nestarium-v1', 'firebase-auth.firebase-token']);
      expect(jsonDecode(channel.sink.messages.single as String), {
        'type': 'getInventory',
      });
      channel.incoming.add(
        jsonEncode({
          'type': 'onlineInventory',
          'revision': 2,
          'items': [
            {
              'animalId': 'rabbit',
              'mutationId': 'none',
              'level': 1,
              'quantity': 2,
            },
          ],
        }),
      );
      expect(service.onlineInventoryRevision, 2);
      expect(service.onlineInventory?.single.animalId, 'rabbit');
      expect(service.onlineInventory?.single.quantity, 2);
    },
  );

  test('two online players complete a confirmed animal trade', () async {
    final webRoot = await Directory.systemTemp.createTemp('egg_trade_web_');
    await File(
      '${webRoot.path}${Platform.pathSeparator}index.html',
    ).writeAsString('Nestarium');
    addTearDown(() => webRoot.delete(recursive: true));
    final server = await LocalMultiplayerServer.start(
      port: 0,
      webRoot: webRoot.path,
    );
    addTearDown(server.close);
    final uri = Uri.parse('ws://127.0.0.1:${server.port}/ws');
    final first = TradingService(serverUri: uri);
    final second = TradingService(serverUri: uri);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await Future.wait([first.connect(), second.connect()]);

    const chicken = OwnedAnimal(animalId: 'chicken', quantity: 2, level: 3);
    const fox = OwnedAnimal(
      animalId: 'fox',
      mutationId: 'golden',
      quantity: 1,
      level: 4,
    );
    first.findTrader(
      OnlineTraderSnapshot(
        account: _account('first', 'First Trader'),
        inventory: const [chicken],
      ),
    );
    second.findTrader(
      OnlineTraderSnapshot(
        account: _account('second', 'Second Trader'),
        inventory: const [fox],
      ),
    );
    await _waitFor(
      () =>
          first.state == TradingConnectionState.trading &&
          second.state == TradingConnectionState.trading,
    );

    expect(first.trade!.opponentInventory.single.animalId, 'fox');
    expect(second.trade!.opponentInventory.single.animalId, 'chicken');
    first.sendChat(TradeChatTag.isThisFair);
    await _waitFor(() => second.chatMessages.isNotEmpty);
    expect(second.chatMessages.last.tag, TradeChatTag.isThisFair);
    expect(second.chatMessages.last.fromSelf, isFalse);
    second.sendChat(TradeChatTag.yes);
    await _waitFor(() => first.chatMessages.length == 2);
    expect(first.chatMessages.last.tag, TradeChatTag.yes);
    first.requestAnimal(fox);
    await _waitFor(() => second.chatMessages.length == 3);
    expect(second.chatMessages.last.tag, TradeChatTag.requestAnimal);
    expect(second.chatMessages.last.animal!.animalId, 'fox');
    expect(second.chatMessages.last.fromSelf, isFalse);

    first.offer(chicken);
    second.offer(fox);
    await _waitFor(
      () =>
          first.trade?.opponentOffer != null &&
          second.trade?.opponentOffer != null,
    );
    first.confirm();
    await _waitFor(() => second.trade?.opponentConfirmed ?? false);
    second.confirm();
    await _waitFor(() => first.completion != null && second.completion != null);

    expect(first.completion!.sent.animalId, 'chicken');
    expect(first.completion!.received.animalId, 'fox');
    expect(second.completion!.sent.animalId, 'fox');
    expect(second.completion!.received.animalId, 'chicken');
    expect(first.completion!.received.quantity, 1);
  });

  test(
    'leaving a live trade notifies the other player of the decline',
    () async {
      final webRoot = await Directory.systemTemp.createTemp('egg_trade_leave_');
      addTearDown(() => webRoot.delete(recursive: true));
      final server = await LocalMultiplayerServer.start(
        port: 0,
        webRoot: webRoot.path,
      );
      addTearDown(server.close);
      final uri = Uri.parse('ws://127.0.0.1:${server.port}/ws');
      final first = TradingService(serverUri: uri);
      final second = TradingService(serverUri: uri);
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      await Future.wait([first.connect(), second.connect()]);
      const chicken = OwnedAnimal(animalId: 'chicken', quantity: 1);
      const fox = OwnedAnimal(animalId: 'fox', quantity: 1);
      first.findTrader(
        OnlineTraderSnapshot(
          account: _account('first', 'First Trader'),
          inventory: const [chicken],
        ),
      );
      second.findTrader(
        OnlineTraderSnapshot(
          account: _account('second', 'Second Trader'),
          inventory: const [fox],
        ),
      );
      await _waitFor(
        () =>
            first.state == TradingConnectionState.trading &&
            second.state == TradingConnectionState.trading,
      );

      second.leaveTrade();
      await _waitFor(() => first.cancellationMessage != null);
      expect(first.cancellationMessage, '@second declined the trade.');
      expect(first.state, TradingConnectionState.ready);
    },
  );
}

class _TokenProvider implements OnlineIdentityTokenProvider {
  const _TokenProvider(this.token);

  final String? token;

  @override
  Future<String?> getIdToken() async => token;
}

PlayerAccount _account(String id, String name) => PlayerAccount(
  id: id,
  displayName: name,
  username: id,
  avatarColorValue: 0xFF5271FF,
  createdAt: DateTime.utc(2026, 8, 27),
);

Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Expected trading state was not reached.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
