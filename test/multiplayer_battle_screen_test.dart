import 'dart:async';

import 'package:egg_hatchers/models/arena.dart';
import 'package:egg_hatchers/models/multiplayer.dart';
import 'package:egg_hatchers/models/player_account.dart';
import 'package:egg_hatchers/screens/multiplayer_battle_screen.dart';
import 'package:egg_hatchers/services/custom_sprite_service.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/multiplayer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tool/multiplayer_server.dart';

void main() {
  testWidgets('online battle fits a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late LocalMultiplayerServer server;
    late MultiplayerService first;
    late MultiplayerService second;
    late MultiplayerPlayerSnapshot firstPlayer;
    late MultiplayerPlayerSnapshot secondPlayer;
    late CustomSpriteService sprites;
    late GameService game;
    await tester.runAsync(() async {
      server = await LocalMultiplayerServer.start(port: 0);
      final uri = Uri.parse('ws://127.0.0.1:${server.port}/ws');
      first = MultiplayerService(serverUri: uri);
      second = MultiplayerService(serverUri: uri);
      await Future.wait([first.connect(), second.connect()]);
      firstPlayer = _player('first', 'First Player');
      secondPlayer = _player('second', 'Second Player');
      first.findMatch(firstPlayer);
      second.findMatch(secondPlayer);
      await _waitFor(() => first.opponent != null && second.opponent != null);
      first.enterBattle();
      second.enterBattle();
      await _waitFor(() => first.battleState != null);

      SharedPreferences.setMockInitialValues({});
      game = GameService();
      sprites = CustomSpriteService();
      await Future.wait([game.initialize(), sprites.initialize()]);
    });
    addTearDown(server.close);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    addTearDown(game.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiplayerBattleScreen(
          multiplayer: first,
          game: game,
          player: firstPlayer,
          opponent: secondPlayer,
          customSprites: sprites,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('ONLINE MATCH'), findsOneWidget);
    expect(find.text('First Player'), findsOneWidget);
    expect(find.text('Second Player'), findsOneWidget);
    expect(find.text('2 ENERGY'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

MultiplayerPlayerSnapshot _player(String id, String name) {
  return MultiplayerPlayerSnapshot.fromPlayer(
    account: PlayerAccount(
      id: id,
      displayName: name,
      username: id,
      avatarColorValue: 0xFF5271FF,
      createdAt: DateTime.utc(2026, 8, 27),
    ),
    rating: 1000,
    team: const [
      ArenaFighter(animalId: 'chicken', mutationId: 'none', level: 1, power: 1),
      ArenaFighter(animalId: 'fox', mutationId: 'none', level: 1, power: 2),
      ArenaFighter(animalId: 'dragon', mutationId: 'none', level: 1, power: 3),
    ],
  );
}

Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Expected multiplayer state was not reached.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
