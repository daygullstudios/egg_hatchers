import 'package:flutter/material.dart';

import '../data/retro_pixel_animal_sprites.dart';
import 'retro_pixel_sprite.dart';

/// Crisp retro pixel-art animal sprite (nearest-neighbor block scaling).
class RetroPixelAnimalSprite extends StatelessWidget {
  const RetroPixelAnimalSprite({
    super.key,
    required this.animalId,
    required this.size,
    this.semanticLabel,
  });

  final String animalId;
  final double size;
  final String? semanticLabel;

  static const _themedAssetPaths = {
    'boba_bazooka': 'assets/images/animal_themes/retro_pixel/boba_bazooka.png',
    'crossword_beast':
        'assets/images/animal_themes/retro_pixel/crossword_beast.png',
    'the_hatched_egg':
        'assets/images/animal_themes/retro_pixel/the_hatched_egg.png',
  };

  @override
  Widget build(BuildContext context) {
    final themedAssetPath = _themedAssetPaths[animalId];
    if (themedAssetPath != null) {
      return Semantics(
        label: semanticLabel,
        child: SizedBox(
          width: size,
          height: size,
          child: Image.asset(
            themedAssetPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
          ),
        ),
      );
    }

    final definition = RetroPixelAnimalSprites.spriteFor(animalId);
    if (definition == null || !definition.hasVisiblePixels) {
      return SizedBox(width: size, height: size);
    }

    return Semantics(
      label: semanticLabel,
      child: RetroPixelSprite(definition: definition, size: size),
    );
  }
}
