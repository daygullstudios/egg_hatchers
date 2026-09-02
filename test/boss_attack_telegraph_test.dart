import 'package:egg_hatchers/models/animal_sprite_theme.dart';
import 'package:egg_hatchers/widgets/animal_sprite_theme_scope.dart';
import 'package:egg_hatchers/widgets/boss_attack_telegraph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('attack warning paints in every animal art style', (
    tester,
  ) async {
    for (final theme in AnimalSpriteThemes.all) {
      await tester.pumpWidget(
        MaterialApp(
          home: AnimalSpriteThemeScope(
            theme: theme,
            child: const Center(
              child: BossAttackTelegraph(
                bossId: 'shadow_phoenix',
                progress: 0.65,
                width: 40,
                height: 220,
                reducedEffects: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BossAttackTelegraph), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('reduced effects warning remains visible and stable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AnimalSpriteThemeScope(
          theme: AnimalSpriteThemes.classic,
          child: const Center(
            child: BossAttackTelegraph(
              bossId: 'slime_boss',
              progress: 0.2,
              width: 38,
              height: 180,
              reducedEffects: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
