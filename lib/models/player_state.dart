import '../utils/egg_shard_logic.dart';
import '../utils/egg_mastery_logic.dart';
import 'active_auto_battle.dart';
import 'daily_quest_progress.dart';
import 'egg_mastery_progress.dart';
import 'owned_animal.dart';
import 'quest_progress.dart';

/// All progress the player has made in the game.
class PlayerState {
  const PlayerState({
    required this.coins,
    required this.ownedAnimals,
    required this.lastSavedTime,
    required this.lifetimeCoinsEarned,
    this.luckLevel = 1,
    this.rebirthLevel = 0,
    this.questProgress = const QuestProgress(),
    this.secretSpaceEggClaimed = false,
    this.fullDeveloperToolsUnlocked = false,
    this.battleTokens = 0,
    this.bossWins = const {},
    this.hardPhaseWins = const {},
    this.nightmareWins = const {},
    this.bossMutationUnlocked = false,
    this.activeAutoBattle,
    this.tutorialCompleted = false,
    this.tutorialSkipped = false,
    this.tutorialVersionCompleted = 0,
    this.battleHomingLevel = 0,
    this.battleShotSpeedLevel = 0,
    this.battleExtraLifeLevel = 0,
    this.eggShards = 0,
    this.shadowPhoenixFlawlessWin = false,
    this.battleLimitBreakLevel = 0,
    this.extraLifeLimitBreakLevel = 0,
    this.eggRebirthReductionLevel = 0,
    this.customSpriteCanvasTier = 0,
    this.lastDailyRewardClaimDate,
    this.dailyRewardStreak = 0,
    this.bestDailyRewardStreak = 0,
    this.dailyQuestDate,
    this.dailyQuests = const [],
    this.lastDailyRewardPopupDismissDate,
    this.eggMastery = const {},
    this.arenaRating = 1000,
    this.arenaWins = 0,
    this.arenaLosses = 0,
    this.arenaWinStreak = 0,
    this.arenaBestStreak = 0,
  });

  final int coins;
  final List<OwnedAnimal> ownedAnimals;
  final DateTime lastSavedTime;
  final int lifetimeCoinsEarned;
  final int luckLevel;
  final int rebirthLevel;
  final QuestProgress questProgress;
  final bool secretSpaceEggClaimed;
  final bool fullDeveloperToolsUnlocked;
  final int battleTokens;
  final Map<String, int> bossWins;
  final Map<String, int> hardPhaseWins;
  final Map<String, int> nightmareWins;
  final bool bossMutationUnlocked;
  final ActiveAutoBattle? activeAutoBattle;
  final bool tutorialCompleted;
  final bool tutorialSkipped;
  final int tutorialVersionCompleted;
  final int battleHomingLevel;
  final int battleShotSpeedLevel;
  final int battleExtraLifeLevel;
  final int eggShards;
  final bool shadowPhoenixFlawlessWin;
  final int battleLimitBreakLevel;
  final int extraLifeLimitBreakLevel;
  final int eggRebirthReductionLevel;
  final int customSpriteCanvasTier;
  final String? lastDailyRewardClaimDate;
  final int dailyRewardStreak;
  final int bestDailyRewardStreak;
  final String? dailyQuestDate;
  final List<DailyQuestProgress> dailyQuests;
  final String? lastDailyRewardPopupDismissDate;
  final Map<String, EggMasteryProgress> eggMastery;
  final int arenaRating;
  final int arenaWins;
  final int arenaLosses;
  final int arenaWinStreak;
  final int arenaBestStreak;

  static PlayerState initial() {
    return PlayerState(
      coins: 250,
      ownedAnimals: const [],
      lastSavedTime: DateTime.now(),
      lifetimeCoinsEarned: 0,
      luckLevel: 1,
      rebirthLevel: 0,
      questProgress: QuestProgress.initial(),
    );
  }

  PlayerState copyWith({
    int? coins,
    List<OwnedAnimal>? ownedAnimals,
    DateTime? lastSavedTime,
    int? lifetimeCoinsEarned,
    int? luckLevel,
    int? rebirthLevel,
    QuestProgress? questProgress,
    bool? secretSpaceEggClaimed,
    bool? fullDeveloperToolsUnlocked,
    int? battleTokens,
    Map<String, int>? bossWins,
    Map<String, int>? hardPhaseWins,
    Map<String, int>? nightmareWins,
    bool? bossMutationUnlocked,
    ActiveAutoBattle? activeAutoBattle,
    bool clearActiveAutoBattle = false,
    bool? tutorialCompleted,
    bool? tutorialSkipped,
    int? tutorialVersionCompleted,
    int? battleHomingLevel,
    int? battleShotSpeedLevel,
    int? battleExtraLifeLevel,
    int? eggShards,
    bool? shadowPhoenixFlawlessWin,
    int? battleLimitBreakLevel,
    int? extraLifeLimitBreakLevel,
    int? eggRebirthReductionLevel,
    int? customSpriteCanvasTier,
    String? lastDailyRewardClaimDate,
    bool clearLastDailyRewardClaimDate = false,
    int? dailyRewardStreak,
    int? bestDailyRewardStreak,
    String? dailyQuestDate,
    bool clearDailyQuestDate = false,
    List<DailyQuestProgress>? dailyQuests,
    String? lastDailyRewardPopupDismissDate,
    bool clearLastDailyRewardPopupDismissDate = false,
    Map<String, EggMasteryProgress>? eggMastery,
    int? arenaRating,
    int? arenaWins,
    int? arenaLosses,
    int? arenaWinStreak,
    int? arenaBestStreak,
  }) {
    return PlayerState(
      coins: coins ?? this.coins,
      ownedAnimals: ownedAnimals ?? this.ownedAnimals,
      lastSavedTime: lastSavedTime ?? this.lastSavedTime,
      lifetimeCoinsEarned: lifetimeCoinsEarned ?? this.lifetimeCoinsEarned,
      luckLevel: luckLevel ?? this.luckLevel,
      rebirthLevel: rebirthLevel ?? this.rebirthLevel,
      questProgress: questProgress ?? this.questProgress,
      secretSpaceEggClaimed:
          secretSpaceEggClaimed ?? this.secretSpaceEggClaimed,
      fullDeveloperToolsUnlocked:
          fullDeveloperToolsUnlocked ?? this.fullDeveloperToolsUnlocked,
      battleTokens: battleTokens ?? this.battleTokens,
      bossWins: bossWins ?? this.bossWins,
      hardPhaseWins: hardPhaseWins ?? this.hardPhaseWins,
      nightmareWins: nightmareWins ?? this.nightmareWins,
      bossMutationUnlocked: bossMutationUnlocked ?? this.bossMutationUnlocked,
      activeAutoBattle: clearActiveAutoBattle
          ? null
          : activeAutoBattle ?? this.activeAutoBattle,
      tutorialCompleted: tutorialCompleted ?? this.tutorialCompleted,
      tutorialSkipped: tutorialSkipped ?? this.tutorialSkipped,
      tutorialVersionCompleted:
          tutorialVersionCompleted ?? this.tutorialVersionCompleted,
      battleHomingLevel: battleHomingLevel ?? this.battleHomingLevel,
      battleShotSpeedLevel: battleShotSpeedLevel ?? this.battleShotSpeedLevel,
      battleExtraLifeLevel: battleExtraLifeLevel ?? this.battleExtraLifeLevel,
      eggShards: eggShards ?? this.eggShards,
      shadowPhoenixFlawlessWin:
          shadowPhoenixFlawlessWin ?? this.shadowPhoenixFlawlessWin,
      battleLimitBreakLevel:
          battleLimitBreakLevel ?? this.battleLimitBreakLevel,
      extraLifeLimitBreakLevel:
          extraLifeLimitBreakLevel ?? this.extraLifeLimitBreakLevel,
      eggRebirthReductionLevel:
          eggRebirthReductionLevel ?? this.eggRebirthReductionLevel,
      customSpriteCanvasTier:
          customSpriteCanvasTier ?? this.customSpriteCanvasTier,
      lastDailyRewardClaimDate: clearLastDailyRewardClaimDate
          ? null
          : lastDailyRewardClaimDate ?? this.lastDailyRewardClaimDate,
      dailyRewardStreak: dailyRewardStreak ?? this.dailyRewardStreak,
      bestDailyRewardStreak:
          bestDailyRewardStreak ?? this.bestDailyRewardStreak,
      dailyQuestDate: clearDailyQuestDate
          ? null
          : dailyQuestDate ?? this.dailyQuestDate,
      dailyQuests: dailyQuests ?? this.dailyQuests,
      lastDailyRewardPopupDismissDate: clearLastDailyRewardPopupDismissDate
          ? null
          : lastDailyRewardPopupDismissDate ??
                this.lastDailyRewardPopupDismissDate,
      eggMastery: eggMastery ?? this.eggMastery,
      arenaRating: arenaRating ?? this.arenaRating,
      arenaWins: arenaWins ?? this.arenaWins,
      arenaLosses: arenaLosses ?? this.arenaLosses,
      arenaWinStreak: arenaWinStreak ?? this.arenaWinStreak,
      arenaBestStreak: arenaBestStreak ?? this.arenaBestStreak,
    );
  }

  Map<String, dynamic> toJson() => {
    'coins': coins,
    'ownedAnimals': ownedAnimals.map((a) => a.toJson()).toList(),
    'lastSavedTime': lastSavedTime.toIso8601String(),
    'lifetimeCoinsEarned': lifetimeCoinsEarned,
    'luckLevel': luckLevel,
    'rebirthLevel': rebirthLevel,
    'questProgress': questProgress.toJson(),
    'secretSpaceEggClaimed': secretSpaceEggClaimed,
    'fullDeveloperToolsUnlocked': fullDeveloperToolsUnlocked,
    'battleTokens': battleTokens,
    'bossWins': bossWins,
    'hardPhaseWins': hardPhaseWins,
    'nightmareWins': nightmareWins,
    'bossMutationUnlocked': bossMutationUnlocked,
    if (activeAutoBattle != null)
      'activeAutoBattle': activeAutoBattle!.toJson(),
    'tutorialCompleted': tutorialCompleted,
    'tutorialSkipped': tutorialSkipped,
    'tutorialVersionCompleted': tutorialVersionCompleted,
    'battleHomingLevel': battleHomingLevel,
    'battleShotSpeedLevel': battleShotSpeedLevel,
    'battleExtraLifeLevel': battleExtraLifeLevel,
    'eggShards': eggShards,
    'shadowPhoenixFlawlessWin': shadowPhoenixFlawlessWin,
    'battleLimitBreakLevel': battleLimitBreakLevel,
    'extraLifeLimitBreakLevel': extraLifeLimitBreakLevel,
    'eggRebirthReductionLevel': eggRebirthReductionLevel,
    'customSpriteCanvasTier': customSpriteCanvasTier,
    if (lastDailyRewardClaimDate != null)
      'lastDailyRewardClaimDate': lastDailyRewardClaimDate,
    'dailyRewardStreak': dailyRewardStreak,
    'bestDailyRewardStreak': bestDailyRewardStreak,
    if (dailyQuestDate != null) 'dailyQuestDate': dailyQuestDate,
    'dailyQuests': dailyQuests.map((quest) => quest.toJson()).toList(),
    if (lastDailyRewardPopupDismissDate != null)
      'lastDailyRewardPopupDismissDate': lastDailyRewardPopupDismissDate,
    'eggMastery': {
      for (final entry in eggMastery.entries) entry.key: entry.value.toJson(),
    },
    'arenaRating': arenaRating,
    'arenaWins': arenaWins,
    'arenaLosses': arenaLosses,
    'arenaWinStreak': arenaWinStreak,
    'arenaBestStreak': arenaBestStreak,
  };

  factory PlayerState.fromJson(Map<String, dynamic> json) {
    final coins = json['coins'] as int;
    final battleLimitBreak = EggShardLogic.clampBattleLimitBreak(
      json['battleLimitBreakLevel'] as int? ?? 0,
    );
    final extraLifeLimitBreak = EggShardLogic.clampExtraLifeLimitBreak(
      json['extraLifeLimitBreakLevel'] as int? ?? 0,
    );
    return PlayerState(
      coins: coins,
      ownedAnimals: (json['ownedAnimals'] as List<dynamic>)
          .map((item) => OwnedAnimal.fromJson(item as Map<String, dynamic>))
          .toList(),
      lastSavedTime: DateTime.parse(json['lastSavedTime'] as String),
      // Older saves may not have lifetime coins — use current coins as estimate.
      lifetimeCoinsEarned: json['lifetimeCoinsEarned'] as int? ?? coins,
      luckLevel: json['luckLevel'] as int? ?? 1,
      rebirthLevel: json['rebirthLevel'] as int? ?? 0,
      questProgress: QuestProgress.fromJson(
        json['questProgress'] as Map<String, dynamic>?,
      ),
      secretSpaceEggClaimed: json['secretSpaceEggClaimed'] as bool? ?? false,
      fullDeveloperToolsUnlocked:
          json['fullDeveloperToolsUnlocked'] as bool? ?? false,
      battleTokens: json['battleTokens'] as int? ?? 0,
      bossWins: _bossWinsFromJson(json['bossWins']),
      hardPhaseWins: _bossWinsFromJson(json['hardPhaseWins']),
      nightmareWins: _bossWinsFromJson(json['nightmareWins']),
      bossMutationUnlocked: json['bossMutationUnlocked'] as bool? ?? false,
      activeAutoBattle: json['activeAutoBattle'] is Map<String, dynamic>
          ? ActiveAutoBattle.fromJson(
              json['activeAutoBattle'] as Map<String, dynamic>,
            )
          : null,
      tutorialCompleted: json['tutorialCompleted'] as bool? ?? false,
      tutorialSkipped: json['tutorialSkipped'] as bool? ?? false,
      tutorialVersionCompleted: json['tutorialVersionCompleted'] as int? ?? 0,
      battleHomingLevel: EggShardLogic.clampHomingLevel(
        json['battleHomingLevel'] as int? ?? 0,
        battleLimitBreak,
      ),
      battleShotSpeedLevel: EggShardLogic.clampShotSpeedLevel(
        json['battleShotSpeedLevel'] as int? ?? 0,
        battleLimitBreak,
      ),
      battleExtraLifeLevel: EggShardLogic.clampExtraLifeLevel(
        json['battleExtraLifeLevel'] as int? ?? 0,
        extraLifeLimitBreak,
      ),
      eggShards: (json['eggShards'] as num?)?.toInt() ?? 0,
      shadowPhoenixFlawlessWin:
          json['shadowPhoenixFlawlessWin'] as bool? ?? false,
      battleLimitBreakLevel: battleLimitBreak,
      extraLifeLimitBreakLevel: extraLifeLimitBreak,
      eggRebirthReductionLevel: EggShardLogic.clampEggRebirthReduction(
        json['eggRebirthReductionLevel'] as int? ?? 0,
      ),
      customSpriteCanvasTier: EggShardLogic.clampCustomSpriteCanvas(
        json['customSpriteCanvasTier'] as int? ?? 0,
      ),
      lastDailyRewardClaimDate: json['lastDailyRewardClaimDate'] as String?,
      dailyRewardStreak: (json['dailyRewardStreak'] as num?)?.toInt() ?? 0,
      bestDailyRewardStreak:
          (json['bestDailyRewardStreak'] as num?)?.toInt() ?? 0,
      dailyQuestDate: json['dailyQuestDate'] as String?,
      dailyQuests: _dailyQuestsFromJson(json['dailyQuests']),
      lastDailyRewardPopupDismissDate:
          json['lastDailyRewardPopupDismissDate'] as String?,
      eggMastery: _eggMasteryFromJson(json['eggMastery']),
      arenaRating: (json['arenaRating'] as num?)?.toInt() ?? 1000,
      arenaWins: (json['arenaWins'] as num?)?.toInt() ?? 0,
      arenaLosses: (json['arenaLosses'] as num?)?.toInt() ?? 0,
      arenaWinStreak: (json['arenaWinStreak'] as num?)?.toInt() ?? 0,
      arenaBestStreak: (json['arenaBestStreak'] as num?)?.toInt() ?? 0,
    );
  }

  static Map<String, EggMasteryProgress> _eggMasteryFromJson(Object? raw) {
    if (raw is! Map) return const {};
    final parsed = <String, EggMasteryProgress>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is! Map<String, dynamic>) continue;
      final progress = EggMasteryProgress.fromJson(value);
      parsed[progress.eggId] = progress;
    }
    return EggMasteryLogic.normalizeMap(parsed);
  }

  static List<DailyQuestProgress> _dailyQuestsFromJson(Object? raw) {
    if (raw is! List || raw.isEmpty) return const [];
    return raw
        .map(
          (item) => DailyQuestProgress.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  static Map<String, int> _bossWinsFromJson(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        entry.key.toString(): (entry.value as num).toInt(),
    };
  }
}
