import 'dart:math';

import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/models/egg.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/utils/built_in_egg_logic.dart';
import 'package:egg_hatchers/utils/custom_egg_logic.dart';
import 'package:egg_hatchers/utils/egg_shard_logic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('built-in egg weighted roll only returns valid animals', () {
    final random = Random(7);
    final basic = GameData.eggById('basic')!;

    for (var i = 0; i < 50; i++) {
      final animalId = BuiltInEggLogic.rollAnimal(basic, random);
      expect(basic.possibleAnimalIds, contains(animalId));
    }
  });

  test('built-in egg without weights uses equal fallback', () {
    const egg = Egg(
      id: 'test',
      name: 'Test',
      cost: 100,
      possibleAnimalIds: ['chicken', 'mouse'],
      emoji: '🥚',
    );
    final weights = BuiltInEggLogic.effectiveWeights(egg);
    expect(weights['chicken'], 1);
    expect(weights['mouse'], 1);
    expect(BuiltInEggLogic.roundedChancePercent(egg, 'chicken'), 50);
    expect(BuiltInEggLogic.roundedChancePercent(egg, 'mouse'), 50);
  });

  test('basic egg shop percents match configured weights', () {
    final basic = GameData.eggById('basic')!;
    expect(BuiltInEggLogic.roundedChancePercent(basic, 'chicken'), 60);
    expect(BuiltInEggLogic.roundedChancePercent(basic, 'mouse'), 30);
    expect(BuiltInEggLogic.roundedChancePercent(basic, 'rabbit'), 10);
  });

  test('space egg shop percents match configured weights', () {
    final space = GameData.eggById('space')!;
    expect(BuiltInEggLogic.roundedChancePercent(space, 'moon_cat'), 40);
    expect(BuiltInEggLogic.roundedChancePercent(space, 'star_fox'), 30);
    expect(BuiltInEggLogic.roundedChancePercent(space, 'alien_slime'), 20);
    expect(BuiltInEggLogic.roundedChancePercent(space, 'galaxy_dragon'), 10);
  });

  test('DayGull egg shop percents match configured weights', () {
    final dayGull = GameData.eggById(GameData.dayGullEggId)!;
    expect(
      BuiltInEggLogic.roundedChancePercent(dayGull, 'crossword_beast'),
      60,
    );
    expect(BuiltInEggLogic.roundedChancePercent(dayGull, 'boba_bazooka'), 35);
    expect(BuiltInEggLogic.roundedChancePercent(dayGull, 'the_hatched_egg'), 5);
  });

  test('rebirth egg shop percents match configured weights', () {
    final ancient = GameData.eggById('ancient')!;
    expect(BuiltInEggLogic.roundedChancePercent(ancient, 'scarab_beetle'), 50);
    expect(BuiltInEggLogic.roundedChancePercent(ancient, 'saber_cub'), 35);
    expect(BuiltInEggLogic.roundedChancePercent(ancient, 'stone_golem'), 15);
  });

  test('basic egg favors chicken over rabbit in weighted rolls', () {
    final basic = GameData.eggById('basic')!;
    var chicken = 0;
    var rabbit = 0;
    final random = Random(99);

    for (var i = 0; i < 500; i++) {
      final id = BuiltInEggLogic.rollAnimal(basic, random);
      if (id == 'chicken') chicken++;
      if (id == 'rabbit') rabbit++;
    }

    expect(chicken, greaterThan(rabbit));
  });

  test('rebirth eggs stay locked below required rebirth level', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    final ancient = GameData.eggById('ancient')!;
    final royal = GameData.eggById('royal')!;
    final celestial = GameData.eggById('celestial')!;
    final voidEgg = GameData.eggById('void')!;

    expect(game.isEggUnlocked(ancient), isFalse);
    expect(game.isEggUnlocked(royal), isFalse);
    expect(game.isEggUnlocked(celestial), isFalse);
    expect(game.isEggUnlocked(voidEgg), isFalse);

    game.setRebirthLevel(1);
    expect(game.isEggUnlocked(ancient), isTrue);
    expect(game.isEggUnlocked(royal), isFalse);

    game.setRebirthLevel(2);
    expect(game.isEggUnlocked(royal), isTrue);
    expect(game.isEggUnlocked(celestial), isFalse);

    game.setRebirthLevel(3);
    expect(game.isEggUnlocked(celestial), isTrue);
    expect(game.isEggUnlocked(voidEgg), isFalse);

    game.setRebirthLevel(5);
    expect(game.isEggUnlocked(voidEgg), isTrue);

    game.dispose();
  });

  test('DayGull Egg unlocks after a Rotten Shell win', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    final dayGull = GameData.eggById(GameData.dayGullEggId)!;
    expect(game.isDayGullEggUnlocked, isFalse);
    expect(game.isEggUnlocked(dayGull), isFalse);
    expect(
      game.visibleShopEggs.map((egg) => egg.id),
      isNot(contains(GameData.dayGullEggId)),
    );
    expect(
      game.eggLockedDisplayMessage(dayGull),
      'Beat The Rotten Shell to unlock the DayGull Egg.',
    );

    game.devAddBossWin(EggShardLogic.rottenShellBossId);

    expect(game.isDayGullEggUnlocked, isTrue);
    expect(game.isEggUnlocked(dayGull), isTrue);
    expect(
      game.visibleShopEggs.map((egg) => egg.id),
      contains(GameData.dayGullEggId),
    );
    game.dispose();
  });

  test('rebirth-required animals stay locked in custom egg editor logic', () {
    expect(
      CustomEggLogic.isAnimalUnlockedForCustomEgg(
        'scarab_beetle',
        999999999,
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
    expect(
      CustomEggLogic.isAnimalUnlockedForCustomEgg(
        'void_mouse',
        999999999,
        rebirthLevel: 4,
      ),
      isFalse,
    );
    expect(
      CustomEggLogic.isAnimalUnlockedForCustomEgg(
        'void_mouse',
        0,
        rebirthLevel: 5,
      ),
      isTrue,
    );
  });
}
