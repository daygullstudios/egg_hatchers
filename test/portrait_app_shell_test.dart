import 'package:egg_hatchers/widgets/app_theme_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<Size> pumpShell(
    WidgetTester tester, {
    required Size viewportSize,
  }) async {
    await tester.binding.setSurfaceSize(viewportSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Size? inheritedSize;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => PortraitAppShell(child: child!),
        home: Builder(
          builder: (context) {
            inheritedSize = MediaQuery.sizeOf(context);
            return const ColoredBox(color: Colors.white);
          },
        ),
      ),
    );

    expect(inheritedSize, isNotNull);
    return inheritedSize!;
  }

  testWidgets('centers a 430px app surface on wide displays', (tester) async {
    final inheritedSize = await pumpShell(
      tester,
      viewportSize: const Size(1400, 900),
    );

    final surface = tester.getRect(find.byKey(PortraitAppShell.surfaceKey));
    expect(surface, const Rect.fromLTWH(485, 0, 430, 900));
    expect(inheritedSize, const Size(430, 900));
  });

  testWidgets('remains edge-to-edge on phone displays', (tester) async {
    final inheritedSize = await pumpShell(
      tester,
      viewportSize: const Size(390, 844),
    );

    final surface = tester.getRect(find.byKey(PortraitAppShell.surfaceKey));
    expect(surface, const Rect.fromLTWH(0, 0, 390, 844));
    expect(inheritedSize, const Size(390, 844));
  });
}
