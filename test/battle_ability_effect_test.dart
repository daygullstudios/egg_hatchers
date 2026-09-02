import 'package:egg_hatchers/data/arena_ability_data.dart';
import 'package:egg_hatchers/widgets/battle_ability_effect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('animates an animal ability when its trigger changes', (
    tester,
  ) async {
    final ability = ArenaAbilityData.forAnimal('chicken').first;

    Widget build(int trigger) {
      return MaterialApp(
        home: SizedBox.expand(
          child: BattleAbilityEffect(
            trigger: trigger,
            animalId: 'chicken',
            mutationId: 'rainbow',
            ability: ability,
            playerAttacks: true,
            reducedEffects: false,
          ),
        ),
      );
    }

    await tester.pumpWidget(build(0));
    expect(find.byKey(const ValueKey('battle-ability-effect')), findsNothing);

    await tester.pumpWidget(build(1));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byKey(const ValueKey('battle-ability-effect')), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('battle-ability-effect')), findsNothing);
  });

  testWidgets('supports reduced effects and reverse drain travel', (
    tester,
  ) async {
    final ability = ArenaAbilityData.forAnimal(
      'fox',
    ).firstWhere((candidate) => candidate.effect.name == 'drain');

    Widget build(int trigger) {
      return MaterialApp(
        home: SizedBox.expand(
          child: BattleAbilityEffect(
            trigger: trigger,
            animalId: 'fox',
            mutationId: 'shadow',
            ability: ability,
            playerAttacks: false,
            reducedEffects: true,
          ),
        ),
      );
    }

    await tester.pumpWidget(build(0));
    await tester.pumpWidget(build(1));
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byKey(const ValueKey('battle-ability-effect')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
