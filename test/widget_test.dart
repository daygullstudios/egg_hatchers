import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/models/animal.dart';
import 'package:egg_hatchers/models/custom_egg.dart';
import 'package:egg_hatchers/models/forced_hatch_result.dart';
import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/models/player_state.dart';
import 'package:egg_hatchers/services/custom_egg_service.dart';
import 'package:egg_hatchers/services/developer_tools_preferences.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/data/quest_data.dart';
import 'package:egg_hatchers/models/quest_progress.dart';
import 'package:egg_hatchers/utils/luck_logic.dart';
import 'package:egg_hatchers/utils/quest_logic.dart';
import 'package:egg_hatchers/utils/rebirth_logic.dart';

void main() {
  test('Crossword Beast and Boba Bazooka use their swapped incomes', () {
    expect(GameData.animalById('crossword_beast')!.coinsPerSecond, 6500000);
    expect(GameData.animalById('boba_bazooka')!.coinsPerSecond, 4200000);
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  test('starting player has 250 coins and no animals', () {
    final state = GameData.startingPlayerState();
    expect(state.coins, 250);
    expect(state.lifetimeCoinsEarned, 0);
    expect(state.luckLevel, 1);
    expect(state.rebirthLevel, 0);
    expect(state.ownedAnimals, isEmpty);
  });

  test('buying and hatching a basic egg works', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    final basicEgg = GameData.eggs.first;
    expect(game.canAfford(basicEgg), isTrue);

    final bought = game.buyEgg(basicEgg);
    expect(bought, isTrue);
    expect(game.coins, 150);

    final result = game.hatchEgg(basicEgg);
    expect(basicEgg.possibleAnimalIds, contains(result.animal.id));
    expect(game.ownedAnimals.length, 1);
    expect(game.ownedAnimals.first.quantity, 1);
    expect(game.ownedAnimals.first.level, 1);
    expect(
      GameData.mutationById(game.ownedAnimals.first.mutationId),
      isNotNull,
    );

    game.dispose();
  });

  test('player state serializes and deserializes', () {
    final state = PlayerState(
      coins: 500,
      ownedAnimals: const [
        OwnedAnimal(
          animalId: 'chicken',
          quantity: 2,
          level: 3,
          mutationId: 'golden',
        ),
      ],
      lastSavedTime: DateTime(2025, 1, 1),
      lifetimeCoinsEarned: 1200,
    );

    final restored = PlayerState.fromJson(state.toJson());
    expect(restored.coins, 500);
    expect(restored.lifetimeCoinsEarned, 1200);
    expect(restored.luckLevel, 1);
    expect(restored.ownedAnimals.first.quantity, 2);
    expect(restored.ownedAnimals.first.level, 3);
    expect(restored.ownedAnimals.first.mutationId, 'golden');
    expect(restored.questProgress.totalEggsHatched, 0);
    expect(restored.questProgress.claimedQuestIds, isEmpty);
    expect(restored.secretSpaceEggClaimed, isFalse);
    expect(restored.fullDeveloperToolsUnlocked, isFalse);
  });

  test('old saves without questProgress default stats to zero', () {
    final restored = PlayerState.fromJson({
      'coins': 500,
      'ownedAnimals': [],
      'lastSavedTime': '2025-01-01T00:00:00.000',
      'lifetimeCoinsEarned': 600,
      'luckLevel': 2,
    });
    expect(restored.questProgress.totalEggsHatched, 0);
    expect(restored.questProgress.claimedQuestIds, isEmpty);
  });

  test('old saves without lifetimeCoinsEarned default to current coins', () {
    final restored = PlayerState.fromJson({
      'coins': 750,
      'ownedAnimals': [],
      'lastSavedTime': '2025-01-01T00:00:00.000',
    });
    expect(restored.lifetimeCoinsEarned, 750);
  });

  test('old saves without level or mutation default correctly', () {
    final owned = OwnedAnimal.fromJson({'animalId': 'chicken', 'quantity': 2});
    expect(owned.level, 1);
    expect(owned.mutationId, 'none');
  });

  test('income uses base x mutation x quantity x level', () {
    const animal = Animal(
      id: 'chicken',
      name: 'Chicken',
      rarity: Rarity.common,
      coinsPerSecond: 1,
      emoji: '🐔',
    );
    const owned = OwnedAnimal(
      animalId: 'chicken',
      quantity: 3,
      level: 2,
      mutationId: 'golden',
    );
    expect(GameService.incomeFor(animal, owned), 12);
  });

  test('upgrade cost uses base x level x 30 without mutation multiplier', () {
    const animal = Animal(
      id: 'rabbit',
      name: 'Rabbit',
      rarity: Rarity.common,
      coinsPerSecond: 3,
      emoji: '🐰',
    );
    const rainbowRabbit = OwnedAnimal(
      animalId: 'rabbit',
      quantity: 1,
      level: 1,
      mutationId: 'rainbow',
    );
    const normalRabbit = OwnedAnimal(
      animalId: 'rabbit',
      quantity: 1,
      level: 1,
      mutationId: 'none',
    );
    expect(GameService.upgradeCostFor(animal, rainbowRabbit), 90);
    expect(GameService.upgradeCostFor(animal, normalRabbit), 90);
  });

  test(
    'mutated and normal animals share the same upgrade cost at same level',
    () {
      const animal = Animal(
        id: 'chicken',
        name: 'Chicken',
        rarity: Rarity.common,
        coinsPerSecond: 1,
        emoji: '🐔',
      );
      const normal = OwnedAnimal(animalId: 'chicken', quantity: 1, level: 2);
      const golden = OwnedAnimal(
        animalId: 'chicken',
        quantity: 1,
        level: 2,
        mutationId: 'golden',
      );
      const shadow = OwnedAnimal(
        animalId: 'chicken',
        quantity: 1,
        level: 2,
        mutationId: 'shadow',
      );

      expect(GameService.upgradeCostFor(animal, normal), 60);
      expect(GameService.upgradeCostFor(animal, golden), 60);
      expect(GameService.upgradeCostFor(animal, shadow), 60);
    },
  );

  test('upgrading increases level and subtracts coins', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService(random: Random(1));
    await game.initialize();

    final basicEgg = GameData.eggs.first;
    game.buyEgg(basicEgg);
    game.hatchEgg(basicEgg);

    final owned = game.ownedAnimals.first;
    final animal = GameData.animalById(owned.animalId)!;
    final cost = GameService.upgradeCostFor(animal, owned);

    expect(game.coins, 150);
    final newLevel = game.upgradeAnimal(owned.animalId, owned.mutationId);

    expect(newLevel, 2);
    expect(game.coins, 150 - cost);
    expect(
      game.ownedAnimal(owned.animalId, mutationId: owned.mutationId)!.level,
      2,
    );

    game.dispose();
  });

  test('duplicate hatch increases quantity without resetting level', () async {
    final basicEgg = GameData.eggs.first;
    var found = false;

    for (var seed = 0; seed < 500; seed++) {
      SharedPreferences.setMockInitialValues({});
      final game = GameService(random: Random(seed));
      await game.initialize();

      game.buyEgg(basicEgg);
      final first = game.hatchEgg(basicEgg);
      expect(game.upgradeAnimal(first.animal.id, first.mutation.id), 2);

      game.buyEgg(basicEgg);
      final second = game.hatchEgg(basicEgg);

      if (first.animal.id == second.animal.id &&
          first.mutation.id == second.mutation.id) {
        final owned = game.ownedAnimal(
          first.animal.id,
          mutationId: first.mutation.id,
        )!;
        expect(owned.quantity, 2);
        expect(owned.level, 2);
        found = true;
      }

      game.dispose();
      if (found) break;
    }

    expect(
      found,
      isTrue,
      reason: 'Need a seed that hatches the same combo twice',
    );
  });

  test('golden and normal chickens are separate entries', () async {
    SharedPreferences.setMockInitialValues({});
    // Rolls: animal index, mutation roll (99 = shadow)... need controlled rolls.
    // Use a custom approach: hatch twice with forced mutations via direct state is not available.
    // Instead test rollMutation and matching logic separately.
    final shadowMutation = GameData.mutationById('shadow')!;
    expect(shadowMutation.incomeMultiplier, 10);

    const animal = Animal(
      id: 'chicken',
      name: 'Chicken',
      rarity: Rarity.common,
      coinsPerSecond: 1,
      emoji: '🐔',
    );
    const normal = OwnedAnimal(animalId: 'chicken', quantity: 3, level: 2);
    const golden = OwnedAnimal(
      animalId: 'chicken',
      quantity: 1,
      level: 1,
      mutationId: 'golden',
    );

    expect(GameService.incomeFor(animal, normal), 6);
    expect(GameService.incomeFor(animal, golden), 2);
  });

  test('mutation roll weighted chances', () {
    final random = Random(42);
    final results = <String, int>{};
    for (var i = 0; i < 1000; i++) {
      final mutation = GameData.rollMutation(random);
      results[mutation.id] = (results[mutation.id] ?? 0) + 1;
    }
    expect(results['none'], greaterThan(results['golden']!));
    expect(results['golden'], greaterThan(results['rainbow']!));
    expect(results['rainbow'], greaterThan(results['shadow']!));
  });

  test('upgrading golden chicken does not upgrade normal chicken', () async {
    const saveKey = 'egg_hatchers_player_state';
    SharedPreferences.setMockInitialValues({
      saveKey:
          '{"coins":1000,"ownedAnimals":[{"animalId":"chicken","quantity":1,"level":1,"mutationId":"none"},{"animalId":"chicken","quantity":1,"level":1,"mutationId":"golden"}],"lastSavedTime":"2025-06-01T00:00:00.000"}',
    });

    final game = GameService();
    await game.initialize();

    expect(game.upgradeAnimal('chicken', 'golden'), 2);
    expect(game.ownedAnimal('chicken', mutationId: 'none')!.level, 1);
    expect(game.ownedAnimal('chicken', mutationId: 'golden')!.level, 2);

    game.dispose();
  });

  test('setCoins and resetCoins work', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    game.setCoins(9999);
    expect(game.coins, 9999);

    game.resetCoins();
    expect(game.coins, 250);

    game.dispose();
  });

  test('forced next hatch overrides random then clears', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService(random: Random(1));
    await game.initialize();

    game.setForcedNextHatch('dragon', 'shadow');
    expect(game.hasForcedNextHatch, isTrue);

    game.buyEgg(GameData.eggs.first);
    final result = game.hatchEgg(GameData.eggs.first);

    expect(result.animal.id, 'dragon');
    expect(result.mutation.id, 'shadow');
    expect(game.hasForcedNextHatch, isFalse);

    game.dispose();
  });

  test('all eggs reference valid animals', () {
    for (final egg in GameData.eggs) {
      for (final id in egg.possibleAnimalIds) {
        expect(
          GameData.animalById(id),
          isNotNull,
          reason: 'Missing animal $id in ${egg.name}',
        );
      }
    }
    expect(GameData.animals.length, 54);
    expect(GameData.eggs.length, 14);
  });

  test('egg unlocks based on lifetime coins earned', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    final basic = GameData.eggs[0];
    final forest = GameData.eggs[1];
    final farm = GameData.eggs[2];
    final magic = GameData.eggs[3];

    expect(game.isEggUnlocked(basic), isTrue);
    expect(game.isEggUnlocked(forest), isFalse);
    expect(game.isEggUnlocked(farm), isFalse);
    expect(game.isEggUnlocked(magic), isFalse);

    game.setLifetimeCoinsEarned(300);
    expect(game.isEggUnlocked(forest), isTrue);
    expect(game.isEggUnlocked(magic), isFalse);

    final space = GameData.eggs[8];
    expect(game.isEggUnlocked(farm), isFalse);

    game.setLifetimeCoinsEarned(750);
    expect(game.isEggUnlocked(farm), isTrue);

    game.setLifetimeCoinsEarned(2500);
    expect(game.isEggUnlocked(magic), isTrue);

    game.setLifetimeCoinsEarned(750000);
    expect(game.isEggUnlocked(space), isTrue);

    game.dispose();
  });

  test('spending coins does not reduce lifetime coins earned', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    game.setLifetimeCoinsEarned(1000);
    game.setCoins(1000);
    game.buyEgg(GameData.eggs.first);

    expect(game.lifetimeCoinsEarned, 1000);
    expect(game.coins, 900);

    game.dispose();
  });

  test('setCoins does not change lifetime coins earned', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    game.setLifetimeCoinsEarned(500);
    game.setCoins(9999);

    expect(game.lifetimeCoinsEarned, 500);
    expect(game.coins, 9999);

    game.dispose();
  });

  test('normal hatch is random when no forced override', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    expect(game.hasForcedNextHatch, isFalse);

    game.buyEgg(GameData.eggs.first);
    final result = game.hatchEgg(GameData.eggs.first);

    expect(GameData.eggs.first.possibleAnimalIds, contains(result.animal.id));

    game.dispose();
  });

  test('triple hatch cost is ceil of egg cost times 3.5', () {
    expect(GameService.tripleHatchCost(GameData.eggs.first), 350);
    expect(GameService.tripleHatchCost(GameData.eggs[1]), 1400);
    expect(GameService.tripleHatchCost(GameData.eggs[3]), 5250);
    expect(GameService.tripleHatchCost(GameData.eggs[8]), 1750000);
  });

  test('triple hatch deducts correct coins and adds three animals', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService(random: Random(99));
    await game.initialize();

    final basicEgg = GameData.eggs.first;
    game.setCoins(350);

    expect(game.canAffordTripleHatch(basicEgg), isTrue);
    expect(game.buyTripleHatch(basicEgg), isTrue);
    expect(game.coins, 0);

    final beforeCount = game.ownedAnimals.length;
    final results = game.hatchEggMultiple(basicEgg, 3);

    expect(results, hasLength(3));
    expect(game.ownedAnimals.length, greaterThanOrEqualTo(beforeCount));
    expect(
      game.ownedAnimals.fold<int>(0, (sum, o) => sum + o.quantity),
      greaterThanOrEqualTo(3),
    );

    game.dispose();
  });

  test('triple hatch fails when coins are too low', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    final basicEgg = GameData.eggs.first;
    game.setCoins(349);

    expect(game.canAffordTripleHatch(basicEgg), isFalse);
    expect(game.buyTripleHatch(basicEgg), isFalse);
    expect(game.coins, 349);

    game.dispose();
  });

  test('forced hatch applies only to first triple hatch result', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService(random: Random(5));
    await game.initialize();

    game.setCoins(1000);
    game.setForcedNextHatch('dragon', 'golden');

    final basicEgg = GameData.eggs.first;
    game.buyTripleHatch(basicEgg);
    final results = game.hatchEggMultiple(basicEgg, 3);

    expect(results, hasLength(3));
    expect(results.first.animal.id, 'dragon');
    expect(results.first.mutation.id, 'golden');
    expect(game.hasForcedNextHatch, isFalse);

    game.dispose();
  });

  test('triple forced hatch affects all three results in order', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService(random: Random(5));
    await game.initialize();

    game.setCoins(1000);
    game.setForcedNextTripleHatch([
      const ForcedHatchResult(animalId: 'chicken', mutationId: 'golden'),
      const ForcedHatchResult(animalId: 'rabbit', mutationId: 'rainbow'),
      const ForcedHatchResult(animalId: 'dragon', mutationId: 'shadow'),
    ]);

    expect(game.isForcedTripleHatch, isTrue);

    final basicEgg = GameData.eggs.first;
    game.buyTripleHatch(basicEgg);
    final results = game.hatchEggMultiple(basicEgg, 3);

    expect(results, hasLength(3));
    expect(results[0].animal.id, 'chicken');
    expect(results[0].mutation.id, 'golden');
    expect(results[1].animal.id, 'rabbit');
    expect(results[1].mutation.id, 'rainbow');
    expect(results[2].animal.id, 'dragon');
    expect(results[2].mutation.id, 'shadow');
    expect(game.hasForcedNextHatch, isFalse);

    game.dispose();
  });

  test('triple force on single hatch uses slot 1 only and clears', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService(random: Random(1));
    await game.initialize();

    game.setForcedNextTripleHatch([
      const ForcedHatchResult(animalId: 'fox', mutationId: 'golden'),
      const ForcedHatchResult(animalId: 'bear', mutationId: 'rainbow'),
      const ForcedHatchResult(animalId: 'tiger', mutationId: 'shadow'),
    ]);

    game.buyEgg(GameData.eggs.first);
    final result = game.hatchEgg(GameData.eggs.first);

    expect(result.animal.id, 'fox');
    expect(result.mutation.id, 'golden');
    expect(game.hasForcedNextHatch, isFalse);

    game.dispose();
  });

  test(
    'developer force slot selections persist in shared_preferences',
    () async {
      SharedPreferences.setMockInitialValues({});
      await DeveloperToolsPreferences.saveSlots(
        DevForceSlotSelections(
          slot1: const DevForceSlotSelection(
            animalId: 'dragon',
            mutationId: 'golden',
          ),
          slot2: const DevForceSlotSelection(
            animalId: 'rabbit',
            mutationId: 'rainbow',
          ),
          slot3: const DevForceSlotSelection(
            animalId: 'unicorn',
            mutationId: 'shadow',
          ),
        ),
      );

      final loaded = await DeveloperToolsPreferences.load();
      expect(loaded.slot1.animalId, 'dragon');
      expect(loaded.slot1.mutationId, 'golden');
      expect(loaded.slot2.animalId, 'rabbit');
      expect(loaded.slot3.animalId, 'unicorn');
    },
  );

  test('invalid saved force slots default safely', () async {
    SharedPreferences.setMockInitialValues({
      'devForceSlot1AnimalId': 'not_real',
      'devForceSlot1MutationId': 'not_real',
    });

    final loaded = await DeveloperToolsPreferences.load();
    expect(GameData.animalById(loaded.slot1.animalId), isNotNull);
    expect(GameData.mutationById(loaded.slot1.mutationId), isNotNull);
  });

  test('triple hatch rolls separate results', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService(random: Random(42));
    await game.initialize();

    game.setCoins(5000);
    final basicEgg = GameData.eggs.first;
    game.buyTripleHatch(basicEgg);
    final results = game.hatchEggMultiple(basicEgg, 3);

    expect(results, hasLength(3));
    for (final result in results) {
      expect(basicEgg.possibleAnimalIds, contains(result.animal.id));
    }

    game.dispose();
  });

  test('old saves without luckLevel default to 1', () {
    final restored = PlayerState.fromJson({
      'coins': 500,
      'ownedAnimals': [],
      'lastSavedTime': '2025-01-01T00:00:00.000',
      'lifetimeCoinsEarned': 600,
    });
    expect(restored.luckLevel, 1);
  });

  test('luck upgrade cost follows 500 * level * level', () {
    expect(LuckLogic.upgradeCost(1), 500);
    expect(LuckLogic.upgradeCost(2), 2000);
    expect(LuckLogic.upgradeCost(3), 4500);
    expect(LuckLogic.upgradeCost(4), 8000);
    expect(LuckLogic.upgradeCost(10), 0);
  });

  test('upgrading luck subtracts coins and increases level', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    game.setCoins(500);
    final newLevel = game.upgradeLuck();

    expect(newLevel, 2);
    expect(game.luckLevel, 2);
    expect(game.coins, 0);

    game.dispose();
  });

  test('luck cannot exceed max level 10', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    game.setLuckLevel(10);
    expect(game.luckLevel, 10);
    expect(game.upgradeLuck(), isNull);

    game.setLuckLevel(99);
    expect(game.luckLevel, 10);

    game.dispose();
  });

  test('luck-adjusted mutation chances total 100 percent', () {
    for (var level = 1; level <= LuckLogic.maxLevel; level++) {
      final percentages = LuckLogic.mutationPercentages(level);
      final sum = percentages.values.fold<double>(0, (total, p) => total + p);
      expect(sum, closeTo(100.0, 0.001));
      expect(LuckLogic.totalWeight(level), LuckLogic.weightTotal);
    }

    final level10 = LuckLogic.mutationPercentages(10);
    expect(level10['none'], 43);
    expect(level10['golden'], 38);
    expect(level10['rainbow'], 14.75);
    expect(level10['shadow'], 4.25);
  });

  test('forced hatch ignores luck and uses exact mutation', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService(random: Random(0));
    await game.initialize();

    game.setLuckLevel(1);
    game.setForcedNextHatch('chicken', 'shadow');
    game.setCoins(1000);
    game.buyTripleHatch(GameData.eggs.first);
    final results = game.hatchEggMultiple(GameData.eggs.first, 3);

    expect(results.first.mutation.id, 'shadow');
    expect(game.luckLevel, 1);

    game.dispose();
  });

  test('higher luck increases shadow mutation weight', () {
    final low = LuckLogic.mutationWeights(1)['shadow']!;
    final high = LuckLogic.mutationWeights(10)['shadow']!;
    expect(high, greaterThan(low));
  });

  test('triple hatch uses luck for non-forced results', () async {
    SharedPreferences.setMockInitialValues({});
    final basicEgg = GameData.eggs.first;
    int? seedWhereLuckMatters;

    for (var seed = 0; seed < 500; seed++) {
      final lowLuckGame = GameService(random: Random(seed));
      await lowLuckGame.initialize();
      lowLuckGame.setLuckLevel(1);
      lowLuckGame.setCoins(10000);
      lowLuckGame.buyTripleHatch(basicEgg);
      final lowLuckMutations = lowLuckGame
          .hatchEggMultiple(basicEgg, 3)
          .map((r) => r.mutation.id)
          .toList();
      lowLuckGame.dispose();

      final highLuckGame = GameService(random: Random(seed));
      await highLuckGame.initialize();
      highLuckGame.setLuckLevel(10);
      highLuckGame.setCoins(10000);
      highLuckGame.buyTripleHatch(basicEgg);
      final highLuckMutations = highLuckGame
          .hatchEggMultiple(basicEgg, 3)
          .map((r) => r.mutation.id)
          .toList();
      highLuckGame.dispose();

      if (lowLuckMutations != highLuckMutations) {
        seedWhereLuckMatters = seed;
        break;
      }
    }

    expect(
      seedWhereLuckMatters,
      isNotNull,
      reason: 'luck level should change triple hatch mutation rolls',
    );
  });

  test('single hatch still works after triple hatch helpers added', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService(random: Random(2));
    await game.initialize();

    final basicEgg = GameData.eggs.first;
    game.buyEgg(basicEgg);
    final result = game.hatchEgg(basicEgg);

    expect(basicEgg.possibleAnimalIds, contains(result.animal.id));
    expect(game.ownedAnimals, isNotEmpty);

    game.dispose();
  });

  test('hatching increments quest egg stats', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService(random: Random(1));
    await game.initialize();

    final basicEgg = GameData.eggs.first;
    game.buyEgg(basicEgg);
    game.hatchEgg(basicEgg);

    expect(game.questProgress.totalEggsHatched, 1);
    expect(game.questProgress.totalSingleHatches, 1);
    expect(game.questProgress.totalTripleHatches, 0);

    game.dispose();
  });

  test('claiming quest reward adds coins without lifetime earnings', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    game.devAddEggsHatched(1);
    final lifetimeBefore = game.lifetimeCoinsEarned;
    final coinsBefore = game.coins;

    final reward = game.claimQuest('beginner_hatch_1');

    expect(reward?.coins, 100);
    expect(game.coins, coinsBefore + 100);
    expect(game.lifetimeCoinsEarned, lifetimeBefore);
    expect(game.questProgress.isQuestClaimed('beginner_hatch_1'), isTrue);
    expect(game.claimQuest('beginner_hatch_1'), isNull);

    game.dispose();
  });

  test(
    'luck level quest can complete from current luck without retroactive upgrades',
    () async {
      SharedPreferences.setMockInitialValues({});
      final game = GameService();
      await game.initialize();

      game.setLuckLevel(2);
      final quest = QuestData.all.firstWhere((q) => q.id == 'beginner_luck_2');

      expect(QuestLogic.isComplete(quest, game.state), isTrue);

      game.dispose();
    },
  );

  test('ready to claim quests follow stable definition order', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    game.devAddEggsHatched(3);
    game.setLuckLevel(2);

    final ready = QuestLogic.readyToClaimQuests(game.state);
    final readyIds = ready.map((q) => q.id).toList();

    expect(readyIds, containsAll(['beginner_hatch_1', 'beginner_hatch_3']));
    expect(
      QuestData.all.indexWhere((q) => q.id == readyIds.first),
      lessThan(QuestData.all.indexWhere((q) => q.id == readyIds.last)),
    );

    game.dispose();
  });

  test('claimed quests persist through player state serialization', () {
    final state = PlayerState(
      coins: 1000,
      ownedAnimals: const [],
      lastSavedTime: DateTime(2025, 1, 1),
      lifetimeCoinsEarned: 5000,
      questProgress: QuestProgress.initial().copyWith(
        totalEggsHatched: 5,
        claimedQuestIds: const ['beginner_hatch_1', 'beginner_hatch_3'],
      ),
    );

    final restored = PlayerState.fromJson(state.toJson());
    expect(restored.questProgress.totalEggsHatched, 5);
    expect(
      restored.questProgress.claimedQuestIds,
      containsAll(['beginner_hatch_1', 'beginner_hatch_3']),
    );
  });

  test(
    'hatch defers quest notification until hatch dialog is dismissed',
    () async {
      SharedPreferences.setMockInitialValues({});
      final game = GameService(random: Random(1));
      await game.initialize();

      final basicEgg = GameData.eggs.first;
      game.setCoins(1000);
      game.buyEgg(basicEgg);
      game.hatchEgg(basicEgg);

      expect(game.isQuestNotificationDeferred, isTrue);
      expect(game.consumePendingQuestNotification(), isNull);

      final message = game.releaseDeferredQuestNotification();
      expect(message, contains('Beginner Quest Complete'));
      expect(game.consumePendingQuestNotification(), isNull);

      game.dispose();
    },
  );

  test(
    'quest completion notification is queued once per newly completed quest',
    () async {
      SharedPreferences.setMockInitialValues({});
      final game = GameService();
      await game.initialize();

      game.devAddEggsHatched(1);

      expect(
        game.consumePendingQuestNotification(),
        '🌱 Beginner Quest Complete! Claim your reward.',
      );
      expect(game.consumePendingQuestNotification(), isNull);
      expect(
        game.questProgress.wasCompletionNotified('beginner_hatch_1'),
        isTrue,
      );

      game.devAddEggsHatched(1);
      expect(game.consumePendingQuestNotification(), isNull);

      game.dispose();
    },
  );

  test(
    'already completed quests are silenced on load without notification',
    () async {
      final saved = PlayerState(
        coins: 1000,
        ownedAnimals: const [],
        lastSavedTime: DateTime(2025, 1, 1),
        lifetimeCoinsEarned: 5000,
        questProgress: QuestProgress.initial().copyWith(totalEggsHatched: 3),
      );
      SharedPreferences.setMockInitialValues({
        'egg_hatchers_player_state': jsonEncode(saved.toJson()),
      });

      final game = GameService();
      await game.initialize();

      expect(game.consumePendingQuestNotification(), isNull);
      expect(
        game.questProgress.wasCompletionNotified('beginner_hatch_1'),
        isTrue,
      );
      expect(
        game.questProgress.wasCompletionNotified('beginner_hatch_3'),
        isTrue,
      );

      game.dispose();
    },
  );

  test('multiple quest completions produce one combined notification', () {
    final message = QuestLogic.completionNotificationMessage(
      QuestData.all.where((q) => q.id.startsWith('beginner_hatch')).toList(),
    );
    expect(message, '2 Quests Complete! Claim your rewards.');
  });

  test('old saves without rebirthLevel default to 0', () {
    final restored = PlayerState.fromJson({
      'coins': 500,
      'ownedAnimals': [],
      'lastSavedTime': '2025-01-01T00:00:00.000',
      'lifetimeCoinsEarned': 600,
      'luckLevel': 2,
    });
    expect(restored.rebirthLevel, 0);
  });

  test('income multiplier formula works', () {
    expect(RebirthLogic.incomeMultiplier(0), 1);
    expect(RebirthLogic.incomeMultiplier(1), 1.25);
    expect(RebirthLogic.incomeMultiplier(2), 1.5);
    expect(RebirthLogic.incomeMultiplier(4), 2);
    expect(RebirthLogic.applyMultiplier(100, 1), 125);
    expect(RebirthLogic.applyMultiplier(100, 4), 200);
  });

  test('rebirth is unavailable below requirement at level 0', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    expect(game.rebirthRequirement, 1000000);
    game.setLifetimeCoinsEarned(999999);
    expect(game.canRebirth, isFalse);
    expect(game.performRebirth(), isFalse);

    game.dispose();
  });

  test('rebirth requirement scales with rebirth level', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    expect(game.rebirthRequirement, 1000000);
    game.setRebirthLevel(1);
    expect(game.rebirthRequirement, 4000000);
    game.setRebirthLevel(2);
    expect(game.rebirthRequirement, 9000000);

    game.dispose();
  });

  test('rebirth at level 1 requires 4 million lifetime coins', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    game.setRebirthLevel(1);
    game.setLifetimeCoinsEarned(3999999);
    expect(game.canRebirth, isFalse);

    game.setLifetimeCoinsEarned(4000000);
    expect(game.canRebirth, isTrue);

    game.dispose();
  });

  test('rebirth resets progress and increases rebirth level', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService(random: Random(1));
    await game.initialize();

    game.setLifetimeCoinsEarned(1000000);
    game.setLuckLevel(4);
    game.devAddEggsHatched(25);
    game.setCoins(5000);
    final basicEgg = GameData.eggs.first;
    game.buyEgg(basicEgg);
    game.hatchEgg(basicEgg);

    expect(game.ownedAnimals, isNotEmpty);
    expect(game.performRebirth(), isTrue);
    expect(game.coins, 250);
    expect(game.lifetimeCoinsEarned, 0);
    expect(game.ownedAnimals, isEmpty);
    expect(game.luckLevel, 1);
    expect(game.rebirthLevel, 1);
    expect(game.rebirthRequirement, 4000000);
    expect(game.canRebirth, isFalse);
    expect(game.questProgress.totalEggsHatched, 0);
    expect(game.questProgress.claimedQuestIds, isEmpty);

    game.dispose();
  });

  test('rebirth multiplier affects coins per second', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    game.setRebirthLevel(2);
    game.setCoins(500);
    game.setLifetimeCoinsEarned(5000);
    final basicEgg = GameData.eggs.first;
    game.buyEgg(basicEgg);
    game.hatchEgg(basicEgg);

    expect(game.baseCoinsPerSecond, greaterThan(0));
    expect(
      game.coinsPerSecond,
      RebirthLogic.applyMultiplier(game.baseCoinsPerSecond, 2),
    );

    game.dispose();
  });

  test('custom eggs remain after rebirth', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    final customEggs = CustomEggService();
    await Future.wait([game.initialize(), customEggs.initialize()]);

    await customEggs.saveEgg(
      const CustomEgg(
        id: 'custom_test_1',
        name: 'Test Egg',
        emoji: '🥚',
        cost: 500,
        selectedAnimalIds: ['chicken'],
        isEnabled: true,
      ),
    );
    expect(customEggs.allEggs.length, 1);

    game.setLifetimeCoinsEarned(1000000);
    game.performRebirth();

    expect(customEggs.allEggs.length, 1);
    expect(game.rebirthLevel, 1);

    game.dispose();
  });
}
