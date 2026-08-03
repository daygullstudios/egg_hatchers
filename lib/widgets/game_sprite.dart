import 'package:flutter/material.dart';

import '../data/egg_theme_assets.dart';
import '../data/realistic_animal_sprites.dart';
import '../data/retro_pixel_animal_sprites.dart';
import '../models/animal_sprite_theme.dart';
import '../models/custom_sprite_data.dart';
import '../models/egg.dart';
import '../models/mutation.dart';
import '../theme/game_theme.dart';
import 'animal_sprite_theme_scope.dart';
import 'pixel_sprite.dart';
import 'retro_pixel_animal_sprite.dart';

/// Shows custom pixel art, retro pixel art, a sprite image, or emoji fallback.
class GameSprite extends StatelessWidget {
  const GameSprite({
    super.key,
    this.customSprite,
    this.animalId,
    this.spritePath,
    required this.fallbackEmoji,
    required this.size,
    this.semanticLabel,
    this.fit = BoxFit.contain,
    this.emojiFontSize,
    this.filterQuality = FilterQuality.none,
    this.errorSpritePath,
  });

  final CustomSpriteData? customSprite;
  final String? animalId;
  final String? spritePath;
  final String fallbackEmoji;
  final double size;
  final String? semanticLabel;
  final BoxFit fit;
  final double? emojiFontSize;
  final FilterQuality filterQuality;
  final String? errorSpritePath;

  @override
  Widget build(BuildContext context) {
    final emojiSize = emojiFontSize ?? size * 0.58;

    final custom = customSprite;
    if (custom != null && custom.hasVisiblePixels) {
      return Semantics(
        label: semanticLabel,
        child: PixelSprite(data: custom, size: size),
      );
    }

    final theme = AnimalSpriteThemeScope.of(context);
    final id = animalId;
    if (theme.id == AnimalSpriteThemes.retroPixel.id &&
        id != null &&
        RetroPixelAnimalSprites.hasSprite(id)) {
      return RetroPixelAnimalSprite(
        animalId: id,
        size: size,
        semanticLabel: semanticLabel,
      );
    }

    if (theme.id == AnimalSpriteThemes.realistic.id && id != null) {
      final realisticPath = RealisticAnimalSprites.assetPathFor(id);
      if (realisticPath != null) {
        return _assetImage(
          realisticPath,
          emojiSize,
          filterQuality: FilterQuality.high,
          errorFallback: (_) {
            final classicPath = spritePath;
            if (classicPath == null || classicPath.isEmpty) {
              return _emojiFallback(emojiSize);
            }
            return _assetImage(classicPath, emojiSize);
          },
        );
      }
    }

    if (spritePath == null || spritePath!.isEmpty) {
      return _emojiFallback(emojiSize);
    }

    return _assetImage(
      spritePath!,
      emojiSize,
      filterQuality: filterQuality,
      errorFallback: errorSpritePath == null
          ? null
          : (_) => _assetImage(errorSpritePath!, emojiSize),
    );
  }

  Widget _assetImage(
    String path,
    double emojiSize, {
    FilterQuality filterQuality = FilterQuality.none,
    WidgetBuilder? errorFallback,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        path,
        width: size,
        height: size,
        fit: fit,
        filterQuality: filterQuality,
        semanticLabel: semanticLabel,
        errorBuilder: (context, _, _) =>
            errorFallback?.call(context) ?? _emojiFallback(emojiSize),
      ),
    );
  }

  Widget _emojiFallback(double emojiSize) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          fallbackEmoji,
          style: TextStyle(fontSize: emojiSize, height: 1.0),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Built-in egg artwork that follows the selected animal sprite theme.
class GameEggSprite extends StatelessWidget {
  const GameEggSprite({
    super.key,
    required this.egg,
    required this.size,
    this.semanticLabel,
    this.emojiFontSize,
  });

  final Egg egg;
  final double size;
  final String? semanticLabel;
  final double? emojiFontSize;

  @override
  Widget build(BuildContext context) {
    final theme = AnimalSpriteThemeScope.of(context);
    final themedPath = EggThemeAssets.assetPathFor(
      themeId: theme.id,
      eggId: egg.id,
    );
    return GameSprite(
      spritePath: themedPath ?? egg.spritePath,
      errorSpritePath: themedPath == null ? null : egg.spritePath,
      fallbackEmoji: egg.emoji,
      size: size,
      semanticLabel: semanticLabel ?? egg.name,
      emojiFontSize: emojiFontSize,
      filterQuality: theme.id == AnimalSpriteThemes.realistic.id
          ? FilterQuality.high
          : FilterQuality.none,
    );
  }
}

/// Animal portrait with optional mutation glow; uses base animal sprite only.
class GameAnimalPortrait extends StatelessWidget {
  const GameAnimalPortrait({
    super.key,
    this.customSprite,
    this.animalId,
    required this.spritePath,
    required this.fallbackEmoji,
    required this.size,
    this.mutation,
    this.semanticLabel,
    this.emojiFontSize,
  });

  final CustomSpriteData? customSprite;
  final String? animalId;
  final String? spritePath;
  final String fallbackEmoji;
  final double size;
  final Mutation? mutation;
  final String? semanticLabel;
  final double? emojiFontSize;

  @override
  Widget build(BuildContext context) {
    final activeMutation = mutation;
    final isMutated = activeMutation != null && !activeMutation.isNormal;
    final accent = isMutated
        ? GameTheme.mutationAccent(activeMutation.id)
        : null;
    final portraitScale = activeMutation?.displayScale ?? 1.0;
    final innerSize = size * 0.82 * portraitScale;

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        color: accent?.withValues(alpha: 0.08),
        border: Border.all(
          color: (accent ?? Colors.transparent).withValues(
            alpha: isMutated ? 0.75 : 0.0,
          ),
          width: isMutated ? 2.5 : 0,
        ),
        boxShadow: isMutated
            ? [
                BoxShadow(
                  color: accent!.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          GameSprite(
            customSprite: customSprite,
            animalId: animalId,
            spritePath: spritePath,
            fallbackEmoji: fallbackEmoji,
            size: innerSize.clamp(size * 0.75, size * 0.98),
            semanticLabel: semanticLabel,
            emojiFontSize: emojiFontSize,
          ),
          if (isMutated && activeMutation.icon.isNotEmpty)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: accent!.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accent),
                ),
                child: Text(
                  activeMutation.icon,
                  style: TextStyle(fontSize: size * 0.18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
