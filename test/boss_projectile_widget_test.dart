import 'package:egg_hatchers/models/animal_sprite_theme.dart';
import 'package:egg_hatchers/widgets/animal_sprite_theme_scope.dart';
import 'package:egg_hatchers/widgets/boss_projectile_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('every projectile type has a trail in every art style', (
    tester,
  ) async {
    const bossIds = [
      'slime_boss',
      'egg_golem',
      'shadow_rooster',
      'slime_king',
      'egg_guardian',
      'shadow_phoenix',
      'rotten_shell',
      'unknown_rotten_egg_boss',
    ];

    for (final theme in AnimalSpriteThemes.all) {
      for (final bossId in bossIds) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AnimalSpriteThemeScope(
                  theme: theme,
                  child: BossProjectileWidget(bossId: bossId),
                ),
              ),
            ),
          ),
        );

        expect(
          find.byKey(ValueKey('boss-projectile-trail-$bossId')),
          findsOneWidget,
          reason: '$bossId in ${theme.name}',
        );
        expect(tester.takeException(), isNull);
      }
    }
  });
}
