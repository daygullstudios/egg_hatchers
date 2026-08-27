import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/models/custom_egg.dart';
import 'package:egg_hatchers/services/custom_egg_service.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/utils/custom_egg_logic.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const maxLifetime = 999999999;
  const maxRebirth = 5;

  test('old custom eggs without weights default to weight 1', () {
    final json = jsonEncode([
      {
        'id': 'custom_123',
        'name': 'Legacy Egg',
        'emoji': '🥚',
        'cost': 1000,
        'selectedAnimalIds': ['chicken', 'rabbit'],
        'isEnabled': true,
      },
    ]);

    final eggs = CustomEgg.listFromJsonString(json);
    expect(eggs, hasLength(1));

    final egg = eggs.first;
    expect(CustomEggLogic.effectiveWeights(egg), {'chicken': 1, 'rabbit': 1});
    expect(CustomEggLogic.chancePercentForAnimal(egg, 'chicken'), 50);
    expect(CustomEggLogic.chancePercentForAnimal(egg, 'rabbit'), 50);
  });

  test('weighted chances calculate percentages correctly', () {
    const egg = CustomEgg(
      id: 'custom_test',
      name: 'Weighted',
      emoji: '🥚',
      cost: 1000,
      selectedAnimalIds: ['chicken', 'rabbit', 'dragon'],
      animalWeights: {
        'chicken': 6,
        'rabbit': 3,
        'dragon': 1,
      },
    );

    expect(
      CustomEggLogic.chancePercentForAnimal(
        egg,
        'chicken',
        lifetimeCoinsEarned: maxLifetime,
      ),
      60,
    );
    expect(
      CustomEggLogic.chancePercentForAnimal(
        egg,
        'rabbit',
        lifetimeCoinsEarned: maxLifetime,
      ),
      30,
    );
    expect(
      CustomEggLogic.chancePercentForAnimal(
        egg,
        'dragon',
        lifetimeCoinsEarned: maxLifetime,
      ),
      10,
    );
  });

  test('minimum cost is higher for late-game animals', () {
    const chickenOnly = CustomEgg(
      id: 'custom_a',
      name: 'A',
      emoji: '🥚',
      cost: 100,
      selectedAnimalIds: ['chicken'],
      animalWeights: {'chicken': 1},
    );

    const galaxyOnly = CustomEgg(
      id: 'custom_b',
      name: 'B',
      emoji: '🥚',
      cost: 100,
      selectedAnimalIds: ['galaxy_dragon'],
      animalWeights: {'galaxy_dragon': 1},
    );

    final chickenMin = CustomEggLogic.minimumCostForCustomEgg(
      chickenOnly,
      lifetimeCoinsEarned: maxLifetime,
      rebirthLevel: maxRebirth,
    );
    final galaxyMin = CustomEggLogic.minimumCostForCustomEgg(
      galaxyOnly,
      lifetimeCoinsEarned: maxLifetime,
      rebirthLevel: maxRebirth,
    );

    expect(chickenMin, greaterThan(0));
    expect(galaxyMin, greaterThan(chickenMin));
    expect(galaxyMin, greaterThan(100000));
  });

  test('weighted mix prices mostly common animal with rare tail', () {
    const mixed = CustomEgg(
      id: 'custom_mix',
      name: 'Mix',
      emoji: '🥚',
      cost: 100,
      selectedAnimalIds: ['chicken', 'galaxy_dragon'],
      animalWeights: {
        'chicken': 9,
        'galaxy_dragon': 1,
      },
    );

    final mixedMin = CustomEggLogic.minimumCostForCustomEgg(
      mixed,
      lifetimeCoinsEarned: maxLifetime,
      rebirthLevel: maxRebirth,
    );
    const chickenOnly = CustomEgg(
      id: 'custom_c',
      name: 'C',
      emoji: '🥚',
      cost: 100,
      selectedAnimalIds: ['chicken'],
      animalWeights: {'chicken': 1},
    );
    final chickenMin = CustomEggLogic.minimumCostForCustomEgg(
      chickenOnly,
      lifetimeCoinsEarned: maxLifetime,
      rebirthLevel: maxRebirth,
    );

    expect(mixedMin, greaterThan(chickenMin));
    expect(
      mixedMin,
      lessThan(
        CustomEggLogic.minimumCostForCustomEgg(
          const CustomEgg(
            id: 'custom_d',
            name: 'D',
            emoji: '🥚',
            cost: 100,
            selectedAnimalIds: ['galaxy_dragon'],
            animalWeights: {'galaxy_dragon': 1},
          ),
          lifetimeCoinsEarned: maxLifetime,
          rebirthLevel: maxRebirth,
        ),
      ),
    );
  });

  test('weighted random favors higher weights', () {
    const egg = CustomEgg(
      id: 'custom_weighted',
      name: 'W',
      emoji: '🥚',
      cost: 1000,
      selectedAnimalIds: ['chicken', 'dragon'],
      animalWeights: {
        'chicken': 99,
        'dragon': 1,
      },
    );

    final random = Random(7);
    var chickenHits = 0;
    for (var i = 0; i < 200; i++) {
      if (CustomEggLogic.weightedRandomAnimal(egg, random) == 'chicken') {
        chickenHits++;
      }
    }
    expect(chickenHits, greaterThan(150));
  });

  test('forced hatch overrides custom egg weighted result', () async {
    SharedPreferences.setMockInitialValues({});
    const customEgg = CustomEgg(
      id: 'custom_force',
      name: 'Force Test',
      emoji: '🥚',
      cost: 1000,
      selectedAnimalIds: ['chicken'],
      animalWeights: {'chicken': 1},
    );
    final egg = customEgg.toEgg(lifetimeCoinsEarned: 0);
    final game = GameService(random: Random(1));
    await game.initialize();

    game.setForcedNextHatch('dragon', 'none');
    game.buyEgg(egg);
    final result = game.hatchEgg(egg, customEgg: customEgg);

    expect(result.animal.id, 'dragon');
    expect(game.hasForcedNextHatch, isFalse);
    game.dispose();
  });

  test('built-in egg hatching is unchanged', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService(random: Random(2));
    await game.initialize();

    final basicEgg = GameData.eggs.first;
    game.buyEgg(basicEgg);
    final result = game.hatchEgg(basicEgg);

    expect(basicEgg.possibleAnimalIds, contains(result.animal.id));
    game.dispose();
  });

  test('findSourceEggForAnimal uses cheapest built-in egg', () {
    final chickenSource = CustomEggLogic.findSourceEggForAnimal('chicken');
    expect(chickenSource?.id, 'basic');

    final galaxySource = CustomEggLogic.findSourceEggForAnimal('galaxy_dragon');
    expect(galaxySource?.id, 'space');
  });

  test('custom egg ids are unique', () {
    final ids = {for (var i = 0; i < 20; i++) CustomEgg.generateUniqueId()};
    expect(ids, hasLength(20));
  });

  test('animal unlock follows built-in egg lifetime requirements', () {
    expect(
      CustomEggLogic.isAnimalUnlockedForCustomEgg('chicken', 0),
      isTrue,
    );
    expect(
      CustomEggLogic.isAnimalUnlockedForCustomEgg('fox', 299),
      isFalse,
    );
    expect(
      CustomEggLogic.isAnimalUnlockedForCustomEgg('fox', 300),
      isTrue,
    );
    expect(
      CustomEggLogic.isAnimalUnlockedForCustomEgg('galaxy_dragon', 749999),
      isFalse,
    );
    expect(
      CustomEggLogic.isAnimalUnlockedForCustomEgg('galaxy_dragon', 750000),
      isTrue,
    );
    expect(
      CustomEggLogic.isAnimalUnlockedForCustomEgg(
        'scarab_beetle',
        maxLifetime,
        rebirthLevel: 0,
      ),
      isFalse,
    );
    expect(
      CustomEggLogic.isAnimalUnlockedForCustomEgg(
        'scarab_beetle',
        0,
        rebirthLevel: 1,
      ),
      isTrue,
    );
  });

  test('DayGull animals stay secret in custom egg editor', () {
    expect(
      CustomEggLogic.isAnimalUnlockedForCustomEgg(
        'crossword_beast',
        maxLifetime,
        rebirthLevel: maxRebirth,
      ),
      isFalse,
    );
    expect(
      CustomEggLogic.unlockMessageForAnimal('the_hatched_egg'),
      'Unlocks from the DayGull Egg after beating The Rotten Shell.',
    );
  });

  test('canAddAnimalToCustomEgg respects six animal limit', () {
    expect(
      CustomEggLogic.canAddAnimalToCustomEgg(
        'chicken',
        0,
        selectedCount: 6,
      ),
      isFalse,
    );
    expect(
      CustomEggLogic.canAddAnimalToCustomEgg(
        'chicken',
        0,
        selectedCount: 5,
      ),
      isTrue,
    );
  });

  test('custom egg service stores multiple eggs', () async {
    SharedPreferences.setMockInitialValues({});
    final service = CustomEggService();
    await service.initialize();

    const egg1 = CustomEgg(
      id: 'custom_one',
      name: 'Egg One',
      emoji: '🥚',
      cost: 100,
      selectedAnimalIds: ['chicken'],
    );
    const egg2 = CustomEgg(
      id: 'custom_two',
      name: 'Egg Two',
      emoji: '🐣',
      cost: 200,
      selectedAnimalIds: ['rabbit'],
    );

    await service.saveEgg(egg1);
    await service.saveEgg(egg2);

    expect(service.allEggs, hasLength(2));
    expect(service.getById('custom_one')?.name, 'Egg One');
    expect(service.getById('custom_two')?.name, 'Egg Two');

    await service.deleteEgg('custom_one');
    expect(service.allEggs, hasLength(1));
    expect(service.getById('custom_two'), isNotNull);
  });

  test('animalsInProgressionOrder follows built-in egg order', () {
    final ids = GameData.animalsInProgressionOrder.map((a) => a.id).toList();

    expect(ids.sublist(0, 3), ['chicken', 'mouse', 'rabbit']);
    expect(ids.sublist(3, 6), ['fox', 'deer', 'bear']);
    expect(ids.sublist(6, 10), ['cow', 'pig', 'sheep', 'horse']);
    expect(
      ids.sublist(29, 33),
      ['moon_cat', 'star_fox', 'alien_slime', 'galaxy_dragon'],
    );
    expect(
      ids.sublist(33, 36),
      ['scarab_beetle', 'saber_cub', 'stone_golem'],
    );
    expect(
      ids.sublist(36, 39),
      ['royal_chicken', 'crown_fox', 'gem_dragon'],
    );
    expect(
      ids.sublist(39, 42),
      ['cloud_bunny', 'sun_lion', 'cosmic_phoenix'],
    );
    expect(
      ids.sublist(42, 45),
      ['void_mouse', 'eclipse_wolf', 'nebula_hydra'],
    );
    expect(
      ids.sublist(45, 48),
      ['crossword_beast', 'boba_bazooka', 'the_hatched_egg'],
    );
    expect(
      ids.sublist(48, 51),
      ['slime_pet', 'egg_golem_pet', 'night_rooster'],
    );
    expect(
      ids.sublist(51, 54),
      ['slime_king', 'egg_guardian', 'shadow_phoenix'],
    );
    expect(ids.last, 'shadow_phoenix');
  });

  test('hatchable animals exclude locked selections for shop', () {
    const egg = CustomEgg(
      id: 'custom_locked',
      name: 'Locked Mix',
      emoji: '🥚',
      cost: 500,
      selectedAnimalIds: ['chicken', 'galaxy_dragon'],
      animalWeights: {'chicken': 1, 'galaxy_dragon': 1},
    );

    expect(egg.hatchableAnimalIds(0), ['chicken']);
    expect(egg.isShopValid(0), isTrue);
    expect(egg.hatchableAnimalIds(750000), contains('galaxy_dragon'));
  });
}
