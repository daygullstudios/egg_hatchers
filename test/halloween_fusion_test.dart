import 'dart:math';
import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/utils/halloween_fusion_logic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:egg_hatchers/services/preferences_service.dart';
import 'package:egg_hatchers/widgets/halloween_fusion_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Halloween machine previews and confirms at narrow phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final game = GameService(clock: () => DateTime.utc(2026, 10, 25));
    final preferences = PreferencesService();
    await game.initialize();
    await preferences.initialize();
    game.devSetOwnedAnimalsForTesting(const [
      OwnedAnimal(animalId: 'chicken', quantity: 4),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HalloweenFusionPanel(
              game: game,
              theme: preferences.selectedTheme,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final add = find.byTooltip('Add pet');
    for (var i = 0; i < 4; i++) {
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pump();
    }
    expect(find.text('100.0%'), findsOneWidget);
    expect(game.ownedAnimals.single.quantity, 4);
    final fuse = find.text('Fuse 4 pets');
    await tester.ensureVisible(fuse);
    await tester.tap(fuse);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(game.ownedAnimals.single.quantity, 4);
    await tester.tap(fuse);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Fuse 4 pets'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Halloween fusion complete'), findsOneWidget);
    expect(game.ownedAnimals.single.animalId, 'pumpkin_prowler');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    game.dispose();
    preferences.dispose();
  });
  test('Halloween window includes November 2 but ends before November 3', () {
    expect(
      HalloweenFusionLogic.isActive(DateTime.utc(2026, 10, 23, 23, 59)),
      false,
    );
    expect(HalloweenFusionLogic.isActive(DateTime.utc(2026, 10, 24)), true);
    expect(
      HalloweenFusionLogic.isActive(DateTime.utc(2026, 11, 2, 23, 59)),
      true,
    );
    expect(HalloweenFusionLogic.isActive(DateTime.utc(2026, 11, 3)), false);
  });
  test('income odds normalize and stronger income improves rarest odds', () {
    var previous = 0.0;
    for (final power in [0, 4, 4000, 40000, 400000, 4000000, 40000000]) {
      final odds = HalloweenFusionLogic.probabilities(power);
      expect(odds.reduce((a, b) => a + b), closeTo(1, 1e-9));
      expect(odds.every((p) => p >= 0 && p <= 1), true);
      expect(odds.last, greaterThanOrEqualTo(previous));
      previous = odds.last;
    }
    expect(HalloweenFusionLogic.probabilities(4), [1.0, 0.0, 0.0]);
  });
  test(
    'exclusive pets never enter eggs or normal collection quest targets',
    () {
      for (final egg in [...GameData.eggs, ...GameData.battleEggs]) {
        expect(
          egg.possibleAnimalIds.toSet().intersection(
            GameData.fusionExclusiveAnimalIds,
          ),
          isEmpty,
        );
      }
      expect(
        GameData.collectionQuestAnimals.any(
          (a) => GameData.fusionExclusiveAnimalIds.contains(a.id),
        ),
        false,
      );
    },
  );
  test(
    'mixed and matching inputs consume exactly four and persist reward',
    () async {
      SharedPreferences.setMockInitialValues({});
      final game = GameService(
        clock: () => DateTime.utc(2026, 10, 25),
        random: Random(1),
      );
      await game.initialize();
      game.devSetOwnedAnimalsForTesting(const [
        OwnedAnimal(animalId: 'chicken', quantity: 4),
        OwnedAnimal(animalId: 'mouse', quantity: 2),
      ]);
      final chicken = game.ownedAnimals.first;
      final mouse = game.ownedAnimals.last;
      expect(game.randomFusionPower([chicken, chicken, mouse, mouse]), 6);
      expect(
        game.randomFuseAnimals([chicken, chicken, mouse, mouse])?.id,
        'pumpkin_prowler',
      );
      expect(game.ownedAnimal('chicken')?.quantity, 2);
      expect(game.ownedAnimal('mouse'), isNull);
      expect(game.ownedAnimal('pumpkin_prowler')?.quantity, 1);
      expect(
        game.randomFuseAnimals([chicken, chicken, chicken, chicken]),
        isNull,
      );
      await game.save();
      game.dispose();
      final reloaded = GameService(clock: () => DateTime.utc(2026, 11, 4));
      await reloaded.initialize();
      expect(reloaded.ownedAnimal('pumpkin_prowler')?.quantity, 1);
      expect(reloaded.halloweenFusionActive, false);
      reloaded.dispose();
    },
  );
  test('closed event and protected pets cannot be consumed', () async {
    SharedPreferences.setMockInitialValues({});
    var now = DateTime.utc(2026, 10, 25);
    final game = GameService(clock: () => now);
    await game.initialize();
    game.devSetOwnedAnimalsForTesting(const [
      OwnedAnimal(animalId: 'chicken', quantity: 4, isProtected: true),
    ]);
    final protected = List.filled(4, game.ownedAnimals.first);
    expect(game.randomFuseAnimals(protected), isNull);
    game.devSetOwnedAnimalsForTesting(const [
      OwnedAnimal(animalId: 'chicken', quantity: 4),
    ]);
    final valid = List.filled(4, game.ownedAnimals.first);
    now = DateTime.utc(2026, 11, 3);
    expect(game.randomFuseAnimals(valid), isNull);
    expect(game.ownedAnimals.single.quantity, 4);
    now = DateTime.utc(2026, 10, 25);
    expect(game.randomFuseAnimals(valid)?.id, 'pumpkin_prowler');
    expect(game.ownedAnimals.single.animalId, 'pumpkin_prowler');
    game.dispose();
  });
}
