import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:egg_hatchers/models/online_trade.dart';
import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/models/player_account.dart';
import 'package:egg_hatchers/screens/online_trading_screen.dart';
import 'package:egg_hatchers/services/custom_sprite_service.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/online_identity_token_provider.dart';
import 'package:egg_hatchers/services/preferences_service.dart';
import 'package:egg_hatchers/services/trading_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tool/multiplayer_server.dart';
import 'support/controlled_lobby_channel.dart';

void main() {
  testWidgets('hosted trading shows the server roster, not local animals', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    final channel = ControlledLobbyChannel()..handshake.complete();
    final trading = TradingService(
      serverUri: Uri.parse('wss://egg-hatchers-playtest.daygullstudios.com/ws'),
      identityTokenProvider: const _TokenProvider('firebase-token'),
      hostedTradingEnabled: true,
      channelFactory: (uri, {protocols}) => channel,
    );
    final game = GameService();
    final preferences = PreferencesService();
    final sprites = CustomSpriteService();
    await tester.runAsync(() async {
      await Future.wait([
        game.initialize(),
        preferences.initialize(),
        sprites.initialize(),
        trading.connect(),
      ]);
      game.devSetOwnedAnimalsForTesting(const [
        OwnedAnimal(animalId: 'chicken', quantity: 2),
      ]);
      channel.incoming.add(
        jsonEncode({
          'type': 'onlineInventory',
          'revision': 1,
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
    });
    addTearDown(() {
      trading.dispose();
      channel.finish();
      game.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: OnlineTradingScreen(
          game: game,
          account: _account('hosted', 'Hosted Trader'),
          theme: preferences.selectedTheme,
          customSprites: sprites,
          trading: trading,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('online-trade-roster-notice')), findsOne);
    expect(find.textContaining('Online Roster stacks'), findsOne);
    await tester.scrollUntilVisible(
      find.text('Rabbit'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Rabbit'), findsOne);
    expect(find.text('Chicken'), findsNothing);
    expect(tester.takeException(), isNull);

    channel.incoming.add(
      jsonEncode({
        'type': 'tradeComplete',
        'receiptId': 'trade-1:hosted',
        'tradeId': 'trade-1',
        'sent': {
          'animalId': 'rabbit',
          'mutationId': 'none',
          'level': 1,
          'quantity': 1,
        },
        'received': {
          'animalId': 'mouse',
          'mutationId': 'none',
          'level': 1,
          'quantity': 1,
        },
      }),
    );
    await tester.pump();
    expect(game.state.ownedAnimals, hasLength(1));
    expect(game.state.ownedAnimals.single.animalId, 'chicken');
    expect(game.state.ownedAnimals.single.quantity, 2);
  });

  testWidgets('online trading lobby fits a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    late LocalMultiplayerServer server;
    late TradingService trading;
    final game = GameService();
    final preferences = PreferencesService();
    final sprites = CustomSpriteService();
    await tester.runAsync(() async {
      final webRoot = await Directory.systemTemp.createTemp('trade_screen_');
      addTearDown(() => webRoot.delete(recursive: true));
      server = await LocalMultiplayerServer.start(
        port: 0,
        webRoot: webRoot.path,
      );
      trading = TradingService(
        serverUri: Uri.parse('ws://127.0.0.1:${server.port}/ws'),
      );
      await Future.wait([
        game.initialize(),
        preferences.initialize(),
        sprites.initialize(),
        trading.connect(),
      ]);
    });
    addTearDown(server.close);
    addTearDown(trading.dispose);
    addTearDown(game.dispose);
    game.devSetOwnedAnimalsForTesting(const [
      OwnedAnimal(animalId: 'chicken', quantity: 2),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: OnlineTradingScreen(
          game: game,
          account: PlayerAccount(
            id: 'trader',
            displayName: 'Test Trader',
            username: 'test_trader',
            avatarColorValue: 0xFF5271FF,
            createdAt: DateTime.utc(2026, 8, 27),
          ),
          theme: preferences.selectedTheme,
          customSprites: sprites,
          trading: trading,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Online Trading'), findsOneWidget);
    expect(find.text('FIND TRADER'), findsOneWidget);
    expect(find.text('Chicken'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('structured trade chat and animal requests fit a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    late LocalMultiplayerServer server;
    late TradingService firstTrading;
    late TradingService secondTrading;
    final game = GameService();
    final preferences = PreferencesService();
    final sprites = CustomSpriteService();
    final firstAccount = _account('first', 'First Trader');
    final secondAccount = _account('second', 'Second Trader');
    const chicken = OwnedAnimal(animalId: 'chicken', quantity: 2, level: 3);
    const fox = OwnedAnimal(animalId: 'fox', quantity: 1, level: 4);
    await tester.runAsync(() async {
      final webRoot = await Directory.systemTemp.createTemp('trade_chat_');
      addTearDown(() => webRoot.delete(recursive: true));
      server = await LocalMultiplayerServer.start(
        port: 0,
        webRoot: webRoot.path,
      );
      final uri = Uri.parse('ws://127.0.0.1:${server.port}/ws');
      firstTrading = TradingService(serverUri: uri);
      secondTrading = TradingService(serverUri: uri);
      await Future.wait([
        game.initialize(),
        preferences.initialize(),
        sprites.initialize(),
        firstTrading.connect(),
        secondTrading.connect(),
      ]);
      game.devSetOwnedAnimalsForTesting(const [chicken]);
      firstTrading.findTrader(
        OnlineTraderSnapshot(account: firstAccount, inventory: const [chicken]),
      );
      secondTrading.findTrader(
        OnlineTraderSnapshot(account: secondAccount, inventory: const [fox]),
      );
      await _waitFor(
        () =>
            firstTrading.state == TradingConnectionState.trading &&
            secondTrading.state == TradingConnectionState.trading,
      );
    });
    addTearDown(server.close);
    addTearDown(firstTrading.dispose);
    addTearDown(secondTrading.dispose);
    addTearDown(game.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: OnlineTradingScreen(
          game: game,
          account: firstAccount,
          theme: preferences.selectedTheme,
          customSprites: sprites,
          trading: firstTrading,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const ValueKey('trade-chat-panel')), findsOneWidget);
    expect(find.text('YES'), findsOneWidget);
    expect(find.text('NO'), findsOneWidget);
    expect(find.text('IS THIS FAIR?'), findsOneWidget);
    await tester.ensureVisible(find.text('REQUEST ANIMAL'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('REQUEST ANIMAL'));
    await tester.pumpAndSettle();
    expect(find.text('Request from Second Trader'), findsOneWidget);
    expect(find.text('Fox'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _TokenProvider implements OnlineIdentityTokenProvider {
  const _TokenProvider(this.token);

  final String? token;

  @override
  Future<String?> getIdToken() async => token;
}

PlayerAccount _account(String id, String displayName) => PlayerAccount(
  id: id,
  displayName: displayName,
  username: id,
  avatarColorValue: 0xFF5271FF,
  createdAt: DateTime.utc(2026, 8, 27),
);

Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Expected trade state was not reached.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
