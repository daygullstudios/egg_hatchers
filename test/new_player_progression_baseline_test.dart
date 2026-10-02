import 'dart:math';

import 'package:egg_hatchers/data/boss_data.dart';
import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/models/egg.dart';
import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/models/player_state.dart';
import 'package:egg_hatchers/utils/boss_battle_logic.dart';
import 'package:egg_hatchers/utils/built_in_egg_logic.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/utils/egg_shard_logic.dart';
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

  test('fresh midgame and late-game saves work without developer boosts', () {
    final fixtures = <_SaveStageFixture>[
      _freshFixture(),
      _midgameFixture(),
      _lateGameFixture(),
    ];

    for (final fixture in fixtures) {
      final state = fixture.state;
      expect(
        state.fullDeveloperToolsUnlocked,
        isFalse,
        reason: '${fixture.name} must not rely on developer tools',
      );
      expect(_baseIncome(state), greaterThan(0), reason: fixture.name);
      expect(
        _unlockedCoinEggIds(state),
        contains(fixture.expectedHighestCoinEggId),
        reason: fixture.name,
      );
      expect(
        BossBattleLogic.isBossUnlocked(
          BossData.bossById(fixture.expectedUnlockedBossId)!,
          state,
        ),
        isTrue,
        reason: fixture.name,
      );
      expect(
        RebirthLogic.canRebirth(
          lifetimeCoinsEarned: state.lifetimeCoinsEarned,
          rebirthLevel: state.rebirthLevel,
        ),
        fixture.canRebirth,
        reason: fixture.name,
      );
    }

    final late = _lateGameFixture().state;
    expect(EggShardLogic.isRottenShellUnlocked(late), isTrue);
    expect(late.bossWins[EggShardLogic.rottenShellBossId], 1);
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

class _SaveStageFixture {
  const _SaveStageFixture({
    required this.name,
    required this.state,
    required this.expectedHighestCoinEggId,
    required this.expectedUnlockedBossId,
    required this.canRebirth,
  });

  final String name;
  final PlayerState state;
  final String expectedHighestCoinEggId;
  final String expectedUnlockedBossId;
  final bool canRebirth;
}

_SaveStageFixture _freshFixture() => _SaveStageFixture(
  name: 'fresh',
  expectedHighestCoinEggId: 'basic',
  expectedUnlockedBossId: 'slime_boss',
  canRebirth: false,
  state: GameData.startingPlayerState().copyWith(
    coins: 150,
    lifetimeCoinsEarned: 100,
    ownedAnimals: const [
      OwnedAnimal(animalId: 'chicken', quantity: 1, sourceEggId: 'basic'),
    ],
  ),
);

_SaveStageFixture _midgameFixture() => _SaveStageFixture(
  name: 'midgame',
  expectedHighestCoinEggId: 'space',
  expectedUnlockedBossId: 'egg_golem',
  canRebirth: false,
  state: GameData.startingPlayerState().copyWith(
    coins: 600000,
    lifetimeCoinsEarned: 800000,
    luckLevel: 4,
    bossWins: const {'slime_boss': 3},
    ownedAnimals: const [
      OwnedAnimal(
        animalId: 'chicken',
        quantity: 1,
        level: 8,
        sourceEggId: 'basic',
      ),
      OwnedAnimal(
        animalId: 'mouse',
        quantity: 1,
        level: 7,
        sourceEggId: 'basic',
      ),
      OwnedAnimal(
        animalId: 'rabbit',
        quantity: 1,
        level: 6,
        sourceEggId: 'basic',
      ),
      OwnedAnimal(
        animalId: 'fox',
        quantity: 1,
        level: 5,
        sourceEggId: 'forest',
      ),
      OwnedAnimal(
        animalId: 'deer',
        quantity: 1,
        level: 5,
        sourceEggId: 'forest',
      ),
      OwnedAnimal(
        animalId: 'bear',
        quantity: 1,
        level: 4,
        sourceEggId: 'forest',
      ),
      OwnedAnimal(animalId: 'cow', quantity: 1, level: 4, sourceEggId: 'farm'),
      OwnedAnimal(animalId: 'pig', quantity: 1, level: 4, sourceEggId: 'farm'),
      OwnedAnimal(
        animalId: 'sheep',
        quantity: 1,
        level: 4,
        sourceEggId: 'farm',
      ),
      OwnedAnimal(
        animalId: 'galaxy_dragon',
        quantity: 1,
        mutationId: 'golden',
        sourceEggId: 'space',
      ),
    ],
  ),
);

_SaveStageFixture _lateGameFixture() => _SaveStageFixture(
  name: 'late-game',
  expectedHighestCoinEggId: 'void',
  expectedUnlockedBossId: 'rotten_shell',
  canRebirth: true,
  state: GameData.startingPlayerState().copyWith(
    coins: 350000000,
    lifetimeCoinsEarned: 60000000,
    rebirthLevel: 5,
    luckLevel: 10,
    battleTokens: 65,
    eggShards: 9,
    shadowPhoenixFlawlessWin: true,
    bossWins: const {
      'slime_boss': 8,
      'egg_golem': 8,
      'shadow_rooster': 8,
      'slime_king': 1,
      'egg_guardian': 1,
      'shadow_phoenix': 1,
      'rotten_shell': 1,
    },
    ownedAnimals: const [
      OwnedAnimal(
        animalId: 'nebula_hydra',
        quantity: 1,
        mutationId: 'shadow',
        level: 4,
        sourceEggId: 'void',
      ),
      OwnedAnimal(
        animalId: 'eclipse_wolf',
        quantity: 2,
        mutationId: 'rainbow',
        level: 4,
        sourceEggId: 'void',
      ),
      OwnedAnimal(
        animalId: 'shadow_phoenix',
        quantity: 1,
        level: 2,
        isProtected: true,
        isEliteReward: true,
      ),
      OwnedAnimal(
        animalId: 'crossword_beast',
        quantity: 1,
        level: 1,
        sourceEggId: 'daygull',
      ),
    ],
  ),
);

List<String> _unlockedCoinEggIds(PlayerState state) => GameData.eggs
    .where((egg) => egg.id != GameData.dayGullEggId)
    .where(
      (egg) =>
          egg.unlockLifetimeCoins <= state.lifetimeCoinsEarned &&
          state.rebirthLevel >=
              EggShardLogic.effectiveRebirthRequirement(
                egg.unlockRebirthLevel,
                state.eggRebirthReductionLevel,
              ),
    )
    .map((egg) => egg.id)
    .toList(growable: false);

int _baseIncome(PlayerState state) {
  var total = 0;
  for (final owned in state.ownedAnimals) {
    final animal = GameData.animalById(owned.animalId);
    if (animal != null) total += GameService.incomeFor(animal, owned);
  }
  return total;
}
