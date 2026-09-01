import 'package:egg_hatchers/widgets/battle_impact_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('battle impact renders in full and reduced modes', (
    tester,
  ) async {
    for (final reducedEffects in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 280,
              child: BattleImpactOverlay(
                position: const Offset(160, 70),
                progress: 0.35,
                color: Colors.amber,
                intensity: 1,
                reducedEffects: reducedEffects,
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('battle-impact-painter')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });
}
