import 'package:egg_hatchers/models/background_theme.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/widgets/game_primary_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('theme foreground colors keep release-critical contrast', () {
    for (final theme in BackgroundThemes.all) {
      expect(
        _contrastRatio(theme.appBarColor, theme.appBarForegroundColor),
        greaterThanOrEqualTo(4.5),
        reason: '${theme.name} app bar foreground should be readable.',
      );
      expect(
        _contrastRatio(theme.primaryColor, theme.primaryForegroundColor),
        greaterThanOrEqualTo(4.5),
        reason: '${theme.name} primary foreground should be readable.',
      );
      expect(
        _contrastRatio(theme.secondaryColor, theme.secondaryForegroundColor),
        greaterThanOrEqualTo(4.5),
        reason: '${theme.name} secondary foreground should be readable.',
      );
      expect(
        _contrastRatio(theme.cardColor, theme.cardTextPrimaryColor),
        greaterThanOrEqualTo(4.5),
        reason: '${theme.name} card primary text should be readable.',
      );
      expect(
        _contrastRatio(theme.cardColor, theme.cardTextSecondaryColor),
        greaterThanOrEqualTo(3),
        reason: '${theme.name} card secondary text should stay legible.',
      );
    }
  });

  for (final scenario in [
    (
      const Size(390, 844),
      ['Hatchery', 'Shop', 'Battles', 'Collection', 'More'],
    ),
    (
      const Size(1400, 900),
      [
        'Hatchery',
        'Shop',
        'Battles',
        'Collection',
        'Quests',
        'Custom Animals',
        'Settings',
      ],
    ),
  ]) {
    testWidgets(
      'primary navigation exposes labels and touch targets $scenario',
      (tester) async {
        final game = GameService();
        addTearDown(game.dispose);
        tester.view.physicalSize = scenario.$1;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: MainGameShellScope(
              current: MainGameDestination.hatchery,
              game: game,
              onSelect: (_) {},
              child: Scaffold(
                body: Align(
                  alignment: Alignment.topCenter,
                  child: GamePrimaryNavigation(
                    theme: BackgroundThemes.hatcheryDefault,
                    hostDestination: MainGameDestination.hatchery,
                  ),
                ),
              ),
            ),
          ),
        );

        for (final label in scenario.$2) {
          expect(find.text(label), findsOneWidget);
          final target = find
              .ancestor(of: find.text(label), matching: find.byType(InkWell))
              .last;
          final rect = tester.getRect(target);
          expect(rect.width, greaterThanOrEqualTo(48), reason: label);
          expect(rect.height, greaterThanOrEqualTo(48), reason: label);
        }
      },
    );
  }
}

double _contrastRatio(Color a, Color b) {
  final aLum = a.computeLuminance();
  final bLum = b.computeLuminance();
  final light = aLum > bLum ? aLum : bLum;
  final dark = aLum > bLum ? bLum : aLum;
  return (light + 0.05) / (dark + 0.05);
}
