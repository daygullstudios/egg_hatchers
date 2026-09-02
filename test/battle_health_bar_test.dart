import 'package:egg_hatchers/widgets/battle_health_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildBar({
    required double value,
    Object identity = 'fighter-a',
    bool reducedEffects = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 200,
            child: BattleHealthBar(
              value: value,
              identity: identity,
              height: 12,
              reducedEffects: reducedEffects,
            ),
          ),
        ),
      ),
    );
  }

  double widthFactor(WidgetTester tester, String key) {
    final finder = find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(FractionallySizedBox),
    );
    return tester.widget<FractionallySizedBox>(finder).widthFactor!;
  }

  testWidgets('damage drains health before the trailing loss marker', (
    tester,
  ) async {
    await tester.pumpWidget(buildBar(value: 1));
    await tester.pumpWidget(buildBar(value: 0.4));
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      widthFactor(tester, 'battle-health-current-fighter-a'),
      closeTo(0.4, 0.01),
    );
    expect(
      widthFactor(tester, 'battle-health-trail-fighter-a'),
      closeTo(1, 0.01),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 450));
    expect(
      widthFactor(tester, 'battle-health-trail-fighter-a'),
      closeTo(0.4, 0.01),
    );
  });

  testWidgets('a newly switched fighter resets the bar immediately', (
    tester,
  ) async {
    await tester.pumpWidget(buildBar(value: 0.2));
    await tester.pumpWidget(buildBar(value: 0.85, identity: 'fighter-b'));

    expect(widthFactor(tester, 'battle-health-current-fighter-b'), 0.85);
    expect(widthFactor(tester, 'battle-health-trail-fighter-b'), 0.85);
    expect(tester.takeException(), isNull);
  });

  testWidgets('critical health remains stable with reduced effects', (
    tester,
  ) async {
    await tester.pumpWidget(buildBar(value: 0.18, reducedEffects: true));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.byType(BattleHealthBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
