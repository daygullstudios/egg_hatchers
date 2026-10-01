import 'package:egg_hatchers/models/animal_sprite_theme.dart';
import 'package:egg_hatchers/widgets/animal_sprite_theme_scope.dart';
import 'package:egg_hatchers/widgets/game_sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Ultimate Nest occupants sit inside each styled rim', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF292D35),
          body: RepaintBoundary(
            key: const ValueKey('nest-preview'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final theme in AnimalSpriteThemes.all)
                  AnimalSpriteThemeScope(
                    theme: theme,
                    child: const GameSprite(
                      animalId: 'the_hatched_egg',
                      spritePath: 'assets/images/animals/the_hatched_egg.png',
                      fallbackEmoji: 'N',
                      size: 250,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pump();
    await expectLater(
      find.byKey(const ValueKey('nest-preview')),
      matchesGoldenFile('goldens/ultimate_nest_styles.png'),
    );
    await tester.pumpWidget(const SizedBox());
  });
}
