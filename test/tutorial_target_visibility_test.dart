import 'package:egg_hatchers/data/tutorial_data.dart';
import 'package:egg_hatchers/models/background_theme.dart';
import 'package:egg_hatchers/navigation/app_page_route.dart';
import 'package:egg_hatchers/services/tutorial_service.dart';
import 'package:egg_hatchers/widgets/tutorial_overlay.dart';
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

  testWidgets('keeps a long tutorial prompt and controls on a short screen', (
    tester,
  ) async {
    const surfaceSize = Size(491, 757);
    await tester.binding.setSurfaceSize(surfaceSize);
    final service = TutorialService.instance;
    service.showWelcome(isReplay: true);
    service.startGuided();
    for (var index = 0; index < 7; index++) {
      service.advanceNext(force: true);
    }
    addTearDown(() async {
      service.skipTutorial();
      await tester.binding.setSurfaceSize(null);
    });

    final contentKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              SizedBox.expand(
                key: contentKey,
                child: Stack(
                  children: [
                    Positioned(
                      left: 30,
                      top: 205,
                      width: 431,
                      height: 300,
                      child: SizedBox(
                        key: TutorialTargets.fusionSection,
                        child: const ColoredBox(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: TutorialSpotlightOverlay(
                  service: service,
                  theme: BackgroundThemes.hatcheryDefault,
                  topRouteName: kCollectionRouteName,
                  contentKey: contentKey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    final prompt = find.textContaining('Fusion lets you combine');
    final nextButton = find.widgetWithText(FilledButton, 'Next');
    final exitButton = find.widgetWithText(TextButton, 'Exit');

    expect(prompt, findsOneWidget);
    expect(
      find.ancestor(of: prompt, matching: find.byType(SingleChildScrollView)),
      findsOneWidget,
    );
    expect(nextButton, findsOneWidget);
    expect(exitButton, findsOneWidget);
    expect(
      tester.getRect(nextButton).bottom,
      lessThanOrEqualTo(surfaceSize.height),
    );
    expect(tester.getRect(nextButton).top, greaterThanOrEqualTo(0));
    expect(nextButton.hitTestable(), findsOneWidget);
    expect(exitButton.hitTestable(), findsOneWidget);
  });
}
