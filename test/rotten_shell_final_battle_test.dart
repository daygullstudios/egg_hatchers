import 'package:egg_hatchers/data/boss_data.dart';
import 'package:egg_hatchers/models/arena.dart';
import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/services/audio_service.dart';
import 'package:egg_hatchers/utils/rotten_shell_final_battle_logic.dart';
import 'package:egg_hatchers/widgets/audio_scope.dart';
import 'package:egg_hatchers/widgets/rotten_shell_final_battle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const fighter = ArenaFighter(
    animalId: 'chicken',
    mutationId: 'none',
    level: 20,
    power: 5000,
  );
  const quick = ArenaAbility(name: 'Peck', energyCost: 2, damageScale: 1);
  const signature = ArenaAbility(
    name: 'Feather Storm',
    energyCost: 7,
    damageScale: 2.45,
  );

  test('final battle replaces Rotten Shell last-life phase only', () {
    expect(
      RottenShellFinalBattleLogic.shouldEnter(
        bossId: 'rotten_shell',
        livesRemaining: 1,
        maxLives: 5,
      ),
      isTrue,
    );
    expect(
      RottenShellFinalBattleLogic.shouldEnter(
        bossId: 'egg_guardian',
        livesRemaining: 1,
        maxLives: 4,
      ),
      isFalse,
    );
    expect(
      RottenShellFinalBattleLogic.shouldEnter(
        bossId: 'rotten_shell',
        livesRemaining: 2,
        maxLives: 5,
      ),
      isFalse,
    );
  });

  test('every lethal move is promoted to a final attack', () {
    final quickDamage = RottenShellFinalBattleLogic.abilityDamage(
      fighter,
      quick,
    );
    expect(
      RottenShellFinalBattleLogic.isFinalAttack(
        fighter: fighter,
        ability: quick,
        bossHealth: quickDamage,
      ),
      isTrue,
    );
    expect(
      RottenShellFinalBattleLogic.isFinalAttack(
        fighter: fighter,
        ability: quick,
        bossHealth: quickDamage + 1,
      ),
      isFalse,
    );
    expect(
      RottenShellFinalBattleLogic.abilityDamage(fighter, signature),
      greaterThan(quickDamage),
    );
  });

  test('beam color is stable and mutations override it', () {
    expect(
      RottenShellFinalBattleLogic.beamColorValue('chicken', 'none'),
      RottenShellFinalBattleLogic.beamColorValue('chicken', 'none'),
    );
    expect(
      RottenShellFinalBattleLogic.beamColorValue('chicken', 'golden'),
      0xFFFFC928,
    );
    expect(
      RottenShellFinalBattleLogic.beamColorValue('chicken', 'shadow'),
      0xFF7C4DFF,
    );
  });

  testWidgets('final battle intro and duel fit a narrow phone', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final audio = AudioService();
    addTearDown(audio.dispose);

    await tester.pumpWidget(
      AudioScope(
        audio: audio,
        child: MaterialApp(
          home: RottenShellFinalBattle(
            fighter: const OwnedAnimal(
              animalId: 'chicken',
              quantity: 1,
              level: 20,
            ),
            fighterCustomSprite: null,
            boss: BossData.bossById('rotten_shell')!,
            onVictory: () {},
            onDefeat: () {},
          ),
        ),
      ),
    );

    expect(find.text('FINAL BATTLE MODE'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 3300));
    await tester.pump();
    expect(find.text('The Rotten Shell'), findsOneWidget);
    expect(find.text('Chicken'), findsOneWidget);
    expect(find.text('0 / 10 ENERGY'), findsOneWidget);
    expect(find.text('Tap the blue energy to collect it.'), findsOneWidget);

    final blueEnergy = find.byKey(const Key('final-battle-energy'));
    expect(blueEnergy, findsOneWidget);
    expect(tester.getCenter(blueEnergy).dx, inInclusiveRange(120, 270));
    await tester.tap(blueEnergy);
    await tester.pump();
    expect(
      find.text('Gold energy gives 2 energy. Tap the gold energy.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('final-battle-energy')));
    await tester.pump();
    expect(
      find.text('Use an ability to attack The Rotten Shell.'),
      findsOneWidget,
    );
    expect(find.text('3 / 10 ENERGY'), findsOneWidget);

    await tester.tap(find.text('Chicken Scratch'));
    await tester.pump();
    expect(
      find.text('Use an ability to attack The Rotten Shell.'),
      findsNothing,
    );
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool('rottenShellFinalBattleTutorialCompleted'),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
