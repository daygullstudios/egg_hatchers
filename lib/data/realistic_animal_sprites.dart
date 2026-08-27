/// AI-assisted realistic animal theme assets.
class RealisticAnimalSprites {
  RealisticAnimalSprites._();

  static const assetDirectory = 'assets/images/animal_themes/realistic';

  static const supportedAnimalIds = {
    'chicken',
    'mouse',
    'rabbit',
    'fox',
    'deer',
    'bear',
    'tiger',
    'dragon',
    'unicorn',
    'cow',
    'pig',
    'sheep',
    'horse',
    'monkey',
    'parrot',
    'snake',
    'gorilla',
    'fish',
    'turtle',
    'dolphin',
    'shark',
    'penguin',
    'seal',
    'polar_bear',
    'snow_owl',
    'raptor',
    'scarab_beetle',
    'saber_cub',
    'triceratops',
    'stone_golem',
    't_rex',
    'royal_chicken',
    'fossil_dragon',
    'crown_fox',
    'gem_dragon',
    'moon_cat',
    'cloud_bunny',
    'star_fox',
    'sun_lion',
    'alien_slime',
    'cosmic_phoenix',
    'void_mouse',
    'galaxy_dragon',
    'eclipse_wolf',
    'nebula_hydra',
    'crossword_beast',
    'boba_bazooka',
    'the_hatched_egg',
    'slime_pet',
    'egg_golem_pet',
    'night_rooster',
    'slime_king',
    'egg_guardian',
    'shadow_phoenix',
  };

  static const supportedBossIds = {
    'slime_boss',
    'egg_golem',
    'shadow_rooster',
    'night_rooster',
    'night_crow',
    'slime_king',
    'egg_guardian',
    'shadow_phoenix',
    'rotten_shell',
  };

  static const _extraAssetIds = {'rotten_shell'};

  static const _bossAssetAliases = {
    'slime_boss': 'slime_pet',
    'egg_golem': 'egg_golem_pet',
    'shadow_rooster': 'night_rooster',
    'night_crow': 'night_rooster',
  };

  static String canonicalAssetId(String animalOrBossId) {
    return _bossAssetAliases[animalOrBossId] ?? animalOrBossId;
  }

  static bool hasSprite(String animalOrBossId) {
    final assetId = canonicalAssetId(animalOrBossId);
    return supportedAnimalIds.contains(assetId) ||
        _extraAssetIds.contains(assetId);
  }

  static String? assetPathFor(String animalOrBossId) {
    final assetId = canonicalAssetId(animalOrBossId);
    if (!hasSprite(assetId)) return null;
    return '$assetDirectory/$assetId.png';
  }
}
