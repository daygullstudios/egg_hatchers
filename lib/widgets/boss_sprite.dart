import 'package:flutter/material.dart';

import '../data/retro_pixel_boss_sprites.dart';
import '../models/animal_sprite_theme.dart';
import '../utils/egg_shard_logic.dart';
import 'animal_sprite_theme_scope.dart';
import 'game_sprite.dart';
import 'retro_pixel_boss_sprite.dart';

/// Boss portrait with PNG sprite and emoji fallback.
///
/// When [bossId] is set, themed boss art can override the PNG sprite.
class BossSprite extends StatelessWidget {
  const BossSprite({
    super.key,
    required this.spritePath,
    required this.fallbackEmoji,
    required this.size,
    this.bossId,
    this.semanticLabel,
  });

  final String? spritePath;
  final String fallbackEmoji;
  final double size;
  final String? bossId;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final animalTheme = bossId == null
        ? null
        : AnimalSpriteThemeScope.of(context);
    if (bossId != null) {
      if (animalTheme!.id == AnimalSpriteThemes.retroPixel.id &&
          RetroPixelBossSprites.hasSprite(bossId!)) {
        return RetroPixelBossSprite(
          bossId: bossId!,
          size: size,
          semanticLabel: semanticLabel,
        );
      }
    }

    if (bossId == EggShardLogic.rottenShellBossId &&
        animalTheme?.id != AnimalSpriteThemes.realistic.id) {
      return GameSprite(
        spritePath: 'assets/images/bosses/rotten_shell.png',
        fallbackEmoji: fallbackEmoji,
        size: size,
        semanticLabel: semanticLabel,
        emojiFontSize: size * 0.55,
      );
    }

    return GameSprite(
      animalId: bossId,
      spritePath: spritePath,
      fallbackEmoji: fallbackEmoji,
      size: size,
      semanticLabel: semanticLabel,
      emojiFontSize: size * 0.55,
    );
  }
}
