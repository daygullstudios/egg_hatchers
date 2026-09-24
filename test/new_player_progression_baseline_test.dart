import 'dart:math';

import 'package:egg_hatchers/data/boss_data.dart';
import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/models/egg.dart';
import 'package:egg_hatchers/utils/boss_battle_logic.dart';
import 'package:egg_hatchers/utils/built_in_egg_logic.dart';
import 'package:egg_hatchers/utils/luck_logic.dart';
import 'package:egg_hatchers/utils/rebirth_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release baseline keeps the opening milestones connected', () {
    final starting = GameData.startingPlayerState();
    final basicEgg = GameData.eggById('basic')!;
    final slimeBoss = BossData.bossById('slime_boss')!;

    expect(starting.coins, greaterThanOrEqualTo(basicEgg.cost));
    expect(
      BossBattleLogic.isBossUnlocked(
        slimeBoss,
        starting.copyWith(ownedAnimals: const []),
      ),
      isTrue,
    );
    expect(slimeBoss.unlockRequirementText, 'Hatch at least one animal');
    expect(BossBattleLogic.manualBossLives(slimeBoss), 1);
    expect(RebirthLogic.nextRebirthRequirement(0), 1000000);
  });

  test('100 seeded fresh players reach first rebirth without a dead zone', () {
    final economyOnly = <_JourneyResult>[];
    final activePlay = <_JourneyResult>[];

    for (var seed = 0; seed < 100; seed++) {
      economyOnly.add(_simulateJourney(seed: seed, includeFirstBossWin: false));
      activePlay.add(_simulateJourney(seed: seed, includeFirstBossWin: true));
    }

    final economyTimes = economyOnly.map((result) => result.seconds).toList()
      ..sort();
    final activeTimes = activePlay.map((result) => result.seconds).toList()
      ..sort();

    // These exact values keep the written release evidence tied to game data.
    // Intended balance changes should update this cohort and its report.
    expect(economyTimes.first, 120);
    expect(economyTimes[49], 217);
    expect(economyTimes.last, 330);
    expect(activeTimes.first, 99);
    expect(activeTimes[49], 152);
    expect(activeTimes.last, 187);

    expect(
      economyTimes.last,
      lessThanOrEqualTo(const Duration(hours: 6).inSeconds),
    );
    expect(
      activeTimes.last,
      lessThanOrEqualTo(const Duration(hours: 4).inSeconds),
    );
    expect(
      activePlay.every(
        (result) => result.firstBossAvailableAt == Duration.zero,
      ),
      isTrue,
    );
    expect(
      activePlay.every(
        (result) => result.firstBossCompletedAt == const Duration(minutes: 1),
      ),
      isTrue,
    );
  });
}

class _JourneyResult {
  const _JourneyResult({
    required this.seconds,
    required this.firstBossAvailableAt,
    required this.firstBossCompletedAt,
  });

  final int seconds;
  final Duration firstBossAvailableAt;
  final Duration? firstBossCompletedAt;
}

_JourneyResult _simulateJourney({
  required int seed,
  required bool includeFirstBossWin,
}) {
  final random = Random(seed);
  var coins = GameData.startingPlayerState().coins;
  var lifetime = 0;
  var seconds = 0;
  var hatchCount = 0;
  final incomes = <String, int>{};
  final claimedHatchMilestones = <int>{};

  void hatch(Egg egg) {
    coins -= egg.cost;
    hatchCount++;
    final animalId = BuiltInEggLogic.rollAnimal(egg, random);
    final animal = GameData.animalById(animalId)!;
    final mutation = LuckLogic.rollMutation(random, 1);
    final key = '$animalId:${mutation.id}';
    incomes[key] =
        (incomes[key] ?? 0) +
        (animal.coinsPerSecond * mutation.incomeMultiplier);

    const hatchQuestRewards = <int, int>{
      1: 100,
      3: 250,
      25: 2000,
      100: 20000,
      500: 250000,
    };
    final reward = hatchQuestRewards[hatchCount];
    if (reward != null && claimedHatchMilestones.add(hatchCount)) {
      coins += reward;
    }
  }

  final basicEgg = GameData.eggById('basic')!;
  hatch(basicEgg);
  final firstBossAvailableAt = Duration.zero;
  Duration? firstBossCompletedAt;

  while (lifetime < RebirthLogic.nextRebirthRequirement(0)) {
    seconds++;
    final income = incomes.values.fold<int>(0, (sum, value) => sum + value);
    if (income <= 0) {
      throw StateError('Fresh-player progression lost all income.');
    }
    coins += income;
    lifetime += income;

    if (includeFirstBossWin && seconds == 60) {
      firstBossCompletedAt = Duration(seconds: seconds);
      coins += BossData.bossById('slime_boss')!.coinReward;
      coins += 1000; // First Fight quest.
      coins += 5000; // First Victory quest.
    }

    final target = _highestUnlockedProgressionEgg(lifetime);
    while (coins >= target.cost) {
      hatch(target);
    }

    if (seconds > const Duration(hours: 12).inSeconds) {
      throw StateError('Fresh-player progression exceeded 12 hours.');
    }
  }

  return _JourneyResult(
    seconds: seconds,
    firstBossAvailableAt: firstBossAvailableAt,
    firstBossCompletedAt: firstBossCompletedAt,
  );
}

Egg _highestUnlockedProgressionEgg(int lifetimeCoinsEarned) {
  return GameData.eggs.lastWhere(
    (egg) =>
        egg.id != GameData.dayGullEggId &&
        egg.unlockRebirthLevel == 0 &&
        egg.unlockLifetimeCoins <= lifetimeCoinsEarned,
  );
}
