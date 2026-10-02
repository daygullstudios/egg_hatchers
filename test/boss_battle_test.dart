import 'dart:math';

import 'package:egg_hatchers/data/boss_data.dart';
import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/models/player_state.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/utils/battle_power_logic.dart';
import 'package:egg_hatchers/utils/boss_battle_logic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('battle power uses cps level and mutation multiplier', () {
    const normalChicken = OwnedAnimal(
      animalId: 'chicken',
      quantity: 5,
      level: 3,
      mutationId: 'none',
    );
    const goldenChicken = OwnedAnimal(
      animalId: 'chicken',
      quantity: 1,
      level: 3,
      mutationId: 'golden',
    );

    expect(BattlePowerLogic.battlePowerForOwnedAnimal(normalChicken), 3);
    expect(BattlePowerLogic.battlePowerForOwnedAnimal(goldenChicken), 6);
  });

  test('battle power minimum is 1', () {
    const owned = OwnedAnimal(animalId: 'chicken', quantity: 1, level: 1);
    expect(BattlePowerLogic.battlePowerForOwnedAnimal(owned), greaterThan(0));
  });

  test('boss unlock rules', () {
    final slime = BossData.bossById('slime_boss')!;
    final golem = BossData.bossById('egg_golem')!;
    final rooster = BossData.bossById('shadow_rooster')!;

    final empty = PlayerState.initial();
    expect(BossBattleLogic.isBossUnlocked(slime, empty), isTrue);
    expect(BossBattleLogic.isBossUnlocked(golem, empty), isFalse);
    expect(BossBattleLogic.isBossUnlocked(rooster, empty), isFalse);

    final tenAnimals = empty.copyWith(
      ownedAnimals: [
        for (var i = 0; i < 10; i++)
          OwnedAnimal(animalId: GameData.animals[i].id, quantity: 1),
      ],
    );
    expect(BossBattleLogic.isBossUnlocked(golem, tenAnimals), isTrue);
    expect(BossBattleLogic.isBossUnlocked(rooster, tenAnimals), isFalse);

    final rebirthed = empty.copyWith(rebirthLevel: 1);
    expect(BossBattleLogic.isBossUnlocked(rooster, rebirthed), isTrue);
  });

  test('strong fighter usually beats slime boss', () {
    final boss = BossData.bossById('slime_boss')!;
    const fighter = OwnedAnimal(
      animalId: 'galaxy_dragon',
      quantity: 1,
      level: 10,
      mutationId: 'shadow',
    );
    var wins = 0;
    for (var seed = 0; seed < 20; seed++) {
      final result = BossBattleLogic.simulate(
        boss: boss,
        fighter: fighter,
        fighterDisplayName: 'Shadow Galaxy Dragon',
        random: Random(seed),
      );
      if (result.won) wins++;
    }
    expect(wins, greaterThan(10));
  });

  test('simulation includes round snapshots with hp tracking', () {
    final boss = BossData.bossById('slime_boss')!;
    const fighter = OwnedAnimal(
      animalId: 'chicken',
      quantity: 1,
      level: 5,
      mutationId: 'none',
    );
    final result = BossBattleLogic.simulate(
      boss: boss,
      fighter: fighter,
      fighterDisplayName: 'Chicken',
      random: Random(3),
    );

    expect(result.initialPlayerHp, greaterThan(0));
    expect(result.initialBossHp, boss.maxHp);
    expect(result.roundSnapshots, isNotEmpty);
    expect(result.roundSnapshots.first.isPlayerAttack, isTrue);
    expect(result.roundSnapshots.first.bossHpAfter, lessThan(boss.maxHp));
  });

  test('simulate does not grant rewards until applied', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService(random: Random(1));
    await game.initialize();

    game.devCollectAllAnimals();
    final beforeLifetime = game.lifetimeCoinsEarned;
    final beforeCoins = game.coins;
    final beforeTokens = game.battleTokens;

    final result = game.simulateBossBattle(
      bossId: 'slime_boss',
      animalId: 'nebula_hydra',
      mutationId: 'none',
      isProtected: false,
    );
    expect(result, isNotNull);
    expect(result!.won, isTrue);
    expect(game.coins, beforeCoins);
    expect(game.battleTokens, beforeTokens);

    expect(game.applyBossBattleRewards('slime_boss', result), isNull);
    expect(game.coins, beforeCoins + 500);
    expect(game.battleTokens, beforeTokens + 1);
    expect(game.lifetimeCoinsEarned, beforeLifetime);
    expect(game.bossWinCount('slime_boss'), 1);

    game.dispose();
  });

  test('boss win grants coins and tokens without lifetime earnings', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService(random: Random(1));
    await game.initialize();

    game.devCollectAllAnimals();
    final beforeLifetime = game.lifetimeCoinsEarned;
    final beforeCoins = game.coins;
    final beforeTokens = game.battleTokens;

    final result = game.fightBoss(
      bossId: 'slime_boss',
      animalId: 'nebula_hydra',
      mutationId: 'none',
      isProtected: false,
    );

    expect(result, isNotNull);
    expect(result!.won, isTrue);
    expect(game.coins, beforeCoins + 500);
    expect(game.battleTokens, beforeTokens + 1);
    expect(game.lifetimeCoinsEarned, beforeLifetime);
    expect(game.bossWinCount('slime_boss'), 1);

    game.dispose();
  });

  test('old saves default battle tokens and boss wins', () {
    final restored = PlayerState.fromJson({
      'coins': 100,
      'ownedAnimals': [],
      'lastSavedTime': DateTime.now().toIso8601String(),
      'lifetimeCoinsEarned': 100,
    });

    expect(restored.battleTokens, 0);
    expect(restored.bossWins, isEmpty);
  });

  test('boss wins serialize and deserialize', () {
    final state = PlayerState.initial().copyWith(
      battleTokens: 5,
      bossWins: const {'slime_boss': 2, 'egg_golem': 1},
    );
    final restored = PlayerState.fromJson(state.toJson());
    expect(restored.battleTokens, 5);
    expect(restored.bossWins['slime_boss'], 2);
    expect(restored.bossWins['egg_golem'], 1);
  });
}
