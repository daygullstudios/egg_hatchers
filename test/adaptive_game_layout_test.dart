import 'package:egg_hatchers/widgets/phone_width_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<Rect> pumpLayout(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameWidthLayout(
            padding: EdgeInsets.zero,
            child: const ColoredBox(
              key: ValueKey<String>('adaptive-content'),
              color: Colors.teal,
            ),
          ),
        ),
      ),
    );
    return tester.getRect(find.byKey(const ValueKey('adaptive-content')));
  }

  testWidgets('preserves the phone content width on compact screens', (
    tester,
  ) async {
    final rect = await pumpLayout(tester, const Size(390, 844));
    expect(rect, const Rect.fromLTWH(0, 0, 390, 844));
  });

  testWidgets('uses the wider tablet workspace', (tester) async {
    final rect = await pumpLayout(tester, const Size(760, 900));
    expect(rect, const Rect.fromLTWH(0, 0, 760, 900));
  });

  testWidgets('caps and centers the expanded workspace', (tester) async {
    final rect = await pumpLayout(tester, const Size(1400, 900));
    expect(rect, const Rect.fromLTWH(110, 0, 1180, 900));
  });

  testWidgets('reports deliberate layout classes while resizing', (
    tester,
  ) async {
    final classes = <GameLayoutClass>[];
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> pumpAt(Size size) async {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameWidthLayout(
              builder: (_, layoutClass) {
                classes.add(layoutClass);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
    }

    await pumpAt(const Size(390, 844));
    await pumpAt(const Size(700, 900));
    await pumpAt(const Size(1200, 900));

    expect(
      classes,
      containsAllInOrder(const [
        GameLayoutClass.compact,
        GameLayoutClass.medium,
        GameLayoutClass.expanded,
      ]),
    );
  });
}
