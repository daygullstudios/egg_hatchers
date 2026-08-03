import 'package:egg_hatchers/widgets/purchase_celebration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'purchase celebration rains above the current route then clears',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    PurchaseCelebration.show(context);
                    showDialog<void>(
                      context: context,
                      builder: (_) =>
                          const AlertDialog(title: Text('Purchased')),
                    );
                  },
                  child: const Text('Buy'),
                ),
              ),
            ),
          ),
        ),
      );

    await tester.tap(find.text('Buy'));
    await tester.pump();
    await tester.pump();

      expect(find.text('Purchased'), findsOneWidget);
      expect(find.byKey(const ValueKey('purchase-money-rain')), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 2000));
      expect(find.byKey(const ValueKey('purchase-money-rain')), findsNothing);
    },
  );
}
