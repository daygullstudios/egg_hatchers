import 'dart:math';

import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/screens/arena_screen.dart';
import 'package:egg_hatchers/services/audio_service.dart';
import 'package:egg_hatchers/services/custom_sprite_service.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/preferences_service.dart';
import 'package:egg_hatchers/utils/arena_logic.dart';
import 'package:egg_hatchers/widgets/audio_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<
    ({
      GameService game,
      PreferencesService preferences,
      CustomSpriteService sprites,
    })
  >
  services() async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    final preferences = PreferencesService();
    final sprites = CustomSpriteService();
    await Future.wait([
      game.initialize(),
      preferences.initialize(),
      sprites.initialize(),
    ]);
    game.devSetOwnedAnimalsForTesting(const [
      OwnedAnimal(animalId: 'chicken', quantity: 1, level: 20),
      OwnedAnimal(
        animalId: 'fox',
        quantity: 1,
        level: 12,
        mutationId: 'golden',
      ),
      OwnedAnimal(
        animalId: 'dragon',
        quantity: 1,
        level: 4,
        mutationId: 'rainbow',
      ),
    ]);
    return (game: game, preferences: preferences, sprites: sprites);
  }

  testWidgets('Arena lobby fits a narrow phone and presents a full matchup', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final setup = await services();

    await tester.pumpWidget(
      MaterialApp(
        home: ArenaScreen(
          game: setup.game,
          preferences: setup.preferences,
          customSprites: setup.sprites,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Arena'), findsOneWidget);
    expect(find.text('Your lineup'), findsOneWidget);
    expect(find.text('Opponent'), findsOneWidget);
    expect(find.text('ENTER ARENA'), findsOneWidget);
    expect(tester.takeException(), isNull);
    setup.game.dispose();
  });

  testWidgets('Arena battle reaches a result without layout errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final setup = await services();
    final playerTeam = ArenaLogic.recommendedTeam(
      setup.game.state.ownedAnimals,
    ).map(ArenaLogic.fighterFromOwned).toList();
    final opponent = ArenaLogic.generateOpponent(
      playerTeam: playerTeam,
      playerRating: setup.game.arenaRating,
      random: Random(12),
    );
    final simulation = ArenaLogic.simulate(
      playerTeam: playerTeam,
      opponent: opponent,
    );
    final audio = AudioService();

    await tester.pumpWidget(
      AudioScope(
        audio: audio,
        child: MaterialApp(
          home: ArenaBattleScreen(
            game: setup.game,
            preferences: setup.preferences,
            customSprites: setup.sprites,
            simulation: simulation,
          ),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i <= simulation.steps.length; i++) {
      await tester.pump(const Duration(milliseconds: 570));
    }

    expect(
      find.text(simulation.playerWon ? 'VICTORY' : 'DEFEAT'),
      findsOneWidget,
    );
    expect(find.text('NEXT OPPONENT'), findsOneWidget);
    expect(tester.takeException(), isNull);
    setup.game.dispose();
    audio.dispose();
  });
}
