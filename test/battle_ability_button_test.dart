import 'package:egg_hatchers/models/arena.dart';
import 'package:egg_hatchers/widgets/battle_ability_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ability = ArenaAbility(
    name: 'Test Shield',
    energyCost: 4,
    damageScale: 0.8,
    effect: ArenaAbilityEffect.shield,
  );

  Widget buildButton({required bool available, bool reducedEffects = false}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: BattleAbilityButton(
            ability: ability,
            available: available,
            reducedEffects: reducedEffects,
            onPressed: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('ability announces readiness and shows its effect icon', (
    tester,
  ) async {
    await tester.pumpWidget(buildButton(available: false));
    await tester.pumpWidget(buildButton(available: true));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byIcon(Icons.shield), findsOneWidget);
    expect(find.text('4 ENERGY'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(BattleAbilityButton)),
      matchesSemantics(
        label: 'Test Shield, shield ability, costs 4 energy, ready',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced effects keeps readiness stable', (tester) async {
    await tester.pumpWidget(
      buildButton(available: false, reducedEffects: true),
    );
    await tester.pumpWidget(buildButton(available: true, reducedEffects: true));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Test Shield'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
