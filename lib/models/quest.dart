/// Quest category groupings shown on the Quests screen.
enum QuestCategory {
  beginner,
  regular,
  advanced,
  lateGame,
  battle,
  customEgg,
  customSprite,
}

/// Player-facing quest state.
enum QuestStatus { inProgress, readyToClaim, claimed }

/// Metric used to evaluate quest progress.
enum QuestMetric {
  totalEggsHatched,
  totalSingleHatches,
  totalTripleHatches,
  totalMutationsHatched,
  totalGoldenHatched,
  totalRainbowHatched,
  totalShadowHatched,
  totalAnimalUpgrades,
  totalLuckUpgrades,
  totalCustomEggsCreated,
  totalCustomEggHatches,
  totalCustomTripleHatches,
  totalSpritesRated,
  totalSpriteRatingRewardsClaimed,
  bestSpriteRatingScore,
  totalPerfectSpriteRatings,
  totalReferenceOverlaysUnlocked,
  totalBossBattlesStarted,
  totalBossBattlesWon,
  totalBossBattlesLost,
  slimeBossWins,
  eggGolemWins,
  shadowRoosterWins,
  totalBattleTokensEarned,
  totalBossEggsHatched,
  totalBossMutationsApplied,
  totalFusionAttempts,
  totalSuccessfulFusions,
  totalLuckyFusions,
  totalFailedFusions,
  bossMutationUnlocked,
  luckLevel,
  lifetimeCoinsEarned,
  rebirthLevel,
  collectedBaseAnimals,
}

/// A quest definition with stable id and reward.
class Quest {
  const Quest({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.rewardCoins,
    required this.metric,
    required this.target,
    this.rewardBattleTokens = 0,
    this.requiresCustomEggCreated = false,
    this.rewardDisplayLabel,
    this.showsSecretHintOnClaim = false,
  });

  final String id;
  final QuestCategory category;
  final String title;
  final String description;
  final int rewardCoins;
  final int rewardBattleTokens;
  final QuestMetric metric;
  final int target;

  /// When true, the quest only completes after at least one custom egg exists.
  final bool requiresCustomEggCreated;

  /// Optional reward text instead of a coin amount (e.g. "???").
  final String? rewardDisplayLabel;

  /// When true, claiming unlocks the Collector's Vault and grants no coins.
  final bool showsSecretHintOnClaim;

  bool get grantsCoinsOnClaim => !showsSecretHintOnClaim && rewardCoins > 0;

  bool get grantsBattleTokensOnClaim => rewardBattleTokens > 0;

  bool get hasClaimableReward =>
      grantsCoinsOnClaim || grantsBattleTokensOnClaim;

  String get categoryLabel {
    switch (category) {
      case QuestCategory.beginner:
        return 'Beginner Quests';
      case QuestCategory.regular:
        return 'Regular Quests';
      case QuestCategory.advanced:
        return 'Advanced Quests';
      case QuestCategory.lateGame:
        return 'Late Game Quests';
      case QuestCategory.battle:
        return 'Battle';
      case QuestCategory.customEgg:
        return 'Custom Egg Quests';
      case QuestCategory.customSprite:
        return 'Custom Sprite';
    }
  }

  String get categoryEmoji {
    switch (category) {
      case QuestCategory.beginner:
        return '🌱';
      case QuestCategory.regular:
        return '⭐';
      case QuestCategory.advanced:
        return '💎';
      case QuestCategory.lateGame:
        return '👑';
      case QuestCategory.battle:
        return '⚔️';
      case QuestCategory.customEgg:
        return '🎨';
      case QuestCategory.customSprite:
        return '🎨';
    }
  }

  /// Short label for completion notifications.
  String get notificationCategoryLabel {
    switch (category) {
      case QuestCategory.beginner:
        return 'Beginner';
      case QuestCategory.regular:
        return 'Regular';
      case QuestCategory.advanced:
        return 'Advanced';
      case QuestCategory.lateGame:
        return 'Late Game';
      case QuestCategory.battle:
        return 'Battle';
      case QuestCategory.customEgg:
        return 'Custom Egg';
      case QuestCategory.customSprite:
        return 'Custom Sprite';
    }
  }

  /// Emoji used in completion notifications.
  String get notificationEmoji {
    switch (category) {
      case QuestCategory.beginner:
        return '🌱';
      case QuestCategory.regular:
        return '⭐';
      case QuestCategory.advanced:
        return '💎';
      case QuestCategory.lateGame:
        return '👑';
      case QuestCategory.battle:
        return '⚔️';
      case QuestCategory.customEgg:
        return '🥚';
      case QuestCategory.customSprite:
        return '🎨';
    }
  }
}
