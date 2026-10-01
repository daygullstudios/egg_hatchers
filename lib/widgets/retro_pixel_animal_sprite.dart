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

  @override
  Widget build(BuildContext context) {
    final definition = RetroPixelAnimalSprites.spriteFor(animalId);
    final themedAssetPath = RetroPixelAnimalSprites.assetPathFor(animalId);
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
            errorBuilder: definition == null || !definition.hasVisiblePixels
                ? null
                : (context, _, _) =>
                      RetroPixelSprite(definition: definition, size: size),
          ),
        ),
      );
    }

    if (definition == null || !definition.hasVisiblePixels) {
      return SizedBox(width: size, height: size);
    }

    return Semantics(
      label: semanticLabel,
      child: RetroPixelSprite(definition: definition, size: size),
    );
  }
}
