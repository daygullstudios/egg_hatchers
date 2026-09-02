import 'package:egg_hatchers/widgets/battle_fighter_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSwitcher({
    required String identity,
    bool reducedEffects = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: BattleFighterSwitcher(
            identity: identity,
            isOpponent: false,
            reducedEffects: reducedEffects,
            child: SizedBox(
              key: ValueKey('content-$identity'),
              width: 120,
              height: 120,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('switching fighters animates old and new animals', (
    tester,
  ) async {
    await tester.pumpWidget(buildSwitcher(identity: 'first'));
    await tester.pumpWidget(buildSwitcher(identity: 'second'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('content-first')), findsOneWidget);
    expect(find.byKey(const ValueKey('content-second')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('content-first')), findsNothing);
    expect(find.byKey(const ValueKey('content-second')), findsOneWidget);
  });

  testWidgets('reduced effects switches fighters immediately', (tester) async {
    await tester.pumpWidget(
      buildSwitcher(identity: 'first', reducedEffects: true),
    );
    await tester.pumpWidget(
      buildSwitcher(identity: 'second', reducedEffects: true),
    );

    expect(find.byKey(const ValueKey('content-first')), findsNothing);
    expect(find.byKey(const ValueKey('content-second')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
