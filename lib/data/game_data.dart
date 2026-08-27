import 'dart:math';

import '../models/animal.dart';
import '../models/egg.dart';
import '../models/mutation.dart';
import '../models/player_state.dart';
import '../utils/luck_logic.dart';
import 'elite_boss_sprite_paths.dart';

/// Static game content: all animals, eggs, and helpers to look them up.
class GameData {
  GameData._();

  static const dayGullEggId = 'daygull';
  static const dayGullAnimalIds = {
    'crossword_beast',
    'boba_bazooka',
    'the_hatched_egg',
  };

  static const animals = <Animal>[
    // Basic Egg
    Animal(
      id: 'chicken',
      name: 'Chicken',
      rarity: Rarity.common,
      coinsPerSecond: 1,
      emoji: '🐔',
      spritePath: 'assets/images/animals/chicken.png',
    ),
    Animal(
      id: 'mouse',
      name: 'Mouse',
      rarity: Rarity.common,
      coinsPerSecond: 2,
      emoji: '🐭',
      spritePath: 'assets/images/animals/mouse.png',
    ),
    Animal(
      id: 'rabbit',
      name: 'Rabbit',
      rarity: Rarity.common,
      coinsPerSecond: 3,
      emoji: '🐰',
      spritePath: 'assets/images/animals/rabbit.png',
    ),
    // Forest Egg
    Animal(
      id: 'fox',
      name: 'Fox',
      rarity: Rarity.uncommon,
      coinsPerSecond: 8,
      emoji: '🦊',
      spritePath: 'assets/images/animals/fox.png',
    ),
    Animal(
      id: 'deer',
      name: 'Deer',
      rarity: Rarity.uncommon,
      coinsPerSecond: 10,
      emoji: '🦌',
      spritePath: 'assets/images/animals/deer.png',
    ),
    Animal(
      id: 'bear',
      name: 'Bear',
      rarity: Rarity.rare,
      coinsPerSecond: 20,
      emoji: '🐻',
      spritePath: 'assets/images/animals/bear.png',
    ),
    // Magic Egg
    Animal(
      id: 'tiger',
      name: 'Tiger',
      rarity: Rarity.epic,
      coinsPerSecond: 50,
      emoji: '🐯',
      spritePath: 'assets/images/animals/tiger.png',
    ),
    Animal(
      id: 'dragon',
      name: 'Dragon',
      rarity: Rarity.legendary,
      coinsPerSecond: 100,
      emoji: '🐉',
      spritePath: 'assets/images/animals/dragon.png',
    ),
    Animal(
      id: 'unicorn',
      name: 'Unicorn',
      rarity: Rarity.legendary,
      coinsPerSecond: 120,
      emoji: '🦄',
      spritePath: 'assets/images/animals/unicorn.png',
    ),
    // Farm Egg
    Animal(
      id: 'cow',
      name: 'Cow',
      rarity: Rarity.uncommon,
      coinsPerSecond: 15,
      emoji: '🐮',
      spritePath: 'assets/images/animals/cow.png',
    ),
    Animal(
      id: 'pig',
      name: 'Pig',
      rarity: Rarity.uncommon,
      coinsPerSecond: 18,
      emoji: '🐷',
      spritePath: 'assets/images/animals/pig.png',
    ),
    Animal(
      id: 'sheep',
      name: 'Sheep',
      rarity: Rarity.rare,
      coinsPerSecond: 25,
      emoji: '🐑',
      spritePath: 'assets/images/animals/sheep.png',
    ),
    Animal(
      id: 'horse',
      name: 'Horse',
      rarity: Rarity.rare,
      coinsPerSecond: 35,
      emoji: '🐴',
      spritePath: 'assets/images/animals/horse.png',
    ),
    // Jungle Egg
    Animal(
      id: 'monkey',
      name: 'Monkey',
      rarity: Rarity.rare,
      coinsPerSecond: 75,
      emoji: '🐵',
      spritePath: 'assets/images/animals/monkey.png',
    ),
    Animal(
      id: 'parrot',
      name: 'Parrot',
      rarity: Rarity.rare,
      coinsPerSecond: 90,
      emoji: '🦜',
      spritePath: 'assets/images/animals/parrot.png',
    ),
    Animal(
      id: 'snake',
      name: 'Snake',
      rarity: Rarity.epic,
      coinsPerSecond: 140,
      emoji: '🐍',
      spritePath: 'assets/images/animals/snake.png',
    ),
    Animal(
      id: 'gorilla',
      name: 'Gorilla',
      rarity: Rarity.epic,
      coinsPerSecond: 200,
      emoji: '🦍',
      spritePath: 'assets/images/animals/gorilla.png',
    ),
    // Ocean Egg
    Animal(
      id: 'fish',
      name: 'Fish',
      rarity: Rarity.rare,
      coinsPerSecond: 250,
      emoji: '🐟',
      spritePath: 'assets/images/animals/fish.png',
    ),
    Animal(
      id: 'turtle',
      name: 'Turtle',
      rarity: Rarity.epic,
      coinsPerSecond: 400,
      emoji: '🐢',
      spritePath: 'assets/images/animals/turtle.png',
    ),
    Animal(
      id: 'dolphin',
      name: 'Dolphin',
      rarity: Rarity.epic,
      coinsPerSecond: 650,
      emoji: '🐬',
      spritePath: 'assets/images/animals/dolphin.png',
    ),
    Animal(
      id: 'shark',
      name: 'Shark',
      rarity: Rarity.legendary,
      coinsPerSecond: 1000,
      emoji: '🦈',
      spritePath: 'assets/images/animals/shark.png',
    ),
    // Arctic Egg
    Animal(
      id: 'penguin',
      name: 'Penguin',
      rarity: Rarity.epic,
      coinsPerSecond: 1500,
      emoji: '🐧',
      spritePath: 'assets/images/animals/penguin.png',
    ),
    Animal(
      id: 'seal',
      name: 'Seal',
      rarity: Rarity.epic,
      coinsPerSecond: 2000,
      emoji: '🦭',
      spritePath: 'assets/images/animals/seal.png',
    ),
    Animal(
      id: 'polar_bear',
      name: 'Polar Bear',
      rarity: Rarity.legendary,
      coinsPerSecond: 3000,
      emoji: '🐻‍❄️',
      spritePath: 'assets/images/animals/polar_bear.png',
    ),
    Animal(
      id: 'snow_owl',
      name: 'Snow Owl',
      rarity: Rarity.legendary,
      coinsPerSecond: 4000,
      emoji: '🦉',
      spritePath: 'assets/images/animals/snow_owl.png',
    ),
    // Dino Egg
    Animal(
      id: 'raptor',
      name: 'Raptor',
      rarity: Rarity.epic,
      coinsPerSecond: 6000,
      emoji: '🦖',
      spritePath: 'assets/images/animals/raptor.png',
    ),
    Animal(
      id: 'triceratops',
      name: 'Triceratops',
      rarity: Rarity.legendary,
      coinsPerSecond: 10000,
      emoji: '🦕',
      spritePath: 'assets/images/animals/triceratops.png',
    ),
    Animal(
      id: 't_rex',
      name: 'T-Rex',
      rarity: Rarity.legendary,
      coinsPerSecond: 15000,
      emoji: '🦖',
      spritePath: 'assets/images/animals/t_rex.png',
    ),
    Animal(
      id: 'fossil_dragon',
      name: 'Fossil Dragon',
      rarity: Rarity.mythic,
      coinsPerSecond: 25000,
      emoji: '🐉',
      spritePath: 'assets/images/animals/fossil_dragon.png',
    ),
    // Space Egg
    Animal(
      id: 'moon_cat',
      name: 'Moon Cat',
      rarity: Rarity.legendary,
      coinsPerSecond: 50000,
      emoji: '🐱🌙',
      spritePath: 'assets/images/animals/moon_cat.png',
    ),
    Animal(
      id: 'star_fox',
      name: 'Star Fox',
      rarity: Rarity.legendary,
      coinsPerSecond: 75000,
      emoji: '🦊⭐',
      spritePath: 'assets/images/animals/star_fox.png',
    ),
    Animal(
      id: 'alien_slime',
      name: 'Alien Slime',
      rarity: Rarity.mythic,
      coinsPerSecond: 125000,
      emoji: '👽',
      spritePath: 'assets/images/animals/alien_slime.png',
    ),
    Animal(
      id: 'galaxy_dragon',
      name: 'Galaxy Dragon',
      rarity: Rarity.mythic,
      coinsPerSecond: 250000,
      emoji: '🐉🌌',
      spritePath: 'assets/images/animals/galaxy_dragon.png',
    ),
    // Ancient Egg
    Animal(
      id: 'scarab_beetle',
      name: 'Scarab Beetle',
      rarity: Rarity.epic,
      coinsPerSecond: 7000,
      emoji: '🪲',
      spritePath: 'assets/images/animals/scarab_beetle.png',
    ),
    Animal(
      id: 'saber_cub',
      name: 'Saber Cub',
      rarity: Rarity.legendary,
      coinsPerSecond: 9500,
      emoji: '🐯🗡️',
      spritePath: 'assets/images/animals/saber_cub.png',
    ),
    Animal(
      id: 'stone_golem',
      name: 'Stone Golem',
      rarity: Rarity.mythic,
      coinsPerSecond: 14000,
      emoji: '🗿',
      spritePath: 'assets/images/animals/stone_golem.png',
    ),
    // Royal Egg
    Animal(
      id: 'royal_chicken',
      name: 'Royal Chicken',
      rarity: Rarity.legendary,
      coinsPerSecond: 22000,
      emoji: '🐔👑',
      spritePath: 'assets/images/animals/royal_chicken.png',
    ),
    Animal(
      id: 'crown_fox',
      name: 'Crown Fox',
      rarity: Rarity.mythic,
      coinsPerSecond: 30000,
      emoji: '🦊👑',
      spritePath: 'assets/images/animals/crown_fox.png',
    ),
    Animal(
      id: 'gem_dragon',
      name: 'Gem Dragon',
      rarity: Rarity.mythic,
      coinsPerSecond: 45000,
      emoji: '🐉💎',
      spritePath: 'assets/images/animals/gem_dragon.png',
    ),
    // Celestial Egg
    Animal(
      id: 'cloud_bunny',
      name: 'Cloud Bunny',
      rarity: Rarity.mythic,
      coinsPerSecond: 70000,
      emoji: '🐰☁️',
      spritePath: 'assets/images/animals/cloud_bunny.png',
    ),
    Animal(
      id: 'sun_lion',
      name: 'Sun Lion',
      rarity: Rarity.mythic,
      coinsPerSecond: 95000,
      emoji: '🦁☀️',
      spritePath: 'assets/images/animals/sun_lion.png',
    ),
    Animal(
      id: 'cosmic_phoenix',
      name: 'Cosmic Phoenix',
      rarity: Rarity.mythic,
      coinsPerSecond: 140000,
      emoji: '🔥🐦',
      spritePath: 'assets/images/animals/cosmic_phoenix.png',
    ),
    // Void Egg
    Animal(
      id: 'void_mouse',
      name: 'Void Mouse',
      rarity: Rarity.mythic,
      coinsPerSecond: 220000,
      emoji: '🐭🌑',
      spritePath: 'assets/images/animals/void_mouse.png',
    ),
    Animal(
      id: 'eclipse_wolf',
      name: 'Eclipse Wolf',
      rarity: Rarity.mythic,
      coinsPerSecond: 300000,
      emoji: '🐺🌑',
      spritePath: 'assets/images/animals/eclipse_wolf.png',
    ),
    Animal(
      id: 'nebula_hydra',
      name: 'Nebula Hydra',
      rarity: Rarity.unknown,
      coinsPerSecond: 450000,
      emoji: '🐉🌌',
      spritePath: 'assets/images/animals/nebula_hydra.png',
    ),
    // DayGull Egg
    Animal(
      id: 'crossword_beast',
      name: 'Crossword Beast',
      rarity: Rarity.unknown,
      coinsPerSecond: 6500000,
      emoji: '🧩🐲',
      spritePath: 'assets/images/animals/crossword_beast.png',
    ),
    Animal(
      id: 'boba_bazooka',
      name: 'Boba Bazooka',
      rarity: Rarity.unknown,
      coinsPerSecond: 4200000,
      emoji: '🧋💥',
      spritePath: 'assets/images/animals/boba_bazooka.png',
    ),
    Animal(
      id: 'the_hatched_egg',
      name: 'The Hatched Egg',
      rarity: Rarity.boss,
      coinsPerSecond: 12000000,
      emoji: '🐣🥚',
      spritePath: 'assets/images/animals/the_hatched_egg.png',
    ),
    Animal(
      id: 'slime_pet',
      name: 'Slime Pet',
      rarity: Rarity.common,
      coinsPerSecond: 600000,
      emoji: '🟢💧',
      spritePath: 'assets/images/animals/slime_pet.png',
    ),
    Animal(
      id: 'egg_golem_pet',
      name: 'Egg Golem Pet',
      rarity: Rarity.legendary,
      coinsPerSecond: 900000,
      emoji: '🪨🥚',
      spritePath: 'assets/images/animals/egg_golem_pet.png',
    ),
    Animal(
      id: 'night_rooster',
      name: 'Night Rooster',
      rarity: Rarity.unknown,
      coinsPerSecond: 1500000,
      emoji: '🌑🐓',
      spritePath: 'assets/images/animals/night_rooster.png',
    ),
    Animal(
      id: 'slime_king',
      name: 'Slime King',
      rarity: Rarity.mythic,
      coinsPerSecond: 1800000,
      emoji: '👑🟢',
      spritePath: EliteBossSpritePaths.slimeKing,
    ),
    Animal(
      id: 'egg_guardian',
      name: 'Egg Guardian',
      rarity: Rarity.unknown,
      coinsPerSecond: 2200000,
      emoji: '🛡️🥚',
      spritePath: EliteBossSpritePaths.eggGuardian,
    ),
    Animal(
      id: 'shadow_phoenix',
      name: 'Shadow Phoenix',
      rarity: Rarity.boss,
      coinsPerSecond: 3000000,
      emoji: '🔥🐦‍🔥',
      spritePath: EliteBossSpritePaths.shadowPhoenix,
    ),
  ];

  /// Boss victory rewards are not hatchable and excluded from collection quest totals.
  static const bossVictoryRewardAnimalIds = {
    'slime_king',
    'egg_guardian',
    'shadow_phoenix',
  };

  /// Post-Rotten Shell hatchables extend the game without moving the existing
  /// complete-collection quest beyond its original late-game finish line.
  static const postRottenShellSecretAnimalIds = dayGullAnimalIds;

  static Iterable<Animal> get collectionQuestAnimals => animals.where(
    (animal) =>
        !bossVictoryRewardAnimalIds.contains(animal.id) &&
        !postRottenShellSecretAnimalIds.contains(animal.id),
  );

  static const mutations = <Mutation>[
    Mutation(
      id: 'none',
      displayName: 'Normal',
      chance: 70,
      incomeMultiplier: 1,
    ),
    Mutation(
      id: 'golden',
      displayName: 'Golden',
      chance: 20,
      incomeMultiplier: 2,
      icon: '✨',
      prefix: 'Golden',
    ),
    Mutation(
      id: 'rainbow',
      displayName: 'Rainbow',
      chance: 8,
      incomeMultiplier: 5,
      icon: '🌈',
      prefix: 'Rainbow',
    ),
    Mutation(
      id: 'shadow',
      displayName: 'Shadow',
      chance: 2,
      incomeMultiplier: 10,
      icon: '🌑',
      prefix: 'Shadow',
    ),
    Mutation(
      id: 'boss',
      displayName: 'Boss',
      chance: 0,
      incomeMultiplier: 25,
      icon: '👑',
      prefix: 'Boss',
    ),
  ];

  /// Eggs in progression order (basic → endgame).
  static const eggs = <Egg>[
    Egg(
      id: 'basic',
      name: 'Basic Egg',
      cost: 100,
      possibleAnimalIds: ['chicken', 'mouse', 'rabbit'],
      animalWeights: {'chicken': 60, 'mouse': 30, 'rabbit': 10},
      emoji: '🥚',
      description: 'Common farm friends',
      spritePath: 'assets/images/eggs/basic_egg.png',
    ),
    Egg(
      id: 'forest',
      name: 'Forest Egg',
      cost: 400,
      possibleAnimalIds: ['fox', 'deer', 'bear'],
      animalWeights: {'fox': 50, 'deer': 35, 'bear': 15},
      emoji: '🌲🥚',
      description: 'Woodland creatures',
      unlockLifetimeCoins: 300,
      spritePath: 'assets/images/eggs/forest_egg.png',
    ),
    Egg(
      id: 'farm',
      name: 'Farm Egg',
      cost: 800,
      possibleAnimalIds: ['cow', 'pig', 'sheep', 'horse'],
      animalWeights: {'cow': 35, 'pig': 30, 'sheep': 25, 'horse': 10},
      emoji: '🚜🥚',
      description: 'Barnyard beasts',
      unlockLifetimeCoins: 750,
      spritePath: 'assets/images/eggs/farm_egg.png',
    ),
    Egg(
      id: 'magic',
      name: 'Magic Egg',
      cost: 1500,
      possibleAnimalIds: ['tiger', 'dragon', 'unicorn'],
      animalWeights: {'tiger': 50, 'dragon': 35, 'unicorn': 15},
      emoji: '✨🥚',
      description: 'Legendary wonders',
      unlockLifetimeCoins: 2500,
      spritePath: 'assets/images/eggs/magic_egg.png',
    ),
    Egg(
      id: 'jungle',
      name: 'Jungle Egg',
      cost: 3500,
      possibleAnimalIds: ['monkey', 'parrot', 'snake', 'gorilla'],
      animalWeights: {'monkey': 40, 'parrot': 30, 'snake': 20, 'gorilla': 10},
      emoji: '🌴🥚',
      description: 'Wild jungle hunters',
      unlockLifetimeCoins: 5000,
      spritePath: 'assets/images/eggs/jungle_egg.png',
    ),
    Egg(
      id: 'ocean',
      name: 'Ocean Egg',
      cost: 12000,
      possibleAnimalIds: ['fish', 'turtle', 'dolphin', 'shark'],
      animalWeights: {'fish': 45, 'turtle': 30, 'dolphin': 18, 'shark': 7},
      emoji: '🌊🥚',
      description: 'Deep sea legends',
      unlockLifetimeCoins: 20000,
      spritePath: 'assets/images/eggs/ocean_egg.png',
    ),
    Egg(
      id: 'arctic',
      name: 'Arctic Egg',
      cost: 40000,
      possibleAnimalIds: ['penguin', 'seal', 'polar_bear', 'snow_owl'],
      animalWeights: {
        'penguin': 40,
        'seal': 30,
        'polar_bear': 20,
        'snow_owl': 10,
      },
      emoji: '❄️🥚',
      description: 'Frozen frontier friends',
      unlockLifetimeCoins: 75000,
      spritePath: 'assets/images/eggs/arctic_egg.png',
    ),
    Egg(
      id: 'dino',
      name: 'Dino Egg',
      cost: 125000,
      possibleAnimalIds: ['raptor', 'triceratops', 't_rex', 'fossil_dragon'],
      animalWeights: {
        'raptor': 40,
        'triceratops': 30,
        't_rex': 20,
        'fossil_dragon': 10,
      },
      emoji: '🦖🥚',
      description: 'Prehistoric power',
      unlockLifetimeCoins: 200000,
      spritePath: 'assets/images/eggs/dino_egg.png',
    ),
    Egg(
      id: 'space',
      name: 'Space Egg',
      cost: 500000,
      possibleAnimalIds: [
        'moon_cat',
        'star_fox',
        'alien_slime',
        'galaxy_dragon',
      ],
      animalWeights: {
        'moon_cat': 40,
        'star_fox': 30,
        'alien_slime': 20,
        'galaxy_dragon': 10,
      },
      emoji: '🚀🥚',
      description: 'Cosmic creatures',
      unlockLifetimeCoins: 750000,
      spritePath: 'assets/images/eggs/space_egg.png',
    ),
    Egg(
      id: 'ancient',
      name: 'Ancient Egg',
      cost: 1500000,
      possibleAnimalIds: ['scarab_beetle', 'saber_cub', 'stone_golem'],
      animalWeights: {'scarab_beetle': 50, 'saber_cub': 35, 'stone_golem': 15},
      emoji: '🏛️🥚',
      description: 'Ruins and relic beasts',
      unlockRebirthLevel: 1,
      spritePath: 'assets/images/eggs/ancient_egg.png',
    ),
    Egg(
      id: 'royal',
      name: 'Royal Egg',
      cost: 5000000,
      possibleAnimalIds: ['royal_chicken', 'crown_fox', 'gem_dragon'],
      animalWeights: {'royal_chicken': 50, 'crown_fox': 35, 'gem_dragon': 15},
      emoji: '👑🥚',
      description: 'Regal hatchery treasures',
      unlockRebirthLevel: 2,
      spritePath: 'assets/images/eggs/royal_egg.png',
    ),
    Egg(
      id: 'celestial',
      name: 'Celestial Egg',
      cost: 15000000,
      possibleAnimalIds: ['cloud_bunny', 'sun_lion', 'cosmic_phoenix'],
      animalWeights: {'cloud_bunny': 50, 'sun_lion': 35, 'cosmic_phoenix': 15},
      emoji: '☀️🥚',
      description: 'Heavenly hatchlings',
      unlockRebirthLevel: 3,
      spritePath: 'assets/images/eggs/celestial_egg.png',
    ),
    Egg(
      id: 'void',
      name: 'Void Egg',
      cost: 50000000,
      possibleAnimalIds: ['void_mouse', 'eclipse_wolf', 'nebula_hydra'],
      animalWeights: {'void_mouse': 50, 'eclipse_wolf': 35, 'nebula_hydra': 15},
      emoji: '🌑🥚',
      description: 'Dark dimension dwellers',
      unlockRebirthLevel: 5,
      spritePath: 'assets/images/eggs/void_egg.png',
    ),
    Egg(
      id: dayGullEggId,
      name: 'DayGull Egg',
      cost: 250000000,
      possibleAnimalIds: ['crossword_beast', 'boba_bazooka', 'the_hatched_egg'],
      animalWeights: {
        'crossword_beast': 60,
        'boba_bazooka': 35,
        'the_hatched_egg': 5,
      },
      emoji: '🌘🥚',
      description: 'Rule-breaking hatchlings beyond the final shell',
      spritePath: 'assets/images/eggs/daygull_egg.png',
    ),
  ];

  /// Battle Token eggs (shown separately in the shop).
  static const battleEggs = <Egg>[
    Egg(
      id: 'boss_egg',
      name: 'Boss Egg',
      cost: 10,
      possibleAnimalIds: ['slime_pet', 'egg_golem_pet', 'night_rooster'],
      animalWeights: {'slime_pet': 65, 'egg_golem_pet': 30, 'night_rooster': 5},
      emoji: '⚔️🥚',
      description: 'Battle-hardened companions',
      spritePath: 'assets/images/eggs/boss_egg.png',
      costCurrency: EggCostCurrency.battleTokens,
    ),
  ];

  static const int unlockBossMutationCost = 40;
  static const int applyBossMutationCost = 100;

  static PlayerState startingPlayerState() => PlayerState.initial();

  /// First built-in egg in progression order that can hatch [animalId].
  static Egg? progressionEggForAnimal(String animalId) {
    for (final egg in eggs) {
      if (egg.possibleAnimalIds.contains(animalId)) return egg;
    }
    return null;
  }

  /// Lower values sort earlier (basic → endgame). Unknown animals sort last.
  static int progressionIndexForAnimal(String animalId) {
    for (var eggIndex = 0; eggIndex < eggs.length; eggIndex++) {
      final slot = eggs[eggIndex].possibleAnimalIds.indexOf(animalId);
      if (slot >= 0) return eggIndex * 100 + slot;
    }
    return 99999;
  }

  /// All animals ordered by built-in egg progression.
  static final List<Animal> animalsInProgressionOrder =
      _buildAnimalsInProgressionOrder();

  static List<Animal> _buildAnimalsInProgressionOrder() {
    final seen = <String>{};
    final ordered = <Animal>[];

    for (final egg in eggs) {
      for (final animalId in egg.possibleAnimalIds) {
        if (!seen.add(animalId)) continue;
        final animal = animalById(animalId);
        if (animal != null) ordered.add(animal);
      }
    }

    for (final animal in animals) {
      if (seen.add(animal.id)) ordered.add(animal);
    }

    return ordered;
  }

  static Animal? animalById(String id) {
    for (final animal in animals) {
      if (animal.id == id) return animal;
    }
    return null;
  }

  static Egg? eggById(String id) {
    for (final egg in eggs) {
      if (egg.id == id) return egg;
    }
    for (final egg in battleEggs) {
      if (egg.id == id) return egg;
    }
    return null;
  }

  static Mutation? mutationById(String id) {
    for (final mutation in mutations) {
      if (mutation.id == id) return mutation;
    }
    return null;
  }

  /// Roll a mutation using base chances (Luck Level 1).
  static Mutation rollMutation(Random random) {
    return LuckLogic.rollMutation(random, LuckLogic.minLevel);
  }

  /// Sort owned animals by rarity, then base income, then name.
  static int compareOwnedAnimals(String animalIdA, String animalIdB) {
    final animalA = animalById(animalIdA);
    final animalB = animalById(animalIdB);
    if (animalA == null || animalB == null) {
      return animalIdA.compareTo(animalIdB);
    }

    final rarityCompare = animalB.rarity.sortOrder.compareTo(
      animalA.rarity.sortOrder,
    );
    if (rarityCompare != 0) return rarityCompare;

    final incomeCompare = animalB.coinsPerSecond.compareTo(
      animalA.coinsPerSecond,
    );
    if (incomeCompare != 0) return incomeCompare;

    return animalA.name.compareTo(animalB.name);
  }
}
