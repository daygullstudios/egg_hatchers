import '../data/game_data.dart';
import '../models/retro_pixel_sprite_definition.dart';
import '../models/retro_pixel_sprite_source.dart';
import 'retro_pixel_animal_catalog.dart';
import 'retro_pixel_hand_authored_sprites.dart';
import 'retro_pixel_massive_sprites.dart';
import 'retro_pixel_native_64_sprites.dart';

/// Retro Pixel animal sprites — explicit hand-authored grids only.
///
/// These sprites are separate from [SpriteReferenceData] and the 16×16 custom
/// sprite editor. Full coverage of [GameData.animals]; missing entries fall
/// back to Classic PNG rendering only if generation fails.
class RetroPixelAnimalSprites {
  RetroPixelAnimalSprites._();

  static const int minBuiltInGridSize = 48;

  static final Map<String, RetroPixelSpriteDefinition> _sprites =
      _buildSprites();

  static Map<String, RetroPixelSpriteDefinition> _buildSprites() {
    final merged = <String, RetroPixelSpriteDefinition>{
      ...RetroPixelHandAuthoredSprites.all,
      ...RetroPixelAnimalCatalog.generated,
      ...RetroPixelNative64Sprites.all,
    };

    return {
      for (final entry in merged.entries)
        entry.key: _normalizeGrid(entry.value),
    };
  }

  static RetroPixelSpriteDefinition _normalizeGrid(
    RetroPixelSpriteDefinition sprite,
  ) {
    if (sprite.width >= minBuiltInGridSize &&
        sprite.height >= minBuiltInGridSize) {
      return sprite;
    }
    return RetroPixelMassiveSprites.ensureMassiveGrid(sprite);
  }

  /// Every built-in animal id from game data.
  static Set<String> get supportedAnimalIds =>
      GameData.animals.map((animal) => animal.id).toSet();

  static bool hasSprite(String animalId) => _sprites.containsKey(animalId);

  static RetroPixelSpriteDefinition? spriteFor(String animalId) =>
      _sprites[animalId];

  static String? assetPathFor(String animalId) {
    if (!supportedAnimalIds.contains(animalId)) return null;
    return 'assets/images/animal_themes/retro_pixel/$animalId.png';
  }

  /// Debug/diagnostic: how this animal's Retro Pixel art was produced.
  static RetroPixelSpriteSource sourceFor(String animalId) {
    if (RetroPixelNative64Sprites.native64Ids.contains(animalId)) {
      return RetroPixelSpriteSource.native64;
    }
    if (RetroPixelAnimalCatalog.generated.containsKey(animalId)) {
      return RetroPixelSpriteSource.catalogGenerated;
    }
    if (RetroPixelHandAuthoredSprites.all.containsKey(animalId)) {
      return RetroPixelSpriteSource.legacyUpscaled;
    }
    return RetroPixelSpriteSource.legacyUpscaled;
  }
}
