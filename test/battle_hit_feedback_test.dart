import 'package:egg_hatchers/widgets/battle_hit_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildFeedback({required int trigger, required int damage}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 400,
          child: BattleHitFeedback(
            trigger: trigger,
            alignment: const Alignment(0, -0.55),
            damage: damage,
            color: Colors.cyan,
            reducedEffects: false,
          ),
        ),
      ),
    );
  }

  testWidgets('a new hit shows a burst and floating damage', (tester) async {
    await tester.pumpWidget(buildFeedback(trigger: 0, damage: 42));
    expect(find.text('-42'), findsNothing);

    await tester.pumpWidget(buildFeedback(trigger: 1, damage: 42));
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.byKey(const ValueKey('battle-hit-feedback')), findsOneWidget);
    expect(find.byKey(const ValueKey('battle-impact-painter')), findsOneWidget);
    expect(find.text('-42'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('-42'), findsNothing);
  });

  testWidgets('a fully shielded hit says blocked', (tester) async {
    await tester.pumpWidget(buildFeedback(trigger: 0, damage: 0));
    await tester.pumpWidget(buildFeedback(trigger: 1, damage: 0));
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('BLOCKED'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
