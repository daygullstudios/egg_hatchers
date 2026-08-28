import '../models/animal_sprite_theme.dart';

class EggThemeAssets {
  EggThemeAssets._();

  static const supportedEggIds = {
    'basic',
    'forest',
    'farm',
    'magic',
    'jungle',
    'ocean',
    'arctic',
    'dino',
    'space',
    'ancient',
    'royal',
    'celestial',
    'void',
    'daygull',
    'boss_egg',
  };

  static const _retroDirectory = 'assets/images/egg_themes/retro_pixel';
  static const _realisticDirectory = 'assets/images/egg_themes/realistic';
  static const _realisticAssetNames = {'daygull': 'daygull_v2'};

  static String? assetPathFor({
    required String themeId,
    required String eggId,
  }) {
    if (!supportedEggIds.contains(eggId)) return null;
    if (themeId == AnimalSpriteThemes.retroPixel.id) {
      return '$_retroDirectory/$eggId.png';
    }
    if (themeId == AnimalSpriteThemes.realistic.id) {
      final assetName = _realisticAssetNames[eggId] ?? eggId;
      return '$_realisticDirectory/$assetName.png';
    }
    return null;
  }
}
