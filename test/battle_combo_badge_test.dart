import 'package:egg_hatchers/widgets/battle_combo_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildBadge(int combo) => MaterialApp(
    home: Scaffold(body: BattleComboBadge(combo: combo, reducedEffects: false)),
  );

  testWidgets('combo badge promotes meaningful streak milestones', (
    tester,
  ) async {
    await tester.pumpWidget(buildBadge(1));
    expect(find.textContaining('COMBO'), findsNothing);

    await tester.pumpWidget(buildBadge(2));
    expect(find.text('2 HIT COMBO'), findsOneWidget);

    await tester.pumpWidget(buildBadge(5));
    expect(find.text('HOT STREAK  5'), findsOneWidget);

    await tester.pumpWidget(buildBadge(10));
    expect(find.text('UNSTOPPABLE  10'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
