import 'dart:async';
import 'dart:io';

import 'package:egg_hatchers/models/online_trade.dart';
import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/models/player_account.dart';
import 'package:egg_hatchers/services/trading_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/multiplayer_server.dart';

void main() {
  test('two online players complete a confirmed animal trade', () async {
    final webRoot = await Directory.systemTemp.createTemp('egg_trade_web_');
    await File(
      '${webRoot.path}${Platform.pathSeparator}index.html',
    ).writeAsString('Egg Hatchers');
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
