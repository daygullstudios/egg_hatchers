import 'dart:io';

import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/models/player_account.dart';
import 'package:egg_hatchers/screens/online_trading_screen.dart';
import 'package:egg_hatchers/services/custom_sprite_service.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/preferences_service.dart';
import 'package:egg_hatchers/services/trading_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tool/multiplayer_server.dart';

void main() {
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
}
