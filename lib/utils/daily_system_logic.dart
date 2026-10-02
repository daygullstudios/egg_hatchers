import 'dart:math';

import '../models/daily_quest_progress.dart';

/// Daily reward track and daily quest definitions.
class DailySystemLogic {
  DailySystemLogic._();

  static const dailyQuestCount = 3;

  static const hatchEggsType = 'hatchEggs';
  static const upgradeAnimalsType = 'upgradeAnimals';
  static const defeatBossType = 'defeatBoss';
  static const startAutoBattleType = 'startAutoBattle';
  static const startManualBattleType = 'startManualBattle';
  static const winManualBattleType = 'winManualBattle';
  static const claimQuestRewardType = 'claimQuestReward';
  static const buyEggsType = 'buyEggs';
  static const buyBattleUpgradeType = 'buyBattleUpgrade';
  static const attemptFusionType = 'attemptFusion';
  static const successfulFusionType = 'successfulFusion';
  static const luckyFusionType = 'luckyFusion';
  static const failedFusionType = 'failedFusion';

  static const _questPool = <_DailyQuestDefinition>[
    _DailyQuestDefinition(
      id: 'hatch_3',
      group: 'hatch',
      type: hatchEggsType,
      title: 'Hatch 3 eggs',
      target: 3,
      rewardCoins: 1000,
    ),
    _DailyQuestDefinition(
      id: 'hatch_8',
      group: 'hatch',
      type: hatchEggsType,
      title: 'Hatch 8 eggs',
      target: 8,
      rewardCoins: 2500,
    ),
    _DailyQuestDefinition(
      id: 'upgrade_3',
      group: 'upgrade',
      type: upgradeAnimalsType,
      title: 'Upgrade animals 3 times',
      target: 3,
      rewardCoins: 1500,
    ),
    _DailyQuestDefinition(
      id: 'upgrade_6',
      group: 'upgrade',
      type: upgradeAnimalsType,
      title: 'Upgrade animals 6 times',
      target: 6,
      rewardCoins: 3500,
    ),
    _DailyQuestDefinition(
      id: 'defeat_boss_1',
      group: 'boss',
      type: defeatBossType,
      title: 'Defeat 1 boss',
      target: 1,
      rewardBattleTokens: 3,
    ),
    _DailyQuestDefinition(
      id: 'defeat_boss_3',
      group: 'boss',
      type: defeatBossType,
      title: 'Defeat 3 bosses',
      target: 3,
      rewardBattleTokens: 8,
    ),
    _DailyQuestDefinition(
      id: 'start_auto_1',
      group: 'battleStartAuto',
      type: startAutoBattleType,
      title: 'Start 1 Auto Battle',
      target: 1,
      rewardBattleTokens: 2,
    ),
    _DailyQuestDefinition(
      id: 'start_manual_1',
      group: 'battleStartManual',
      type: startManualBattleType,
      title: 'Start 1 Manual Battle',
      target: 1,
      rewardCoins: 1000,
    ),
    _DailyQuestDefinition(
      id: 'win_manual_1',
      group: 'battleWinManual',
      type: winManualBattleType,
      title: 'Win 1 Manual Battle',
      target: 1,
      rewardBattleTokens: 5,
    ),
    _DailyQuestDefinition(
      id: 'claim_regular_1',
      group: 'questClaim',
      type: claimQuestRewardType,
      title: 'Claim 1 quest reward',
      target: 1,
      rewardBattleTokens: 2,
    ),
    _DailyQuestDefinition(
      id: 'buy_eggs_2',
      group: 'eggsBuy',
      type: buyEggsType,
      title: 'Buy 2 eggs',
      target: 2,
      rewardCoins: 1500,
    ),
    _DailyQuestDefinition(
      id: 'battle_upgrade_1',
      group: 'battleUpgrade',
      type: buyBattleUpgradeType,
      title: 'Buy 1 battle upgrade',
      target: 1,
      rewardBattleTokens: 5,
    ),
    _DailyQuestDefinition(
      id: 'try_fusion_1',
      group: 'fusionAttempt',
      type: attemptFusionType,
      title: 'Try Fusion',
      target: 1,
      rewardCoins: 1500,
    ),
    _DailyQuestDefinition(
      id: 'complete_fusion_1',
      group: 'fusionSuccess',
      type: successfulFusionType,
      title: 'Complete a Fusion',
      target: 1,
      rewardBattleTokens: 5,
    ),
  ];

  /// Local calendar date key: yyyy-MM-dd.
  static String todayKey([DateTime? now]) {
    final date = now ?? DateTime.now();
    return _formatDateKey(date);
  }

  static String yesterdayKey([DateTime? now]) {
    final date = (now ?? DateTime.now()).subtract(const Duration(days: 1));
    return _formatDateKey(date);
  }

  static bool isYesterday(String? dateKey, [DateTime? now]) {
    if (dateKey == null || dateKey.isEmpty) return false;
    return dateKey == yesterdayKey(now);
  }

  static String _formatDateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Reward slot (1–7) for the given streak after claiming today.
  static int rewardDaySlot(int streak) {
    if (streak <= 0) return 1;
    return ((streak - 1) % 7) + 1;
  }

  static DailyRewardOffer rewardForStreak(int streak) {
    return rewardForDaySlot(rewardDaySlot(streak));
  }

  static DailyRewardOffer rewardForDaySlot(int daySlot) {
    switch (daySlot) {
      case 1:
        return const DailyRewardOffer(
          daySlot: 1,
          coins: 500,
          battleTokens: 0,
          label: '500 coins',
        );
      case 2:
        return const DailyRewardOffer(
          daySlot: 2,
          coins: 1000,
          battleTokens: 0,
          label: '1,000 coins',
        );
      case 3:
        return const DailyRewardOffer(
          daySlot: 3,
          coins: 0,
          battleTokens: 5,
          label: '5 Battle Tokens',
        );
      case 4:
        return const DailyRewardOffer(
          daySlot: 4,
          coins: 2500,
          battleTokens: 0,
          label: '2,500 coins',
        );
      case 5:
        return const DailyRewardOffer(
          daySlot: 5,
          coins: 0,
          battleTokens: 5,
          label: '5 Battle Tokens',
        );
      case 6:
        return const DailyRewardOffer(
          daySlot: 6,
          coins: 5000,
          battleTokens: 0,
          label: '5,000 coins',
        );
      case 7:
        return const DailyRewardOffer(
          daySlot: 7,
          coins: 10000,
          battleTokens: 15,
          label: '15 Battle Tokens + 10,000 coins',
        );
      default:
        return rewardForDaySlot(1);
    }
  }

  /// Picks [dailyQuestCount] quests for [dateKey], preferring unique groups.
  static List<DailyQuestProgress> generateDailyQuests(
    String dateKey, {
    int rerollSalt = 0,
  }) {
    final random = Random(_seedFromDateKey(dateKey) ^ rerollSalt);
    final shuffled = List<_DailyQuestDefinition>.from(_questPool)
      ..shuffle(random);

    final selected = <_DailyQuestDefinition>[];
    final usedGroups = <String>{};

    for (final definition in shuffled) {
      if (selected.length >= dailyQuestCount) break;
      if (usedGroups.contains(definition.group)) continue;
      selected.add(definition);
      usedGroups.add(definition.group);
    }

    if (selected.length < dailyQuestCount) {
      for (final definition in shuffled) {
        if (selected.length >= dailyQuestCount) break;
        if (selected.any((quest) => quest.id == definition.id)) continue;
        selected.add(definition);
      }
    }

    return selected.map((definition) => definition.toProgress()).toList();
  }

  static int _seedFromDateKey(String dateKey) {
    var hash = 0;
    for (final unit in dateKey.codeUnits) {
      hash = 0x1fffffff & (hash + unit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= hash >> 6;
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= hash >> 11;
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return hash;
  }

  static String rewardLabel({
    required int rewardCoins,
    required int rewardBattleTokens,
  }) {
    if (rewardCoins > 0 && rewardBattleTokens > 0) {
      return '$rewardCoins coins + $rewardBattleTokens Battle Tokens';
    }
    if (rewardBattleTokens > 0) {
      return '$rewardBattleTokens Battle Tokens';
    }
    return '$rewardCoins coins';
  }
}

class DailyRewardOffer {
  const DailyRewardOffer({
    required this.daySlot,
    required this.coins,
    required this.battleTokens,
    required this.label,
  });

  final int daySlot;
  final int coins;
  final int battleTokens;
  final String label;
}

class _DailyQuestDefinition {
  const _DailyQuestDefinition({
    required this.id,
    required this.group,
    required this.type,
    required this.title,
    required this.target,
    this.rewardCoins = 0,
    this.rewardBattleTokens = 0,
  });

  final String id;
  final String group;
  final String type;
  final String title;
  final int target;
  final int rewardCoins;
  final int rewardBattleTokens;

  DailyQuestProgress toProgress() {
    return DailyQuestProgress(
      id: id,
      group: group,
      type: type,
      title: title,
      target: target,
      rewardCoins: rewardCoins,
      rewardBattleTokens: rewardBattleTokens,
    );
  }
}
