import 'package:egg_hatchers/models/animal_sprite_theme.dart';
import 'package:egg_hatchers/widgets/animal_motion.dart';
import 'package:egg_hatchers/widgets/animal_sprite_theme_scope.dart';
import 'package:egg_hatchers/widgets/game_sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('animal portraits support every battle motion in every style', (
    tester,
  ) async {
    for (final theme in AnimalSpriteThemes.all) {
      for (final motion in AnimalMotionState.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: AnimalSpriteThemeScope(
              theme: theme,
              child: Scaffold(
                body: Center(
                  child: GameAnimalPortrait(
                    animalId: 'motion_test',
                    spritePath: null,
                    fallbackEmoji: 'A',
                    size: 96,
                    motion: motion,
                    attackDirection: const Offset(1, 0),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 120));

        expect(
          find.byKey(const ValueKey('animal-motion-motion_test')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    }

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('system reduced motion leaves the portrait still', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: AnimalSpriteThemeScope(
            theme: AnimalSpriteThemes.classic,
            child: const AnimalMotion(
              state: AnimalMotionState.victory,
              child: SizedBox(
                key: ValueKey('still-animal'),
                width: 40,
                height: 40,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('still-animal')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AnimalMotion),
        matching: find.byType(AnimatedBuilder),
      ),
      findsNothing,
    );
  });
}
