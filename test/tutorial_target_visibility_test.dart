import 'package:egg_hatchers/data/tutorial_data.dart';
import 'package:egg_hatchers/widgets/tutorial_targets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('visibility requires the entire tutorial target', () {
    const viewport = Rect.fromLTWH(0, 0, 320, 500);

    expect(
      TutorialTargets.isFullyVisible(
        const Rect.fromLTWH(16, 420, 288, 60),
        viewport,
      ),
      isTrue,
    );
    expect(
      TutorialTargets.isFullyVisible(
        const Rect.fromLTWH(16, 470, 288, 60),
        viewport,
      ),
      isFalse,
    );
  });

  testWidgets('scrolls a low tutorial target completely into view', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 700),
                SizedBox(
                  key: TutorialTargets.collectionButton,
                  height: 60,
                  child: const Text('Collection'),
                ),
                const SizedBox(height: 300),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.getRect(find.text('Collection')).top, greaterThan(500));

    await TutorialTargets.scrollTargetIntoView(
      TutorialTargetIds.collectionButton,
      duration: Duration.zero,
    );
    await tester.pump();

    final targetRect = tester.getRect(find.text('Collection'));
    expect(
      TutorialTargets.isFullyVisible(
        targetRect,
        const Rect.fromLTWH(0, 0, 320, 500),
      ),
      isTrue,
    );
  });
}
