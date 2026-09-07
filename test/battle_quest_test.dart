import 'dart:math';

import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/data/quest_data.dart';
import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/models/quest.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/utils/quest_logic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Quest _battleQuest(String id) =>
    QuestData.all.firstWhere((quest) => quest.id == id);

void main() {
  test('battle quests are in the Battle category', () {
    final battleQuests = QuestData.all.where(
      (q) => q.category == QuestCategory.battle,
    );
    expect(battleQuests.length, 10);
    expect(QuestData.categoryOrder, contains(QuestCategory.battle));
  });

  test('battle quest notification uses Battle label', () {
    final quest = _battleQuest('battle_first_fight');
    expect(
      QuestLogic.completionNotificationMessage([quest]),
      '⚔️ Battle Quest Complete! Claim your reward.',
    );
  });

  test('starting a boss battle progresses First Fight', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();
    game.devSetOwnedAnimalsForTesting([
      const OwnedAnimal(animalId: 'chicken', quantity: 1),
    ]);

    game.recordBossBattleStarted();

    expect(game.questProgress.totalBossBattlesStarted, 1);
    expect(
      QuestLogic.isComplete(_battleQuest('battle_first_fight'), game.state),
      isTrue,
    );

    game.dispose();
  });

  test('focused battles hold quest notifications until returning', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();
    game.devSetOwnedAnimalsForTesting([
      const OwnedAnimal(animalId: 'chicken', quantity: 1),
    ]);
    final battleRoute = Object();

    game.holdQuestNotifications(battleRoute);
    game.recordBossBattleStarted();

    expect(game.isQuestNotificationDeferred, isTrue);
    expect(game.consumePendingQuestNotification(), isNull);

    game.releaseQuestNotifications(battleRoute);

    expect(
      game.consumePendingQuestNotification(),
      '⚔️ Battle Quest Complete! Claim your reward.',
    );
    game.dispose();
  });

  test('winning a boss battle progresses battle win quests', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService(random: Random(1));
    await game.initialize();
    game.devCollectAllAnimals();

    game.recordBossBattleStarted();
    final result = game.simulateBossBattle(
      bossId: 'slime_boss',
      animalId: 'nebula_hydra',
      mutationId: 'none',
      isProtected: false,
    );
    expect(result, isNotNull);
    game.applyBossBattleRewards('slime_boss', result!);

    expect(game.questProgress.totalBossBattlesWon, 1);
    expect(game.questProgress.slimeBossWins, 1);
    expect(game.questProgress.totalBattleTokensEarned, 1);
    expect(
      QuestLogic.isComplete(_battleQuest('battle_first_victory'), game.state),
      isTrue,
    );
    expect(
      QuestLogic.isComplete(_battleQuest('battle_slime_smasher'), game.state),
      isFalse,
    );

    game.dispose();
  });

  test('losing a boss battle increments loss stat only', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService(random: Random(999));
    await game.initialize();
    game.devSetOwnedAnimalsForTesting([
      const OwnedAnimal(animalId: 'chicken', quantity: 1),
    ]);

    game.recordBossBattleStarted();
    final result = game.simulateBossBattle(
      bossId: 'slime_boss',
      animalId: 'chicken',
      mutationId: 'none',
      isProtected: false,
    );
    expect(result, isNotNull);
    game.applyBossBattleRewards('slime_boss', result!);
    if (result.won) {
      expect(game.questProgress.totalBossBattlesLost, 0);
    } else {
      expect(game.questProgress.totalBossBattlesLost, 1);
      expect(game.questProgress.totalBossBattlesWon, 0);
    }

    game.dispose();
  });

  test('boss egg hatch increments boss egg quest stat', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();
    game.devSetOwnedAnimalsForTesting([
      const OwnedAnimal(animalId: 'chicken', quantity: 1),
    ]);
    game.devAddBattleTokens(10);

    final bossEgg = GameData.battleEggs.first;
    game.buyEgg(bossEgg);
    game.hatchEgg(bossEgg);

    expect(game.questProgress.totalBossEggsHatched, 1);
    expect(
      QuestLogic.isComplete(
        _battleQuest('battle_boss_egg_beginner'),
        game.state,
      ),
      isTrue,
    );

    game.dispose();
  });

  test('unlock boss mutation completes Mutation Commander quest', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();
    game.devAddBattleTokens(40);

    expect(game.unlockBossMutation(), isTrue);
    expect(
      QuestLogic.isComplete(
        _battleQuest('battle_mutation_commander'),
        game.state,
      ),
      isTrue,
    );

    game.dispose();
  });

  test('apply boss mutation completes Boss Alchemist quest', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();
    game.devAddBattleTokens(100);
    game.devSetOwnedAnimalsForTesting([
      const OwnedAnimal(animalId: 'chicken', quantity: 1),
    ]);

    expect(
      game.applyBossMutation(
        const OwnedAnimal(animalId: 'chicken', quantity: 1),
      ),
      isTrue,
    );
    expect(game.questProgress.totalBossMutationsApplied, 1);
    expect(
      QuestLogic.isComplete(_battleQuest('battle_boss_alchemist'), game.state),
      isTrue,
    );

    game.dispose();
  });

  test('battle token quest rewards add tokens not lifetime coins', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();
    game.devAddBattleTokens(10);
    game.devSetOwnedAnimalsForTesting([
      const OwnedAnimal(animalId: 'chicken', quantity: 1),
    ]);

    final bossEgg = GameData.battleEggs.first;
    game.buyEgg(bossEgg);
    game.hatchEgg(bossEgg);

    final lifetimeBefore = game.lifetimeCoinsEarned;
    final tokensBefore = game.battleTokens;
    final reward = game.claimQuest('battle_boss_egg_beginner');

    expect(reward?.battleTokens, 5);
    expect(reward?.coins, 0);
    expect(game.battleTokens, tokensBefore + 5);
    expect(game.lifetimeCoinsEarned, lifetimeBefore);

    game.dispose();
  });

  test('rebirth resets battle quest stats but keeps battle tokens', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();
    game.setLifetimeCoinsEarned(1000000);
    game.recordBossBattleStarted();
    game.devAddBattleTokens(15);

    game.performRebirth();

    expect(game.questProgress.totalBossBattlesStarted, 0);
    expect(game.battleTokens, 15);
    expect(game.bossMutationUnlocked, isFalse);

    game.dispose();
  });
}
