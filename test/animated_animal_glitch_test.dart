import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/models/animal_sprite_theme.dart';
import 'package:egg_hatchers/widgets/animated_animal_glitch.dart';
import 'package:egg_hatchers/widgets/animal_sprite_theme_scope.dart';
import 'package:egg_hatchers/widgets/game_sprite.dart';
import 'package:egg_hatchers/widgets/hatched_egg_glitch_sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DayGull animals glitch in every animal art style', (
    tester,
  ) async {
    for (final animal in const {
      'boba_bazooka': 'assets/images/animals/boba_bazooka.png',
      'crossword_beast': 'assets/images/animals/crossword_beast.png',
    }.entries) {
      for (final theme in AnimalSpriteThemes.all) {
        await tester.pumpWidget(
          MaterialApp(
            home: AnimalSpriteThemeScope(
              theme: theme,
              child: GameSprite(
                animalId: animal.key,
                spritePath: animal.value,
                fallbackEmoji: 'D',
                size: 120,
              ),
            ),
          ),
        );

        expect(
          find.byType(AnimatedAnimalGlitch),
          findsOneWidget,
          reason: '${animal.key} ${theme.name}',
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          tester.takeException(),
          isNull,
          reason: '${animal.key} ${theme.name}',
        );
      }
    }
  });

  testWidgets('animals outside the glitch list render normally', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GameSprite(
          animalId: 'chicken',
          spritePath: 'assets/images/animals/chicken.png',
          fallbackEmoji: 'C',
          size: 120,
        ),
      ),
    );

    expect(find.byType(AnimatedAnimalGlitch), findsNothing);
  });

  testWidgets('DayGull egg glitches in every egg art style', (tester) async {
    final egg = GameData.eggs.firstWhere((egg) => egg.id == 'daygull');

    for (final theme in AnimalSpriteThemes.all) {
      await tester.pumpWidget(
        MaterialApp(
          home: AnimalSpriteThemeScope(
            theme: theme,
            child: GameEggSprite(egg: egg, size: 140),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('daygull-egg-glitch')),
        findsOneWidget,
        reason: theme.name,
      );
      expect(find.byType(AnimatedAnimalGlitch), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull, reason: theme.name);
    }
  });

  testWidgets('The Hatched Egg uses a changing glitch head in every style', (
    tester,
  ) async {
    for (final theme in AnimalSpriteThemes.all) {
      await tester.pumpWidget(
        MaterialApp(
          home: AnimalSpriteThemeScope(
            theme: theme,
            child: const GameSprite(
              animalId: 'the_hatched_egg',
              spritePath: 'assets/images/animals/the_hatched_egg.png',
              fallbackEmoji: 'E',
              size: 160,
            ),
          ),
        ),
      );

      expect(find.byType(HatchedEggGlitchSprite), findsOneWidget);
      expect(find.byType(AnimatedAnimalGlitch), findsOneWidget);
      expect(
        find.byKey(const ValueKey('hatched-egg-front-shell')),
        findsWidgets,
      );
      expect(find.byKey(const ValueKey('hatched-egg-cavity')), findsWidgets);
      expect(find.byKey(const ValueKey('royal_chicken')), findsWidgets);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull, reason: theme.name);
    }

    await tester.pump(const Duration(milliseconds: 3300));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('royal_chicken')), findsNothing);
  });
}
