import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/data/quest_data.dart';
import 'package:egg_hatchers/models/egg.dart';
import 'package:egg_hatchers/utils/animal_fusion_logic.dart';
import 'package:egg_hatchers/utils/daily_system_logic.dart';
import 'package:egg_hatchers/utils/luck_logic.dart';
import 'package:egg_hatchers/utils/rebirth_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('egg tables are complete weighted rarity ladders', () {
    for (final egg in [...GameData.eggs, ...GameData.battleEggs]) {
      expect(egg.possibleAnimalIds, isNotEmpty, reason: egg.id);
      expect(egg.animalWeights.keys.toSet(), egg.possibleAnimalIds.toSet());
      expect(
        egg.animalWeights.values.fold<int>(0, (sum, weight) => sum + weight),
        100,
        reason: egg.id,
      );

      var previousRarity = -1;
      var previousWeight = 101;
      for (final animalId in egg.possibleAnimalIds) {
        final animal = GameData.animalById(animalId);
        expect(animal, isNotNull, reason: '$animalId in ${egg.id}');
        expect(
          animal!.rarity.sortOrder,
          greaterThanOrEqualTo(previousRarity),
          reason: '${egg.id} should progress from common to rare',
        );
        expect(
          egg.animalWeights[animalId]!,
          lessThanOrEqualTo(previousWeight),
          reason: '${egg.id} should not make later outcomes more common',
        );
        previousRarity = animal.rarity.sortOrder;
        previousWeight = egg.animalWeights[animalId]!;
      }
    }
  });

  test('release economy audit remains tied to candidate values', () {
    expect(_expectedMutationMultiplierAtLuckOne(), 1.7);

    const expectedIncome = <String, double>{
      'basic': 2.55,
      'forest': 17.85,
      'farm': 34.68,
      'magic': 132.6,
      'jungle': 178.5,
      'ocean': 713.15,
      'arctic': 3740,
      'dino': 18530,
      'space': 157250,
      'ancient': 15172.5,
      'royal': 48025,
      'celestial': 151725,
      'void': 480250,
      'daygull': 10149000,
      'boss_egg': 1249500,
    };

    for (final entry in expectedIncome.entries) {
      expect(
        _expectedIncome(GameData.eggById(entry.key)!),
        closeTo(entry.value, 0.001),
        reason: entry.key,
      );
    }

    expect(
      _expectedIncome(GameData.eggById('ancient')!),
      lessThan(_expectedIncome(GameData.eggById('space')!)),
    );
    expect(
      _expectedIncome(GameData.eggById('boss_egg')!),
      greaterThan(RebirthLogic.nextRebirthRequirement(0)),
    );
  });

  test('DayGull endgame income spike remains documented', () {
    final voidIncome = _expectedIncome(GameData.eggById('void')!);
    final dayGullIncome = _expectedIncome(GameData.eggById('daygull')!);
    final ultimateNest = GameData.animalById('the_hatched_egg')!;
    final nebulaHydra = GameData.animalById('nebula_hydra')!;

    expect(dayGullIncome, closeTo(10149000, 0.001));
    expect(dayGullIncome / voidIncome, closeTo(21.13, 0.01));
    expect(
      ultimateNest.coinsPerSecond / nebulaHydra.coinsPerSecond,
      closeTo(26.67, 0.01),
    );
    expect(
      GameData.postRottenShellSecretAnimalIds,
      containsAll(GameData.eggById('daygull')!.possibleAnimalIds),
    );
  });

  test('secondary reward systems remain tied to reviewed values', () {
    final weeklyDailyRewards = [
      for (var day = 1; day <= 7; day++) DailySystemLogic.rewardForDaySlot(day),
    ];
    expect(
      weeklyDailyRewards.fold<int>(0, (sum, reward) => sum + reward.coins),
      19000,
    );
    expect(
      weeklyDailyRewards.fold<int>(
        0,
        (sum, reward) => sum + reward.battleTokens,
      ),
      80,
    );

    expect(
      QuestData.all.fold<int>(0, (sum, quest) => sum + quest.rewardCoins),
      3048400,
    );
    expect(
      QuestData.all.fold<int>(
        0,
        (sum, quest) => sum + quest.rewardBattleTokens,
      ),
      240,
    );

    final goldenFusionExpectedOutput =
        AnimalFusionLogic.successChance *
        (0.9 * GameData.mutationById('rainbow')!.incomeMultiplier +
            0.1 * GameData.mutationById('shadow')!.incomeMultiplier);
    final goldenFusionInput =
        AnimalFusionLogic.inputQuantity *
        GameData.mutationById('golden')!.incomeMultiplier;
    expect(goldenFusionExpectedOutput / goldenFusionInput, closeTo(1.1, 0.001));
  });
}

double _expectedMutationMultiplierAtLuckOne() {
  final percentages = LuckLogic.mutationPercentages(1);
  var expected = 0.0;
  for (final mutation in GameData.mutations) {
    expected +=
        (percentages[mutation.id] ?? 0) / 100 * mutation.incomeMultiplier;
  }
  return expected;
}

double _expectedIncome(Egg egg) {
  final totalWeight = egg.animalWeights.values.fold<int>(
    0,
    (sum, weight) => sum + weight,
  );
  var baseIncome = 0.0;
  for (final animalId in egg.possibleAnimalIds) {
    final animal = GameData.animalById(animalId)!;
    baseIncome +=
        animal.coinsPerSecond * egg.animalWeights[animalId]! / totalWeight;
  }
  return baseIncome * _expectedMutationMultiplierAtLuckOne();
}
