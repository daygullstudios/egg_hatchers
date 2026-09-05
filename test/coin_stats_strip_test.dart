import 'package:egg_hatchers/models/background_theme.dart';
import 'package:egg_hatchers/widgets/coin_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('earned income chip explains its Rebirth-scoped total', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CoinStatsStrip(
            coinsPerSecond: 12,
            lifetimeCoinsEarned: 2816,
            theme: BackgroundThemes.hatcheryDefault,
          ),
        ),
      ),
    );

    expect(find.text('2,816 earned'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    expect(
      find.byTooltip('Animal income earned this Rebirth.'),
      findsOneWidget,
    );

    await tester.tap(find.text('2,816 earned'));
    await tester.pumpAndSettle();

    expect(find.text('Total animal income'), findsOneWidget);
    expect(
      find.text(
        'Coins earned by your animals since you started—or since your last '
        'Rebirth. Spending coins doesn’t reduce this total. It unlocks eggs '
        'and counts toward your next Rebirth.',
      ),
      findsOneWidget,
    );
  });
}
