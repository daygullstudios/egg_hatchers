import 'package:egg_hatchers/widgets/coin_balance_scope.dart';
import 'package:egg_hatchers/widgets/phone_width_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp({
    required int coins,
    VoidCallback? onCoinBalanceTap,
    List<Widget>? actions,
  }) {
    return MaterialApp(
      home: CoinBalanceScope(
        coins: coins,
        child: Scaffold(
          appBar: PhoneWidthAppBar(
            title: 'Nestarium',
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            onCoinBalanceTap: onCoinBalanceTap,
            actions: actions,
          ),
        ),
      ),
    );
  }

  testWidgets('shows the scoped coin balance instead of the screen title', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(coins: 1452));

    expect(find.text('1,452'), findsOneWidget);
    expect(find.text('coins'), findsOneWidget);
    expect(find.text('Nestarium'), findsNothing);
  });

  testWidgets('updates when the scoped balance changes', (tester) async {
    await tester.pumpWidget(buildApp(coins: 1452));
    await tester.pumpWidget(buildApp(coins: 9876));

    expect(find.text('1,452'), findsNothing);
    expect(find.text('9,876'), findsOneWidget);
  });

  testWidgets('forwards taps from the persistent balance', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      buildApp(coins: 1452, onCoinBalanceTap: () => taps += 1),
    );

    await tester.tap(find.byKey(PhoneWidthAppBar.coinBalanceKey));

    expect(taps, 1);
  });

  testWidgets('retains an ordinary title when no balance scope exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: PhoneWidthAppBar(
            title: 'Standalone screen',
            backgroundColor: Colors.teal,
          ),
        ),
      ),
    );

    expect(find.text('Standalone screen'), findsOneWidget);
  });

  testWidgets('fits a large balance beside narrow-screen actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildApp(
        coins: 999999999999,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.help)),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('999,999,999,999'), findsOneWidget);
  });
}
