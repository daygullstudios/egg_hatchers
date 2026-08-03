import 'package:egg_hatchers/models/arena.dart';
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

  testWidgets(
    'Arena battle uses delayed circles and abilities to reach a result',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final setup = await services();
      const playerTeam = [
        ArenaFighter(
          animalId: 'chicken',
          mutationId: 'none',
          level: 200,
          power: 100000,
        ),
      ];
      const opponent = ArenaOpponent(
        name: 'Milo',
        title: 'Arena Regular',
        rating: 1000,
        seed: 12,
        team: [
          ArenaFighter(
            animalId: 'mouse',
            mutationId: 'none',
            level: 1,
            power: 1,
          ),
        ],
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
      expect(find.text('Chicken Scratch'), findsOneWidget);
      expect(find.byKey(const Key('arena-energy-circle')), findsNothing);

      await tester.pump(const Duration(milliseconds: 650));
      expect(find.byKey(const Key('arena-energy-circle')), findsOneWidget);
      await tester.tap(find.byKey(const Key('arena-energy-circle')));
      await tester.pump();
      expect(find.byKey(const Key('arena-energy-circle')), findsNothing);

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('arena-energy-circle')), findsNothing);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('arena-energy-circle')), findsOneWidget);
      await tester.tap(find.byKey(const Key('arena-energy-circle')));
      await tester.pump();

      await tester.tap(find.text('Chicken Scratch'));
      await tester.pump();

      expect(find.text('VICTORY'), findsOneWidget);
      expect(find.text('NEXT OPPONENT'), findsOneWidget);
      expect(tester.takeException(), isNull);
      setup.game.dispose();
      audio.dispose();
    },
  );
}
