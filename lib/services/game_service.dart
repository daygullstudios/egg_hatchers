import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/boss_data.dart';
import '../data/game_data.dart';
import '../data/tutorial_data.dart';
import '../data/quest_data.dart';
import '../models/active_auto_battle.dart';
import '../models/arena.dart';
import '../models/animal.dart';
import '../models/boss_battle.dart';
import '../models/custom_egg.dart';
import '../models/egg.dart';
import '../models/egg_mastery_progress.dart';
import '../models/forced_hatch_result.dart';
import '../models/hatch_result.dart';
import '../models/boss_reward_grant.dart';
import '../models/daily_quest_progress.dart';
import '../utils/daily_system_logic.dart';
import '../utils/custom_egg_logic.dart';
import '../utils/animal_fusion_logic.dart';
import '../utils/battle_upgrade_logic.dart';
import '../utils/luck_logic.dart';
import '../models/mutation.dart';
import '../models/owned_animal.dart';
import '../models/player_state.dart';
import '../models/quest.dart';
import '../models/quest_claim_result.dart';
import '../models/quest_progress.dart';
import '../utils/quest_logic.dart';
import '../utils/rebirth_logic.dart';
import '../utils/animal_sell_logic.dart';
import '../utils/arena_logic.dart';
import '../utils/built_in_egg_logic.dart';
import '../utils/egg_mastery_logic.dart';
import '../utils/battle_power_logic.dart';
import '../utils/boss_battle_logic.dart';
import '../utils/egg_shard_logic.dart';
import '../utils/sprite_rating_logic.dart';
import 'save_service.dart';
import 'sprite_reference_overlay_service.dart';

/// Central game logic: coins, hatching, mutations, idle income, and saving.
class GameService extends ChangeNotifier {
  GameService({SaveService? saveService, Random? random})
    : _saveService = saveService ?? SaveService(),
      _random = random ?? Random();

  SaveService _saveService;
  final Random _random;
  String? _activeAccountId;

  PlayerState _state = GameData.startingPlayerState();
  Timer? _idleTimer;
  bool _isInitialized = false;
  String? _pendingQuestNotification;
  bool _questNotificationDeferred = false;
  final List<String> _pendingMasteryNotifications = [];
  AutoBattleCompletionSummary? _pendingAutoBattleCompletion;
  var _dailyRewardPopupShownThisSession = false;

  // In-memory only — for developer testing, not saved.
  ForcedHatchMode _forcedHatchMode = ForcedHatchMode.none;
  List<ForcedHatchResult> _forcedHatchQueue = [];

  PlayerState get state => _state;
  bool get isInitialized => _isInitialized;

  static Mutation _mutationFor(OwnedAnimal owned) {
    return GameData.mutationById(owned.mutationId) ?? GameData.mutations.first;
  }

  /// Income: base × mutationMultiplier × quantity × level × egg mastery bonus.
  static int incomeFor(
    Animal animal,
    OwnedAnimal owned, {
    int masteryLevel = 0,
  }) {
    final mutation = _mutationFor(owned);
    final base =
        animal.coinsPerSecond *
        mutation.incomeMultiplier *
        owned.quantity *
        owned.level;
    if (owned.sourceEggId == null || masteryLevel <= 0) {
      return base;
    }
    return EggMasteryLogic.applyIncomeBonus(base, masteryLevel);
  }

  int masteryLevelForEgg(String? eggId) {
    if (eggId == null) return 0;
    return _state.eggMastery[eggId]?.masteryLevel ?? 0;
  }

  EggMasteryProgress? eggMasteryProgress(String eggId) {
    return _state.eggMastery[eggId];
  }

  int incomeForOwned(Animal animal, OwnedAnimal owned) {
    return incomeFor(
      animal,
      owned,
      masteryLevel: masteryLevelForEgg(owned.sourceEggId),
    );
  }

  /// Upgrade cost: base × level × 30 (mutation does not affect cost).
  static int upgradeCostFor(Animal animal, OwnedAnimal owned) {
    return animal.coinsPerSecond * owned.level * 30;
  }

  /// Sell value for one animal from this owned stack.
  static int sellValueFor(Animal animal, OwnedAnimal owned) {
    return AnimalSellLogic.sellValueFor(animal, owned);
  }

  bool canSellOwnedAnimal(
    String animalId,
    String mutationId, {
    int quantity = 1,
    bool isProtected = false,
  }) {
    if (quantity < 1) return false;
    if (isStackAutoBattling(
      animalId: animalId,
      mutationId: mutationId,
      isProtected: isProtected,
    )) {
      return false;
    }
    final owned = ownedAnimal(
      animalId,
      mutationId: mutationId,
      isProtected: isProtected,
    );
    if (owned == null || owned.isProtected) return false;
    return owned.quantity >= quantity;
  }

  /// Sells animals from a specific stack. Returns coins granted, or null.
  int? sellOwnedAnimal(
    String animalId,
    String mutationId, {
    int quantity = 1,
    bool isProtected = false,
  }) {
    if (!canSellOwnedAnimal(
      animalId,
      mutationId,
      quantity: quantity,
      isProtected: isProtected,
    )) {
      return null;
    }

    final owned = ownedAnimal(
      animalId,
      mutationId: mutationId,
      isProtected: isProtected,
    )!;
    final animal = GameData.animalById(animalId);
    if (animal == null) return null;

    final unitValue = sellValueFor(animal, owned);
    final coinsGranted = unitValue * quantity;
    if (coinsGranted <= 0) return null;

    final updatedAnimals = List<OwnedAnimal>.from(_state.ownedAnimals);
    final index = _indexOfOwnedStack(
      updatedAnimals,
      animalId,
      mutationId,
      isProtected: isProtected,
    );
    if (index < 0) return null;

    final remaining = owned.quantity - quantity;
    if (remaining <= 0) {
      updatedAnimals.removeAt(index);
    } else {
      updatedAnimals[index] = owned.copyWith(quantity: remaining);
    }

    _state = _state.copyWith(
      coins: _state.coins + coinsGranted,
      ownedAnimals: updatedAnimals,
    );
    notifyListeners();
    save();
    return coinsGranted;
  }

  /// Total coins earned per second from all owned animals (includes rebirth).
  int get coinsPerSecond {
    var total = 0;
    for (final owned in _state.ownedAnimals) {
      if (isStackAutoBattling(
        animalId: owned.animalId,
        mutationId: owned.mutationId,
        isProtected: owned.isProtected,
      )) {
        continue;
      }
      final animal = GameData.animalById(owned.animalId);
      if (animal != null) {
        total += incomeForOwned(animal, owned);
      }
    }
    return RebirthLogic.applyMultiplier(total, _state.rebirthLevel);
  }

  int get baseCoinsPerSecond {
    var total = 0;
    for (final owned in _state.ownedAnimals) {
      if (isStackAutoBattling(
        animalId: owned.animalId,
        mutationId: owned.mutationId,
        isProtected: owned.isProtected,
      )) {
        continue;
      }
      final animal = GameData.animalById(owned.animalId);
      if (animal != null) {
        total += incomeForOwned(animal, owned);
      }
    }
    return total;
  }

  int get coins => _state.coins;
  int get lifetimeCoinsEarned => _state.lifetimeCoinsEarned;
  int get luckLevel => _state.luckLevel;
  int get rebirthLevel => _state.rebirthLevel;
  double get incomeMultiplier =>
      RebirthLogic.incomeMultiplier(_state.rebirthLevel);
  bool get canRebirth => RebirthLogic.canRebirth(
    lifetimeCoinsEarned: _state.lifetimeCoinsEarned,
    rebirthLevel: _state.rebirthLevel,
  );
  int get rebirthRequirement =>
      RebirthLogic.nextRebirthRequirement(_state.rebirthLevel);
  bool get secretSpaceEggClaimed => _state.secretSpaceEggClaimed;

  /// True when the one-time Secret Reward Badge has been applied or legacy void egg claimed.
  bool get secretRewardBadgeClaimed => _state.secretSpaceEggClaimed;

  bool get isDayGullEggUnlocked =>
      (_state.bossWins[EggShardLogic.rottenShellBossId] ?? 0) > 0;

  List<Egg> get visibleShopEggs => GameData.eggs
      .where((egg) => egg.id != GameData.dayGullEggId || isDayGullEggUnlocked)
      .toList(growable: false);

  bool get tutorialCompleted => _state.tutorialCompleted;
  bool get tutorialSkipped => _state.tutorialSkipped;
  int get tutorialVersionCompleted => _state.tutorialVersionCompleted;

  bool get shouldAutoStartTutorial =>
      !_state.tutorialCompleted &&
      !_state.tutorialSkipped &&
      _state.tutorialVersionCompleted < TutorialData.currentVersion &&
      _isNewPlayerForTutorial();

  bool _isNewPlayerForTutorial() {
    final starting = GameData.startingPlayerState();
    return _state.lifetimeCoinsEarned == 0 &&
        _state.ownedAnimals.isEmpty &&
        _state.coins <= starting.coins;
  }

  void completeTutorial() {
    _state = _state.copyWith(
      tutorialCompleted: true,
      tutorialSkipped: false,
      tutorialVersionCompleted: TutorialData.currentVersion,
    );
    notifyListeners();
    save();
  }

  void skipTutorial() {
    _state = _state.copyWith(tutorialSkipped: true);
    notifyListeners();
    save();
  }

  void devResetTutorial() {
    _state = _state.copyWith(
      tutorialCompleted: false,
      tutorialSkipped: false,
      tutorialVersionCompleted: 0,
    );
    notifyListeners();
    save();
  }

  void devCompleteTutorial() => completeTutorial();

  bool get hasSecretRewardAnimal =>
      _state.ownedAnimals.any((owned) => owned.isSecretReward);

  bool get canUseSecretRewardBadge =>
      !_state.secretSpaceEggClaimed && _state.ownedAnimals.isNotEmpty;
  int get battleTokens => _state.battleTokens;
  int get arenaRating => _state.arenaRating;
  int get arenaWins => _state.arenaWins;
  int get arenaLosses => _state.arenaLosses;
  int get arenaWinStreak => _state.arenaWinStreak;
  int get arenaBestStreak => _state.arenaBestStreak;
  String get arenaDivision => ArenaLogic.divisionFor(_state.arenaRating);
  Map<String, int> get bossWins => Map.unmodifiable(_state.bossWins);
  int get totalBossWins =>
      _state.bossWins.values.fold<int>(0, (sum, count) => sum + count);
  QuestProgress get questProgress => _state.questProgress;
  ActiveAutoBattle? get activeAutoBattle => _state.activeAutoBattle;
  bool get hasActiveAutoBattle => _state.activeAutoBattle != null;
  List<OwnedAnimal> get ownedAnimals => List.unmodifiable(_state.ownedAnimals);

  List<OwnedAnimal> get normalAnimals =>
      _state.ownedAnimals.where((o) => o.mutationId == 'none').toList();

  List<OwnedAnimal> get mutatedAnimals =>
      _state.ownedAnimals.where((o) => o.mutationId != 'none').toList();

  bool get hasForcedNextHatch => _forcedHatchQueue.isNotEmpty;

  bool get isForcedTripleHatch =>
      _forcedHatchMode == ForcedHatchMode.triple &&
      _forcedHatchQueue.length >= 3;

  List<ForcedHatchResult> get forcedHatchQueue =>
      List<ForcedHatchResult>.unmodifiable(_forcedHatchQueue);

  String? get forcedNextAnimalId =>
      _forcedHatchQueue.isEmpty ? null : _forcedHatchQueue.first.animalId;

  String? get forcedNextMutationId =>
      _forcedHatchQueue.isEmpty ? null : _forcedHatchQueue.first.mutationId;

  /// Load saved progress, apply offline earnings, and start idle income.
  Future<void> initialize({
    String? accountId,
    bool migrateLegacySave = false,
  }) async {
    if (accountId != null) {
      _activeAccountId = accountId;
      _saveService = SaveService(accountId: accountId);
    }
    var saved = await _saveService.load();
    if (saved == null && accountId != null && migrateLegacySave) {
      saved = await SaveService().load();
      if (saved != null) await _saveService.save(saved);
    }
    _loadState(saved);
    _isInitialized = true;
    _startIdleTimer();
    notifyListeners();
  }

  void _loadState(PlayerState? saved) {
    if (saved != null) {
      _state = _migrateEliteRewardAnimals(saved);
      _refreshDailyQuestsIfNeeded();
      _resolveActiveAutoBattle();
      _applyOfflineEarnings();
    } else {
      _state = GameData.startingPlayerState();
      _refreshDailyQuestsIfNeeded();
    }

    _silenceExistingQuestNotifications();
    _pendingQuestNotification = null;
    _pendingMasteryNotifications.clear();
    _pendingAutoBattleCompletion = null;
    _dailyRewardPopupShownThisSession = false;
  }

  Future<void> switchAccount(
    String accountId, {
    bool migrateLegacySave = false,
  }) async {
    if (_activeAccountId == accountId) return;
    if (_activeAccountId != null) await save();
    _idleTimer?.cancel();
    _activeAccountId = accountId;
    _saveService = SaveService(accountId: accountId);
    var saved = await _saveService.load();
    if (saved == null && migrateLegacySave) {
      saved = await SaveService().load();
      if (saved != null) await _saveService.save(saved);
    }
    _loadState(saved);
    _startIdleTimer();
    notifyListeners();
  }

  Future<void> deleteAccountSave(String accountId) async {
    if (_activeAccountId == accountId) {
      _idleTimer?.cancel();
      _activeAccountId = null;
      _saveService = SaveService();
      _loadState(null);
      _startIdleTimer();
      notifyListeners();
    }
    await SaveService(accountId: accountId).delete();
  }

  void _applyOfflineEarnings() {
    final now = DateTime.now();
    final elapsed = now.difference(_state.lastSavedTime);
    if (elapsed.isNegative) return;

    final earned = (coinsPerSecond * elapsed.inSeconds).floor();
    if (earned > 0) {
      _addEarnedCoins(earned, lastSavedTime: now);
    }
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickIdleIncome();
    });
  }

  void _tickIdleIncome() {
    _resolveActiveAutoBattle();

    final income = coinsPerSecond;
    if (income <= 0) return;

    _addEarnedCoins(income);
    notifyListeners();
    _saveQuietly();
  }

  /// Adds coins from animal income and tracks lifetime earnings.
  void _addEarnedCoins(int amount, {DateTime? lastSavedTime}) {
    if (amount <= 0) return;
    _state = _state.copyWith(
      coins: _state.coins + amount,
      lifetimeCoinsEarned: _state.lifetimeCoinsEarned + amount,
      lastSavedTime: lastSavedTime ?? DateTime.now(),
    );
    _refreshQuestNotifications();
  }

  /// Returns and clears a pending quest completion notification message.
  String? consumePendingQuestNotification() {
    if (_questNotificationDeferred) return null;
    final message = _pendingQuestNotification;
    _pendingQuestNotification = null;
    return message;
  }

  /// Releases a hatch-deferred notification after the reveal dialog closes.
  String? releaseDeferredQuestNotification() {
    if (!_questNotificationDeferred) return null;
    _questNotificationDeferred = false;
    final message = _pendingQuestNotification;
    _pendingQuestNotification = null;
    return message;
  }

  bool get isQuestNotificationDeferred => _questNotificationDeferred;

  String? consumePendingMasteryNotification() {
    if (_pendingMasteryNotifications.isEmpty) return null;
    return _pendingMasteryNotifications.removeAt(0);
  }

  bool get hasPendingMasteryNotifications =>
      _pendingMasteryNotifications.isNotEmpty;

  void _silenceExistingQuestNotifications() {
    final progress = _state.questProgress;
    final toAdd = <String>[];
    for (final quest in QuestData.all) {
      if (progress.wasCompletionNotified(quest.id)) continue;
      final status = QuestLogic.status(quest, _state);
      if (status == QuestStatus.readyToClaim || status == QuestStatus.claimed) {
        toAdd.add(quest.id);
      }
    }
    if (toAdd.isEmpty) return;

    _state = _state.copyWith(
      questProgress: progress.copyWith(
        notifiedCompletedQuestIds: [
          ...progress.notifiedCompletedQuestIds,
          ...toAdd,
        ],
      ),
    );
    _saveQuietly();
  }

  void _refreshQuestNotifications({bool deferDisplay = false}) {
    final newlyCompleted = QuestLogic.newlyCompletedUnnotified(_state);
    if (newlyCompleted.isEmpty) return;

    _pendingQuestNotification = QuestLogic.completionNotificationMessage(
      newlyCompleted,
    );
    if (deferDisplay) {
      _questNotificationDeferred = true;
    }
    final progress = _state.questProgress;
    _state = _state.copyWith(
      questProgress: progress.copyWith(
        notifiedCompletedQuestIds: [
          ...progress.notifiedCompletedQuestIds,
          ...newlyCompleted.map((quest) => quest.id),
        ],
      ),
    );
  }

  Future<void> _saveQuietly() async {
    await _saveService.save(_state);
  }

  Future<void> save() async {
    _state = _state.copyWith(lastSavedTime: DateTime.now());
    await _saveService.save(_state);
  }

  bool isEggUnlocked(Egg egg) {
    if (egg.id == GameData.dayGullEggId) {
      return isDayGullEggUnlocked;
    }
    if (egg.usesBattleTokens) {
      return _state.ownedAnimals.isNotEmpty;
    }
    final effectiveRebirth = EggShardLogic.effectiveRebirthRequirement(
      egg.unlockRebirthLevel,
      _state.eggRebirthReductionLevel,
    );
    if (effectiveRebirth > 0 && _state.rebirthLevel < effectiveRebirth) {
      return false;
    }
    if (egg.unlockLifetimeCoins > 0 &&
        _state.lifetimeCoinsEarned < egg.unlockLifetimeCoins) {
      return false;
    }
    return true;
  }

  int get eggShards => _state.eggShards;
  bool get shadowPhoenixFlawlessWin => _state.shadowPhoenixFlawlessWin;
  int get battleLimitBreakLevel => _state.battleLimitBreakLevel;
  int get extraLifeLimitBreakLevel => _state.extraLifeLimitBreakLevel;
  int get eggRebirthReductionLevel => _state.eggRebirthReductionLevel;
  int get customSpriteCanvasTier => _state.customSpriteCanvasTier;

  int get battleHomingMaxLevel =>
      EggShardLogic.homingMaxLevel(_state.battleLimitBreakLevel);
  int get battleShotSpeedMaxLevel =>
      EggShardLogic.shotSpeedMaxLevel(_state.battleLimitBreakLevel);
  int get battleExtraLifeMaxLevel =>
      EggShardLogic.extraLifeMaxLevel(_state.extraLifeLimitBreakLevel);
  int get maxCustomSpriteGridSize =>
      EggShardLogic.maxCustomSpriteGridSize(_state.customSpriteCanvasTier);

  int rottenShellUnlockProgress() =>
      EggShardLogic.defeatedPrerequisiteCount(_state);

  int effectiveEggRebirthRequirement(Egg egg) =>
      EggShardLogic.effectiveRebirthRequirement(
        egg.unlockRebirthLevel,
        _state.eggRebirthReductionLevel,
      );

  String eggLockedDisplayMessage(Egg egg) {
    if (egg.id == GameData.dayGullEggId) {
      return 'Beat The Rotten Shell to unlock the DayGull Egg.';
    }
    final effective = effectiveEggRebirthRequirement(egg);
    if (effective > 0 && _state.rebirthLevel < effective) {
      return 'Requires Rebirth Level $effective';
    }
    return egg.unlockMessage;
  }

  bool get bossMutationUnlocked => _state.bossMutationUnlocked;
  int get battleHomingLevel => _state.battleHomingLevel;
  int get battleShotSpeedLevel => _state.battleShotSpeedLevel;
  int get battleExtraLifeLevel => _state.battleExtraLifeLevel;
  String? get lastDailyRewardClaimDate => _state.lastDailyRewardClaimDate;
  int get dailyRewardStreak => _state.dailyRewardStreak;
  int get bestDailyRewardStreak => _state.bestDailyRewardStreak;
  List<DailyQuestProgress> get dailyQuests {
    _refreshDailyQuestsIfNeeded();
    return List.unmodifiable(_state.dailyQuests);
  }

  bool get hasClaimedDailyRewardToday =>
      _state.lastDailyRewardClaimDate == DailySystemLogic.todayKey();

  bool get canClaimDailyReward => !hasClaimedDailyRewardToday;

  DailyRewardOffer get upcomingDailyReward =>
      DailySystemLogic.rewardForStreak(_dailyRewardStreakAfterClaim());

  /// Streak shown before claiming (includes consecutive-day bonus).
  int get displayDailyRewardStreak => hasClaimedDailyRewardToday
      ? _state.dailyRewardStreak
      : _dailyRewardStreakAfterClaim();

  bool get shouldAutoShowDailyRewardPopup {
    if (_dailyRewardPopupShownThisSession) return false;
    if (!_state.tutorialCompleted && !_state.tutorialSkipped) return false;
    if (!canClaimDailyReward) return false;
    if (_state.lastDailyRewardPopupDismissDate == DailySystemLogic.todayKey()) {
      return false;
    }
    return true;
  }

  void markDailyRewardPopupShown() {
    _dailyRewardPopupShownThisSession = true;
  }

  void dismissDailyRewardPopup() {
    _dailyRewardPopupShownThisSession = true;
    _state = _state.copyWith(
      lastDailyRewardPopupDismissDate: DailySystemLogic.todayKey(),
    );
    notifyListeners();
    save();
  }

  void resetDailyRewardPopupSessionGuard() {
    _dailyRewardPopupShownThisSession = false;
  }

  int get dailyQuestsCompleteCount =>
      dailyQuests.where((quest) => quest.isComplete).length;

  int get dailyQuestsClaimedCount =>
      dailyQuests.where((quest) => quest.claimed).length;

  bool canAfford(Egg egg) {
    if (egg.usesBattleTokens) {
      return _state.battleTokens >= egg.cost;
    }
    return _state.coins >= egg.cost;
  }

  bool canBuyEgg(Egg egg) => isEggUnlocked(egg) && canAfford(egg);

  /// Triple Hatch costs 3.5× the egg price, rounded up.
  static int tripleHatchCost(Egg egg) => (egg.cost * 3.5).ceil();

  bool canAffordTripleHatch(Egg egg) {
    if (!isEggUnlocked(egg)) return false;
    if (egg.usesBattleTokens) {
      return _state.battleTokens >= tripleHatchCost(egg);
    }
    return _state.coins >= tripleHatchCost(egg);
  }

  bool buyEgg(Egg egg) {
    if (!canBuyEgg(egg)) return false;

    if (egg.usesBattleTokens) {
      _state = _state.copyWith(battleTokens: _state.battleTokens - egg.cost);
    } else {
      _state = _state.copyWith(coins: _state.coins - egg.cost);
    }
    _incrementDailyQuest(DailySystemLogic.buyEggsType);
    notifyListeners();
    save();
    return true;
  }

  bool buyTripleHatch(Egg egg) {
    if (!isEggUnlocked(egg)) return false;

    final cost = tripleHatchCost(egg);
    if (egg.usesBattleTokens) {
      if (_state.battleTokens < cost) return false;
      _state = _state.copyWith(battleTokens: _state.battleTokens - cost);
    } else {
      if (_state.coins < cost) return false;
      _state = _state.copyWith(coins: _state.coins - cost);
    }
    _incrementDailyQuest(DailySystemLogic.buyEggsType);
    notifyListeners();
    save();
    return true;
  }

  void setCoins(int amount) {
    _state = _state.copyWith(coins: amount < 0 ? 0 : amount);
    notifyListeners();
    save();
  }

  void addCoins(int amount) {
    setCoins(_state.coins + amount);
  }

  void resetCoins() {
    setCoins(GameData.startingPlayerState().coins);
  }

  void setLifetimeCoinsEarned(int amount) {
    _state = _state.copyWith(lifetimeCoinsEarned: amount < 0 ? 0 : amount);
    _refreshQuestNotifications();
    notifyListeners();
    save();
  }

  void addLifetimeCoinsEarned(int amount) {
    setLifetimeCoinsEarned(_state.lifetimeCoinsEarned + amount);
  }

  void resetLifetimeCoinsEarned() {
    setLifetimeCoinsEarned(0);
  }

  int get luckUpgradeCost => LuckLogic.upgradeCost(_state.luckLevel);

  bool get isLuckMaxed => _state.luckLevel >= LuckLogic.maxLevel;

  bool canAffordLuckUpgrade() =>
      !isLuckMaxed && _state.coins >= luckUpgradeCost;

  /// Upgrade luck if affordable. Returns new level or null on failure.
  int? upgradeLuck() {
    if (isLuckMaxed) return null;
    final cost = luckUpgradeCost;
    if (_state.coins < cost) return null;

    final newLevel = _state.luckLevel + 1;
    _state = _state.copyWith(
      coins: _state.coins - cost,
      luckLevel: newLevel,
      questProgress: _state.questProgress.copyWith(
        totalLuckUpgrades: _state.questProgress.totalLuckUpgrades + 1,
      ),
    );
    _refreshQuestNotifications();
    notifyListeners();
    save();
    return newLevel;
  }

  void setLuckLevel(int level) {
    _state = _state.copyWith(luckLevel: LuckLogic.clampLevel(level));
    _refreshQuestNotifications();
    notifyListeners();
    save();
  }

  void resetLuckLevel() => setLuckLevel(LuckLogic.minLevel);

  void maxLuckLevel() => setLuckLevel(LuckLogic.maxLevel);

  /// Rebirth if eligible. Resets progress and increases rebirth level.
  bool performRebirth() {
    if (!canRebirth) return false;
    if (_state.activeAutoBattle != null) return false;

    final newRebirthLevel = _state.rebirthLevel + 1;
    final secretClaimed = _state.secretSpaceEggClaimed;
    final devToolsUnlocked = _state.fullDeveloperToolsUnlocked;
    final battleTokens = _state.battleTokens;
    final bossWins = _state.bossWins;
    final bossMutationUnlocked = _state.bossMutationUnlocked;
    final battleHomingLevel = _state.battleHomingLevel;
    final battleShotSpeedLevel = _state.battleShotSpeedLevel;
    final battleExtraLifeLevel = _state.battleExtraLifeLevel;
    final eggShards = _state.eggShards;
    final shadowPhoenixFlawlessWin = _state.shadowPhoenixFlawlessWin;
    final battleLimitBreakLevel = _state.battleLimitBreakLevel;
    final extraLifeLimitBreakLevel = _state.extraLifeLimitBreakLevel;
    final eggRebirthReductionLevel = _state.eggRebirthReductionLevel;
    final customSpriteCanvasTier = _state.customSpriteCanvasTier;
    final lastDailyRewardClaimDate = _state.lastDailyRewardClaimDate;
    final dailyRewardStreak = _state.dailyRewardStreak;
    final bestDailyRewardStreak = _state.bestDailyRewardStreak;
    final dailyQuestDate = _state.dailyQuestDate;
    final dailyQuests = _state.dailyQuests;
    final lastDailyRewardPopupDismissDate =
        _state.lastDailyRewardPopupDismissDate;
    final tutorialCompleted = _state.tutorialCompleted;
    final tutorialSkipped = _state.tutorialSkipped;
    final tutorialVersionCompleted = _state.tutorialVersionCompleted;
    final eggMastery = _state.eggMastery;
    final protectedAnimals = _state.ownedAnimals
        .where((owned) => owned.isProtected)
        .toList();
    _state = PlayerState(
      coins: GameData.startingPlayerState().coins,
      ownedAnimals: protectedAnimals,
      lastSavedTime: DateTime.now(),
      lifetimeCoinsEarned: 0,
      luckLevel: 1,
      rebirthLevel: newRebirthLevel,
      questProgress: QuestProgress.initial(),
      secretSpaceEggClaimed: secretClaimed,
      fullDeveloperToolsUnlocked: devToolsUnlocked,
      battleTokens: battleTokens,
      bossWins: bossWins,
      bossMutationUnlocked: bossMutationUnlocked,
      battleHomingLevel: battleHomingLevel,
      battleShotSpeedLevel: battleShotSpeedLevel,
      battleExtraLifeLevel: battleExtraLifeLevel,
      eggShards: eggShards,
      shadowPhoenixFlawlessWin: shadowPhoenixFlawlessWin,
      battleLimitBreakLevel: battleLimitBreakLevel,
      extraLifeLimitBreakLevel: extraLifeLimitBreakLevel,
      eggRebirthReductionLevel: eggRebirthReductionLevel,
      customSpriteCanvasTier: customSpriteCanvasTier,
      lastDailyRewardClaimDate: lastDailyRewardClaimDate,
      dailyRewardStreak: dailyRewardStreak,
      bestDailyRewardStreak: bestDailyRewardStreak,
      dailyQuestDate: dailyQuestDate,
      dailyQuests: dailyQuests,
      lastDailyRewardPopupDismissDate: lastDailyRewardPopupDismissDate,
      tutorialCompleted: tutorialCompleted,
      tutorialSkipped: tutorialSkipped,
      tutorialVersionCompleted: tutorialVersionCompleted,
      eggMastery: eggMastery,
    );
    _pendingQuestNotification = null;
    _pendingMasteryNotifications.clear();
    _questNotificationDeferred = false;
    _refreshQuestNotifications();
    notifyListeners();
    save();
    return true;
  }

  void setRebirthLevel(int level) {
    _state = _state.copyWith(rebirthLevel: level < 0 ? 0 : level);
    _refreshQuestNotifications();
    notifyListeners();
    save();
  }

  void devIncrementRebirthLevel() => setRebirthLevel(_state.rebirthLevel + 1);

  void resetRebirthLevel() => setRebirthLevel(0);

  /// Claim a completed quest reward. Returns null on failure.
  QuestClaimResult? claimQuest(String questId) {
    Quest? quest;
    for (final candidate in QuestData.all) {
      if (candidate.id == questId) {
        quest = candidate;
        break;
      }
    }
    if (quest == null) return null;
    if (_state.questProgress.isQuestClaimed(questId)) return null;
    if (!QuestLogic.isComplete(quest, _state)) return null;

    if (quest.showsSecretHintOnClaim) {
      _state = _state.copyWith(
        questProgress: _state.questProgress.copyWith(
          claimedQuestIds: [..._state.questProgress.claimedQuestIds, questId],
        ),
      );
      _incrementDailyQuest(DailySystemLogic.claimQuestRewardType);
      notifyListeners();
      save();
      return const QuestClaimResult();
    }

    _state = _state.copyWith(
      coins: _state.coins + quest.rewardCoins,
      battleTokens: _state.battleTokens + quest.rewardBattleTokens,
      questProgress: _state.questProgress.copyWith(
        claimedQuestIds: [..._state.questProgress.claimedQuestIds, questId],
      ),
    );
    _incrementDailyQuest(DailySystemLogic.claimQuestRewardType);
    notifyListeners();
    save();
    return QuestClaimResult(
      coins: quest.rewardCoins,
      battleTokens: quest.rewardBattleTokens,
    );
  }

  void _refreshDailyQuestsIfNeeded() {
    final today = DailySystemLogic.todayKey();
    if (_state.dailyQuestDate == today && _state.dailyQuests.isNotEmpty) {
      return;
    }
    _state = _state.copyWith(
      dailyQuestDate: today,
      dailyQuests: DailySystemLogic.generateDailyQuests(today),
    );
  }

  void _rerollDailyQuestsForToday({int? rerollSalt}) {
    final today = DailySystemLogic.todayKey();
    _state = _state.copyWith(
      dailyQuestDate: today,
      dailyQuests: DailySystemLogic.generateDailyQuests(
        today,
        rerollSalt: rerollSalt ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  int _dailyRewardStreakAfterClaim() {
    if (hasClaimedDailyRewardToday) return _state.dailyRewardStreak;
    if (DailySystemLogic.isYesterday(_state.lastDailyRewardClaimDate)) {
      return _state.dailyRewardStreak + 1;
    }
    return 1;
  }

  bool claimDailyReward() {
    final today = DailySystemLogic.todayKey();
    if (_state.lastDailyRewardClaimDate == today) return false;

    final streak = _dailyRewardStreakAfterClaim();
    final best = max(_state.bestDailyRewardStreak, streak);
    final reward = DailySystemLogic.rewardForStreak(streak);

    var progress = _state.questProgress;
    var coins = _state.coins;
    var tokens = _state.battleTokens;

    coins += reward.coins;
    if (reward.battleTokens > 0) {
      tokens += reward.battleTokens;
      progress = progress.copyWith(
        totalBattleTokensEarned:
            progress.totalBattleTokensEarned + reward.battleTokens,
      );
    }

    _state = _state.copyWith(
      lastDailyRewardClaimDate: today,
      dailyRewardStreak: streak,
      bestDailyRewardStreak: best,
      coins: coins,
      battleTokens: tokens,
      questProgress: progress,
    );
    notifyListeners();
    save();
    return true;
  }

  bool claimDailyQuest(String questId) {
    _refreshDailyQuestsIfNeeded();
    final index = _state.dailyQuests.indexWhere((quest) => quest.id == questId);
    if (index < 0) return false;

    final quest = _state.dailyQuests[index];
    if (quest.claimed || !quest.isComplete) return false;

    var progress = _state.questProgress;
    var coins = _state.coins;
    var tokens = _state.battleTokens;

    if (quest.rewardCoins > 0) {
      coins += quest.rewardCoins;
    }
    if (quest.rewardBattleTokens > 0) {
      tokens += quest.rewardBattleTokens;
      progress = progress.copyWith(
        totalBattleTokensEarned:
            progress.totalBattleTokensEarned + quest.rewardBattleTokens,
      );
    }

    final updatedQuests = List<DailyQuestProgress>.from(_state.dailyQuests);
    updatedQuests[index] = quest.copyWith(claimed: true);

    _state = _state.copyWith(
      dailyQuests: updatedQuests,
      coins: coins,
      battleTokens: tokens,
      questProgress: progress,
    );
    notifyListeners();
    save();
    return true;
  }

  void _incrementDailyQuest(String type, {int amount = 1}) {
    if (amount <= 0) return;
    _refreshDailyQuestsIfNeeded();

    var changed = false;
    final updated = _state.dailyQuests.map((quest) {
      if (quest.type != type || quest.claimed || quest.isComplete) {
        return quest;
      }
      changed = true;
      final nextProgress = quest.progress + amount;
      return quest.copyWith(
        progress: nextProgress > quest.target ? quest.target : nextProgress,
      );
    }).toList();

    if (!changed) return;
    _state = _state.copyWith(dailyQuests: updated);
  }

  /// Grants sprite rating bonus coins without affecting lifetime earnings.
  int? grantSpriteRatingReward(int coins) {
    if (coins <= 0) return null;
    _state = _state.copyWith(coins: _state.coins + coins);
    notifyListeners();
    save();
    return coins;
  }

  bool isBossUnlocked(String bossId) {
    final boss = BossBattleLogic.bossById(bossId);
    if (boss == null) return false;
    return BossBattleLogic.isBossUnlocked(boss, _state);
  }

  int bossWinCount(String bossId) => _state.bossWins[bossId] ?? 0;

  bool isHardPhaseUnlocked(String bossId) =>
      BossBattleLogic.isHardPhaseUnlocked(bossWinCount(bossId));

  int hardPhaseWinCount(String bossId) => _state.hardPhaseWins[bossId] ?? 0;

  int get totalHardPhaseWins =>
      _state.hardPhaseWins.values.fold<int>(0, (sum, count) => sum + count);

  bool isNightmareUnlocked(String bossId) =>
      BossBattleLogic.isNightmareUnlocked(hardPhaseWinCount(bossId));

  int nightmareWinCount(String bossId) => _state.nightmareWins[bossId] ?? 0;

  int eliteBossUnlockProgress(String eliteBossId) {
    final boss = BossData.bossById(eliteBossId);
    if (boss?.unlockNightmareWinsBossId == null) return 0;
    return nightmareWinCount(boss!.unlockNightmareWinsBossId!);
  }

  int get totalNightmareWins =>
      _state.nightmareWins.values.fold<int>(0, (sum, count) => sum + count);

  bool isStackAutoBattling({
    required String animalId,
    required String mutationId,
    required bool isProtected,
  }) {
    final battle = _state.activeAutoBattle;
    if (battle == null) return false;
    return battle.animalId == animalId &&
        battle.mutationId == mutationId &&
        battle.isProtected == isProtected;
  }

  bool isOwnedStackAutoBattling(OwnedAnimal owned) => isStackAutoBattling(
    animalId: owned.animalId,
    mutationId: owned.mutationId,
    isProtected: owned.isProtected,
  );

  List<OwnedAnimal> get tradableAnimals => _state.ownedAnimals
      .where(
        (owned) =>
            owned.quantity > 0 &&
            !owned.isProtected &&
            !owned.isSecretReward &&
            !owned.isEliteReward &&
            !isOwnedStackAutoBattling(owned),
      )
      .toList(growable: false);

  bool applyOnlineTrade({
    required OwnedAnimal sent,
    required OwnedAnimal received,
  }) {
    if (received.isProtected ||
        received.isSecretReward ||
        received.isEliteReward) {
      return false;
    }
    final animals = [..._state.ownedAnimals];
    final sentIndex = animals.indexWhere(
      (owned) =>
          _sameTradeStack(owned, sent) &&
          owned.quantity > 0 &&
          !owned.isProtected &&
          !owned.isSecretReward &&
          !owned.isEliteReward &&
          !isOwnedStackAutoBattling(owned),
    );
    if (sentIndex < 0) return false;
    final ownedSent = animals[sentIndex];
    if (ownedSent.quantity == 1) {
      animals.removeAt(sentIndex);
    } else {
      animals[sentIndex] = ownedSent.copyWith(quantity: ownedSent.quantity - 1);
    }

    final receivedIndex = animals.indexWhere(
      (owned) => _sameTradeStack(owned, received) && !owned.isProtected,
    );
    if (receivedIndex >= 0) {
      final existing = animals[receivedIndex];
      animals[receivedIndex] = existing.copyWith(
        quantity: existing.quantity + 1,
      );
    } else {
      animals.add(
        received.copyWith(
          quantity: 1,
          isProtected: false,
          isSecretReward: false,
          isEliteReward: false,
        ),
      );
    }
    _state = _state.copyWith(ownedAnimals: animals);
    _refreshQuestNotifications();
    notifyListeners();
    save();
    return true;
  }

  static bool _sameTradeStack(OwnedAnimal first, OwnedAnimal second) {
    return first.animalId == second.animalId &&
        first.mutationId == second.mutationId &&
        first.level == second.level &&
        first.sourceEggId == second.sourceEggId;
  }

  Duration? timeUntilNextAutoBattleFight() {
    final battle = _state.activeAutoBattle;
    if (battle == null) return null;
    final boss = BossBattleLogic.bossById(battle.bossId);
    if (boss == null) return null;
    final due = battle.lastResolvedAt.add(
      Duration(seconds: boss.autoBattleSeconds),
    );
    final remaining = due.difference(DateTime.now());
    if (remaining.isNegative) return Duration.zero;
    return remaining;
  }

  AutoBattleCompletionSummary? consumePendingAutoBattleCompletion() {
    final summary = _pendingAutoBattleCompletion;
    _pendingAutoBattleCompletion = null;
    return summary;
  }

  /// Starts a background auto battle assignment for one owned stack.
  bool startActiveAutoBattle({
    required String bossId,
    required String animalId,
    required String mutationId,
    required bool isProtected,
  }) {
    if (_state.activeAutoBattle != null) return false;

    final boss = BossBattleLogic.bossById(bossId);
    if (boss == null) return false;
    if (boss.manualBattleOnly) return false;
    if (!BossBattleLogic.isBossUnlocked(boss, _state)) return false;

    final owned = ownedAnimal(
      animalId,
      mutationId: mutationId,
      isProtected: isProtected,
    );
    if (owned == null) return false;

    final animal = GameData.animalById(animalId);
    if (animal == null) return false;

    final mutation =
        GameData.mutationById(mutationId) ?? GameData.mutations.first;
    final displayName = mutation.fullName(animal);
    final battlePower = BattlePowerLogic.battlePowerForOwnedAnimal(owned);
    final maxHp = BossBattleLogic.maxAnimalHpFor(battlePower);
    final now = DateTime.now();

    _state = _state.copyWith(
      activeAutoBattle: ActiveAutoBattle(
        id: now.microsecondsSinceEpoch.toString(),
        animalId: animalId,
        mutationId: mutationId,
        isProtected: isProtected,
        bossId: bossId,
        fighterDisplayName: displayName,
        startedAt: now,
        lastResolvedAt: now,
        currentHp: maxHp,
        maxHp: maxHp,
        battlePower: battlePower,
      ),
    );
    _incrementDailyQuest(DailySystemLogic.startAutoBattleType);
    notifyListeners();
    save();
    return true;
  }

  void _resolveActiveAutoBattle() {
    var battle = _state.activeAutoBattle;
    if (battle == null) return;

    final boss = BossBattleLogic.bossById(battle.bossId);
    if (boss == null) {
      _finishActiveAutoBattle(
        battle,
        bossName: 'Boss',
        reason: AutoBattleCompletionReason.defeated,
        finalHp: 0,
      );
      return;
    }

    final owned = ownedAnimal(
      battle.animalId,
      mutationId: battle.mutationId,
      isProtected: battle.isProtected,
    );
    if (owned == null) {
      _finishActiveAutoBattle(
        battle,
        bossName: boss.name,
        reason: AutoBattleCompletionReason.defeated,
        finalHp: 0,
      );
      return;
    }

    final fightDuration = Duration(seconds: boss.autoBattleSeconds);
    var progress = _state.questProgress;
    var coins = _state.coins;
    var tokens = _state.battleTokens;
    final wins = Map<String, int>.from(_state.bossWins);
    var changed = false;
    AutoBattleCompletionSummary? completion;
    var bossDefeatsForDailyQuest = 0;

    while (battle != null) {
      if (battle.battlesWon >= BossBattleLogic.maxAutoBattleDefeats) {
        completion = _autoBattleCompletionSummary(
          battle,
          boss,
          AutoBattleCompletionReason.capReached,
        );
        battle = null;
        changed = true;
        break;
      }

      final elapsed = DateTime.now().difference(battle.lastResolvedAt);
      if (elapsed < fightDuration) break;

      progress = progress.copyWith(
        totalBossBattlesStarted: progress.totalBossBattlesStarted + 1,
      );
      changed = true;

      final result = BossBattleLogic.simulate(
        boss: boss,
        fighter: owned,
        fighterDisplayName: battle.fighterDisplayName,
        random: _random,
        startingPlayerHp: battle.currentHp,
      );

      if (result.won) {
        progress = _questProgressAfterBossWin(
          progress,
          boss.id,
          boss.battleTokenReward,
        );
        coins += boss.coinReward;
        tokens += boss.battleTokenReward;
        wins[boss.id] = (wins[boss.id] ?? 0) + 1;
        bossDefeatsForDailyQuest++;

        battle = battle.copyWith(
          currentHp: result.finalPlayerHp,
          battlesWon: battle.battlesWon + 1,
          totalCoinsEarned: battle.totalCoinsEarned + boss.coinReward,
          totalBattleTokensEarned:
              battle.totalBattleTokensEarned + boss.battleTokenReward,
          lastResolvedAt: battle.lastResolvedAt.add(fightDuration),
        );

        if (result.finalPlayerHp <= 0) {
          completion = _autoBattleCompletionSummary(
            battle,
            boss,
            AutoBattleCompletionReason.defeated,
            finalHp: 0,
          );
          battle = null;
          break;
        }

        if (battle.battlesWon >= BossBattleLogic.maxAutoBattleDefeats) {
          completion = _autoBattleCompletionSummary(
            battle,
            boss,
            AutoBattleCompletionReason.capReached,
          );
          battle = null;
          break;
        }
      } else {
        progress = progress.copyWith(
          totalBossBattlesLost: progress.totalBossBattlesLost + 1,
        );
        completion = _autoBattleCompletionSummary(
          battle.copyWith(currentHp: 0),
          boss,
          AutoBattleCompletionReason.defeated,
          finalHp: 0,
        );
        battle = null;
        break;
      }
    }

    if (!changed) return;

    _state = _state.copyWith(
      questProgress: progress,
      coins: coins,
      battleTokens: tokens,
      bossWins: wins,
      activeAutoBattle: battle,
      clearActiveAutoBattle: battle == null,
    );

    if (bossDefeatsForDailyQuest > 0) {
      _incrementDailyQuest(
        DailySystemLogic.defeatBossType,
        amount: bossDefeatsForDailyQuest,
      );
    }

    if (completion != null) {
      _pendingAutoBattleCompletion = completion;
    }

    _refreshQuestNotifications();
    notifyListeners();
    save();
  }

  void _finishActiveAutoBattle(
    ActiveAutoBattle battle, {
    required String bossName,
    required AutoBattleCompletionReason reason,
    required int finalHp,
  }) {
    _pendingAutoBattleCompletion = AutoBattleCompletionSummary(
      fighterDisplayName: battle.fighterDisplayName,
      bossName: bossName,
      battlesWon: battle.battlesWon,
      totalCoinsEarned: battle.totalCoinsEarned,
      totalBattleTokensEarned: battle.totalBattleTokensEarned,
      finalHp: finalHp,
      reason: reason,
    );
    _state = _state.copyWith(clearActiveAutoBattle: true);
    notifyListeners();
    save();
  }

  AutoBattleCompletionSummary _autoBattleCompletionSummary(
    ActiveAutoBattle battle,
    BossBattleDefinition boss,
    AutoBattleCompletionReason reason, {
    int? finalHp,
  }) {
    return AutoBattleCompletionSummary(
      fighterDisplayName: battle.fighterDisplayName,
      bossName: boss.name,
      battlesWon: battle.battlesWon,
      totalCoinsEarned: battle.totalCoinsEarned,
      totalBattleTokensEarned: battle.totalBattleTokensEarned,
      finalHp: finalHp ?? battle.currentHp,
      reason: reason,
    );
  }

  void devCompleteActiveAutoBattle() {
    final battle = _state.activeAutoBattle;
    if (battle == null) return;
    final boss = BossBattleLogic.bossById(battle.bossId);
    _finishActiveAutoBattle(
      battle,
      bossName: boss?.name ?? 'Boss',
      reason: AutoBattleCompletionReason.capReached,
      finalHp: battle.currentHp,
    );
  }

  void devClearActiveAutoBattle() {
    if (_state.activeAutoBattle == null) return;
    _state = _state.copyWith(clearActiveAutoBattle: true);
    notifyListeners();
    save();
  }

  void devAdvanceActiveAutoBattleFight() {
    final battle = _state.activeAutoBattle;
    if (battle == null) return;
    final boss = BossBattleLogic.bossById(battle.bossId);
    if (boss == null) return;
    _state = _state.copyWith(
      activeAutoBattle: battle.copyWith(
        lastResolvedAt: battle.lastResolvedAt.subtract(
          Duration(seconds: boss.autoBattleSeconds),
        ),
      ),
    );
    _resolveActiveAutoBattle();
  }

  /// Simulates a boss battle without granting rewards.
  BossBattleResult? simulateBossBattle({
    required String bossId,
    required String animalId,
    required String mutationId,
    required bool isProtected,
  }) {
    final boss = BossBattleLogic.bossById(bossId);
    if (boss == null) return null;
    if (!BossBattleLogic.isBossUnlocked(boss, _state)) return null;

    final owned = ownedAnimal(
      animalId,
      mutationId: mutationId,
      isProtected: isProtected,
    );
    if (owned == null) return null;

    final animal = GameData.animalById(animalId);
    if (animal == null) return null;

    final mutation =
        GameData.mutationById(mutationId) ?? GameData.mutations.first;
    final displayName = mutation.fullName(animal);

    return BossBattleLogic.simulate(
      boss: boss,
      fighter: owned,
      fighterDisplayName: displayName,
      random: _random,
    );
  }

  void recordBossBattleStarted() {
    _state = _state.copyWith(
      questProgress: _state.questProgress.copyWith(
        totalBossBattlesStarted:
            _state.questProgress.totalBossBattlesStarted + 1,
      ),
    );
    _incrementDailyQuest(DailySystemLogic.startManualBattleType);
    _refreshQuestNotifications();
    notifyListeners();
    save();
  }

  PlayerState _migrateEliteRewardAnimals(PlayerState state) {
    final animals = state.ownedAnimals.map((owned) {
      if (!GameData.bossVictoryRewardAnimalIds.contains(owned.animalId)) {
        return owned;
      }
      return owned.copyWith(
        isEliteReward: true,
        isProtected: true,
        isSecretReward: false,
      );
    }).toList();
    return state.copyWith(ownedAnimals: animals);
  }

  BossRewardGrant? grantBossRewardAnimal(
    String animalId, {
    String? mutationId,
  }) {
    final animal = GameData.animalById(animalId);
    if (animal == null) return null;

    final isElite = GameData.bossVictoryRewardAnimalIds.contains(animalId);
    final Mutation mutation;
    if (isElite) {
      if (mutationId != null) {
        mutation =
            GameData.mutationById(mutationId) ?? GameData.mutations.first;
      } else {
        mutation = LuckLogic.rollNormalMutation(_random, _state.luckLevel);
      }
    } else {
      mutation = GameData.mutations.first;
    }

    final updatedAnimals = List<OwnedAnimal>.from(_state.ownedAnimals);
    final existingIndex = isElite
        ? _indexOfEliteRewardStack(updatedAnimals, animalId, mutation.id)
        : _indexOfOwnedStack(
            updatedAnimals,
            animalId,
            mutation.id,
            isProtected: false,
          );

    if (existingIndex >= 0) {
      final existing = updatedAnimals[existingIndex];
      updatedAnimals[existingIndex] = existing.copyWith(
        quantity: existing.quantity + 1,
        isProtected: isElite ? true : existing.isProtected,
        isEliteReward: isElite ? true : existing.isEliteReward,
        isSecretReward: isElite ? false : existing.isSecretReward,
      );
    } else {
      updatedAnimals.add(
        OwnedAnimal(
          animalId: animalId,
          quantity: 1,
          level: 1,
          mutationId: mutation.id,
          isProtected: isElite,
          isEliteReward: isElite,
        ),
      );
    }

    _state = _state.copyWith(ownedAnimals: updatedAnimals);
    return BossRewardGrant(animal: animal, mutation: mutation);
  }

  int _indexOfEliteRewardStack(
    List<OwnedAnimal> animals,
    String animalId,
    String mutationId,
  ) {
    final eliteIndex = _indexOfOwnedStack(
      animals,
      animalId,
      mutationId,
      isProtected: true,
    );
    if (eliteIndex >= 0) return eliteIndex;

    for (var i = 0; i < animals.length; i++) {
      final owned = animals[i];
      if (owned.animalId == animalId &&
          owned.mutationId == mutationId &&
          !owned.isProtected) {
        return i;
      }
    }
    return -1;
  }

  /// Applies win rewards and records battle quest progress after animation.
  BossRewardGrant? applyBossBattleRewards(
    String bossId,
    BossBattleResult result, {
    ManualBattleMode mode = ManualBattleMode.normal,
    String? rewardAnimalId,
    bool isManualBattle = true,
    int livesLostThisBattle = 0,
  }) {
    var progress = _state.questProgress;
    if (result.won) {
      progress = _questProgressAfterBossWin(
        progress,
        bossId,
        result.battleTokenReward,
      );
    } else {
      progress = progress.copyWith(
        totalBossBattlesLost: progress.totalBossBattlesLost + 1,
      );
    }

    _state = _state.copyWith(questProgress: progress);

    if (!result.won) {
      _refreshQuestNotifications();
      notifyListeners();
      save();
      return null;
    }

    final wins = Map<String, int>.from(_state.bossWins);
    wins[bossId] = (wins[bossId] ?? 0) + 1;
    var hardPhaseWins = _state.hardPhaseWins;
    var nightmareWins = _state.nightmareWins;
    if (mode == ManualBattleMode.hard) {
      hardPhaseWins = Map<String, int>.from(hardPhaseWins);
      hardPhaseWins[bossId] = (hardPhaseWins[bossId] ?? 0) + 1;
    } else if (mode == ManualBattleMode.nightmare) {
      nightmareWins = Map<String, int>.from(nightmareWins);
      nightmareWins[bossId] = (nightmareWins[bossId] ?? 0) + 1;
    }
    BossRewardGrant? grant;
    if (rewardAnimalId != null) {
      grant = grantBossRewardAnimal(rewardAnimalId);
    }

    final bossDef = BossData.bossById(bossId);
    var eggShardReward = 0;
    if (bossDef != null && bossDef.eggShardReward > 0) {
      eggShardReward = bossDef.eggShardReward;
    }

    var shadowPhoenixFlawlessWin = _state.shadowPhoenixFlawlessWin;
    if (isManualBattle &&
        bossId == 'shadow_phoenix' &&
        livesLostThisBattle == 0) {
      shadowPhoenixFlawlessWin = true;
    }

    _state = _state.copyWith(
      coins: _state.coins + result.coinReward,
      battleTokens: _state.battleTokens + result.battleTokenReward,
      eggShards: _state.eggShards + eggShardReward,
      shadowPhoenixFlawlessWin: shadowPhoenixFlawlessWin,
      bossWins: wins,
      hardPhaseWins: hardPhaseWins,
      nightmareWins: nightmareWins,
    );
    _incrementDailyQuest(DailySystemLogic.defeatBossType);
    if (isManualBattle) {
      _incrementDailyQuest(DailySystemLogic.winManualBattleType);
    }
    _refreshQuestNotifications();
    notifyListeners();
    save();
    return grant;
  }

  /// Applies finisher slash bonus coins/tokens once after the 5-second slash window.
  void applyManualFinisherBonus({required int coins, required int tokens}) {
    if (coins <= 0 && tokens <= 0) return;

    var progress = _state.questProgress;
    if (tokens > 0) {
      progress = progress.copyWith(
        totalBattleTokensEarned: progress.totalBattleTokensEarned + tokens,
      );
    }

    _state = _state.copyWith(
      coins: _state.coins + coins,
      battleTokens: _state.battleTokens + tokens,
      questProgress: progress,
    );
    _refreshQuestNotifications();
    notifyListeners();
    save();
  }

  /// Records one completed Arena match and grants its calculated reward.
  void applyArenaResult({required bool won, required ArenaReward reward}) {
    final nextStreak = won ? _state.arenaWinStreak + 1 : 0;
    var progress = _state.questProgress;
    if (reward.battleTokens > 0) {
      progress = progress.copyWith(
        totalBattleTokensEarned:
            progress.totalBattleTokensEarned + reward.battleTokens,
      );
    }
    _state = _state.copyWith(
      coins: _state.coins + reward.coins,
      battleTokens: _state.battleTokens + reward.battleTokens,
      questProgress: progress,
      arenaRating: max(0, _state.arenaRating + reward.ratingChange),
      arenaWins: _state.arenaWins + (won ? 1 : 0),
      arenaLosses: _state.arenaLosses + (won ? 0 : 1),
      arenaWinStreak: nextStreak,
      arenaBestStreak: max(_state.arenaBestStreak, nextStreak),
    );
    _refreshQuestNotifications();
    notifyListeners();
    save();
  }

  QuestProgress _questProgressAfterBossWin(
    QuestProgress progress,
    String bossId,
    int battleTokenReward,
  ) {
    progress = progress.copyWith(
      totalBossBattlesWon: progress.totalBossBattlesWon + 1,
      totalBattleTokensEarned:
          progress.totalBattleTokensEarned + battleTokenReward,
    );
    switch (bossId) {
      case 'slime_boss':
        progress = progress.copyWith(slimeBossWins: progress.slimeBossWins + 1);
      case 'egg_golem':
        progress = progress.copyWith(eggGolemWins: progress.eggGolemWins + 1);
      case 'shadow_rooster':
        progress = progress.copyWith(
          shadowRoosterWins: progress.shadowRoosterWins + 1,
        );
    }
    return progress;
  }

  /// Runs an auto-battle and applies rewards immediately (testing helper).
  BossBattleResult? fightBoss({
    required String bossId,
    required String animalId,
    required String mutationId,
    required bool isProtected,
  }) {
    final result = simulateBossBattle(
      bossId: bossId,
      animalId: animalId,
      mutationId: mutationId,
      isProtected: isProtected,
    );
    if (result == null) return null;
    recordBossBattleStarted();
    applyBossBattleRewards(bossId, result, isManualBattle: false);
    return result;
  }

  void devAddBattleTokens(int amount) {
    if (amount <= 0) return;
    _state = _state.copyWith(battleTokens: _state.battleTokens + amount);
    notifyListeners();
    save();
  }

  void devResetBattleTokens() {
    _state = _state.copyWith(battleTokens: 0);
    notifyListeners();
    save();
  }

  void devMaxBattleUpgrades() {
    _state = _state.copyWith(
      battleHomingLevel: BattleUpgradeLogic.maxLevel,
      battleShotSpeedLevel: BattleUpgradeLogic.maxLevel,
      battleExtraLifeLevel: BattleUpgradeLogic.extraLifeMaxLevel,
    );
    notifyListeners();
    save();
  }

  void devResetBattleUpgrades() {
    _state = _state.copyWith(
      battleHomingLevel: BattleUpgradeLogic.minLevel,
      battleShotSpeedLevel: BattleUpgradeLogic.minLevel,
      battleExtraLifeLevel: BattleUpgradeLogic.minLevel,
    );
    notifyListeners();
    save();
  }

  void devResetDailyRewardClaim() {
    _dailyRewardPopupShownThisSession = false;
    _state = _state.copyWith(
      clearLastDailyRewardClaimDate: true,
      clearLastDailyRewardPopupDismissDate: true,
      dailyRewardStreak: 0,
    );
    notifyListeners();
    save();
  }

  void devResetDailyQuests() {
    _rerollDailyQuestsForToday();
    notifyListeners();
    save();
  }

  void devRerollDailyQuests({int? rerollSalt}) {
    _rerollDailyQuestsForToday(rerollSalt: rerollSalt);
    notifyListeners();
    save();
  }

  void devCompleteDailyQuests() {
    _refreshDailyQuestsIfNeeded();
    _state = _state.copyWith(
      dailyQuests: _state.dailyQuests
          .map((quest) => quest.copyWith(progress: quest.target))
          .toList(),
    );
    notifyListeners();
    save();
  }

  void devUnlockBossMutation() {
    _state = _state.copyWith(bossMutationUnlocked: true);
    _refreshQuestNotifications();
    notifyListeners();
    save();
  }

  void devAddBossMutationAnimal({String animalId = 'chicken'}) {
    final updated = List<OwnedAnimal>.from(_state.ownedAnimals);
    final existingIndex = _indexOfOwnedStack(
      updated,
      animalId,
      'boss',
      isProtected: false,
    );
    if (existingIndex >= 0) {
      final existing = updated[existingIndex];
      updated[existingIndex] = existing.copyWith(
        quantity: existing.quantity + 1,
      );
    } else {
      updated.add(
        OwnedAnimal(animalId: animalId, quantity: 1, mutationId: 'boss'),
      );
    }
    _state = _state.copyWith(ownedAnimals: updated);
    notifyListeners();
    save();
  }

  bool canUnlockBossMutation() =>
      !_state.bossMutationUnlocked &&
      _state.battleTokens >= GameData.unlockBossMutationCost;

  bool unlockBossMutation() {
    if (_state.bossMutationUnlocked) return false;
    if (_state.battleTokens < GameData.unlockBossMutationCost) return false;
    _state = _state.copyWith(
      battleTokens: _state.battleTokens - GameData.unlockBossMutationCost,
      bossMutationUnlocked: true,
    );
    _refreshQuestNotifications();
    notifyListeners();
    save();
    return true;
  }

  bool canApplyBossMutation() =>
      _state.battleTokens >= GameData.applyBossMutationCost;

  bool applyBossMutation(OwnedAnimal source) {
    if (_state.battleTokens < GameData.applyBossMutationCost) return false;
    if (source.mutationId == 'boss') return false;
    if (source.quantity < 1) return false;
    if (isOwnedStackAutoBattling(source)) return false;

    final sourceIndex = _state.ownedAnimals.indexWhere(
      (owned) =>
          owned.animalId == source.animalId &&
          owned.mutationId == source.mutationId &&
          owned.isProtected == source.isProtected &&
          owned.level == source.level,
    );
    if (sourceIndex < 0) return false;

    final stack = _state.ownedAnimals[sourceIndex];
    final updated = List<OwnedAnimal>.from(_state.ownedAnimals);

    if (stack.quantity <= 1) {
      updated.removeAt(sourceIndex);
    } else {
      updated[sourceIndex] = stack.copyWith(quantity: stack.quantity - 1);
    }

    final bossIndex = updated.indexWhere(
      (owned) =>
          owned.animalId == stack.animalId &&
          owned.mutationId == 'boss' &&
          owned.isProtected == stack.isProtected &&
          owned.level == stack.level,
    );
    if (bossIndex >= 0) {
      final bossStack = updated[bossIndex];
      updated[bossIndex] = bossStack.copyWith(quantity: bossStack.quantity + 1);
    } else {
      updated.add(
        OwnedAnimal(
          animalId: stack.animalId,
          quantity: 1,
          level: stack.level,
          mutationId: 'boss',
          isProtected: stack.isProtected,
          isSecretReward: stack.isSecretReward,
          isEliteReward: stack.isEliteReward,
        ),
      );
    }

    _state = _state.copyWith(
      ownedAnimals: updated,
      battleTokens: _state.battleTokens - GameData.applyBossMutationCost,
      questProgress: _state.questProgress.copyWith(
        totalBossMutationsApplied:
            _state.questProgress.totalBossMutationsApplied + 1,
      ),
    );
    _refreshQuestNotifications();
    notifyListeners();
    save();
    return true;
  }

  bool canFuseAnimals(OwnedAnimal source) => AnimalFusionLogic.canFuseStack(
    source,
    inBattle: isOwnedStackAutoBattling(source),
  );

  /// Combines 2 copies of the same animal/mutation with an 80% success chance.
  AnimalFusionOutcome? fuseAnimals(OwnedAnimal source, {Random? random}) {
    if (!canFuseAnimals(source)) return null;

    final sourceIndex = _indexOfOwnedStack(
      _state.ownedAnimals,
      source.animalId,
      source.mutationId,
      isProtected: source.isProtected,
    );
    if (sourceIndex < 0) return null;

    final stack = _state.ownedAnimals[sourceIndex];
    if (stack.quantity < AnimalFusionLogic.inputQuantity) return null;

    final animal = GameData.animalById(stack.animalId);
    if (animal == null) return null;

    final inputMutation =
        GameData.mutationById(stack.mutationId) ?? GameData.mutations.first;
    final inputDisplayName = inputMutation.fullName(animal);

    final rng = random ?? Random();
    final roll = AnimalFusionLogic.rollFusion(stack.mutationId, rng);

    final updated = List<OwnedAnimal>.from(_state.ownedAnimals);
    final remaining = stack.quantity - AnimalFusionLogic.inputQuantity;
    if (remaining <= 0) {
      updated.removeAt(sourceIndex);
    } else {
      updated[sourceIndex] = stack.copyWith(quantity: remaining);
    }

    String? resultMutationId;
    String? displayName;
    var wasLucky = false;

    if (roll.succeeded && roll.resultMutationId != null) {
      final outputMutationId = roll.resultMutationId!;
      wasLucky = roll.wasLucky;
      final resultMutation =
          GameData.mutationById(outputMutationId) ?? GameData.mutations.first;
      displayName = resultMutation.fullName(animal);
      resultMutationId = outputMutationId;

      final outputIndex = _indexOfOwnedStack(
        updated,
        stack.animalId,
        outputMutationId,
        isProtected: false,
      );
      if (outputIndex >= 0) {
        final outputStack = updated[outputIndex];
        updated[outputIndex] = outputStack.copyWith(
          quantity: outputStack.quantity + 1,
          sourceEggId: _mergeSourceEggId(
            outputStack.sourceEggId,
            stack.sourceEggId,
          ),
        );
      } else {
        updated.add(
          OwnedAnimal(
            animalId: stack.animalId,
            quantity: 1,
            level: 1,
            mutationId: outputMutationId,
            sourceEggId: stack.sourceEggId,
          ),
        );
      }
    }

    var progress = _state.questProgress.copyWith(
      totalFusionAttempts: _state.questProgress.totalFusionAttempts + 1,
    );
    if (roll.succeeded) {
      progress = progress.copyWith(
        totalSuccessfulFusions: progress.totalSuccessfulFusions + 1,
      );
      if (wasLucky) {
        progress = progress.copyWith(
          totalLuckyFusions: progress.totalLuckyFusions + 1,
        );
      }
    } else {
      progress = progress.copyWith(
        totalFailedFusions: progress.totalFailedFusions + 1,
      );
    }

    _state = _state.copyWith(ownedAnimals: updated, questProgress: progress);
    _incrementDailyQuest(DailySystemLogic.attemptFusionType);
    if (roll.succeeded) {
      _incrementDailyQuest(DailySystemLogic.successfulFusionType);
      if (wasLucky) {
        _incrementDailyQuest(DailySystemLogic.luckyFusionType);
      }
    } else {
      _incrementDailyQuest(DailySystemLogic.failedFusionType);
    }
    _refreshQuestNotifications();
    notifyListeners();
    save();

    return AnimalFusionOutcome(
      animalId: stack.animalId,
      inputMutationId: stack.mutationId,
      succeeded: roll.succeeded,
      inputDisplayName: inputDisplayName,
      resultMutationId: resultMutationId,
      wasLucky: wasLucky,
      displayName: displayName,
    );
  }

  void devAddFusionTestAnimals({
    String animalId = 'chicken',
    String mutationId = 'none',
    int quantity = 2,
  }) {
    final updated = List<OwnedAnimal>.from(_state.ownedAnimals);
    final existingIndex = _indexOfOwnedStack(
      updated,
      animalId,
      mutationId,
      isProtected: false,
    );
    if (existingIndex >= 0) {
      final existing = updated[existingIndex];
      updated[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      updated.add(
        OwnedAnimal(
          animalId: animalId,
          quantity: quantity,
          mutationId: mutationId,
        ),
      );
    }
    _state = _state.copyWith(ownedAnimals: updated);
    notifyListeners();
    save();
  }

  void devResetFusionTestAnimals({String animalId = 'chicken'}) {
    final updated = _state.ownedAnimals
        .where(
          (owned) =>
              owned.animalId != animalId ||
              owned.isProtected ||
              owned.isEliteReward ||
              owned.isSecretReward ||
              (owned.mutationId != 'none' && owned.mutationId != 'golden'),
        )
        .toList();
    _state = _state.copyWith(ownedAnimals: updated);
    notifyListeners();
    save();
  }

  int battleHomingUpgradeCost() =>
      BattleUpgradeLogic.homingUpgradeCost(_state.battleHomingLevel);

  int battleShotSpeedUpgradeCost() =>
      BattleUpgradeLogic.shotSpeedUpgradeCost(_state.battleShotSpeedLevel);

  bool upgradeBattleHoming() {
    if (_state.battleHomingLevel >= battleHomingMaxLevel) return false;
    final cost = battleHomingUpgradeCost();
    if (_state.battleTokens < cost) return false;
    _state = _state.copyWith(
      battleTokens: _state.battleTokens - cost,
      battleHomingLevel: _state.battleHomingLevel + 1,
    );
    _incrementDailyQuest(DailySystemLogic.buyBattleUpgradeType);
    notifyListeners();
    save();
    return true;
  }

  bool upgradeBattleShotSpeed() {
    if (_state.battleShotSpeedLevel >= battleShotSpeedMaxLevel) return false;
    final cost = battleShotSpeedUpgradeCost();
    if (_state.battleTokens < cost) return false;
    _state = _state.copyWith(
      battleTokens: _state.battleTokens - cost,
      battleShotSpeedLevel: _state.battleShotSpeedLevel + 1,
    );
    _incrementDailyQuest(DailySystemLogic.buyBattleUpgradeType);
    notifyListeners();
    save();
    return true;
  }

  int battleExtraLifeUpgradeCost() =>
      BattleUpgradeLogic.extraLifeUpgradeCost(_state.battleExtraLifeLevel);

  bool upgradeBattleExtraLife() {
    if (_state.battleExtraLifeLevel >= battleExtraLifeMaxLevel) {
      return false;
    }
    final cost = battleExtraLifeUpgradeCost();
    if (_state.battleTokens < cost) return false;
    _state = _state.copyWith(
      battleTokens: _state.battleTokens - cost,
      battleExtraLifeLevel: _state.battleExtraLifeLevel + 1,
    );
    _incrementDailyQuest(DailySystemLogic.buyBattleUpgradeType);
    notifyListeners();
    save();
    return true;
  }

  bool purchaseBattleLimitBreak() {
    final level = _state.battleLimitBreakLevel;
    if (level >= EggShardLogic.battleLimitBreakMaxLevel) return false;
    final cost = EggShardLogic.battleLimitBreakCost(level);
    if (_state.eggShards < cost) return false;
    _state = _state.copyWith(
      eggShards: _state.eggShards - cost,
      battleLimitBreakLevel: level + 1,
    );
    notifyListeners();
    save();
    return true;
  }

  bool purchaseExtraLifeLimitBreak() {
    final level = _state.extraLifeLimitBreakLevel;
    if (level >= EggShardLogic.extraLifeLimitBreakMaxLevel) return false;
    final cost = EggShardLogic.extraLifeLimitBreakCost;
    if (_state.eggShards < cost) return false;
    _state = _state.copyWith(
      eggShards: _state.eggShards - cost,
      extraLifeLimitBreakLevel: level + 1,
    );
    notifyListeners();
    save();
    return true;
  }

  bool purchaseEggRebirthReduction() {
    final level = _state.eggRebirthReductionLevel;
    if (level >= EggShardLogic.eggRebirthReductionMaxLevel) return false;
    final cost = EggShardLogic.eggRebirthReductionCost(level);
    if (_state.eggShards < cost) return false;
    _state = _state.copyWith(
      eggShards: _state.eggShards - cost,
      eggRebirthReductionLevel: level + 1,
    );
    notifyListeners();
    save();
    return true;
  }

  bool purchaseCustomSpriteCanvas() {
    final level = _state.customSpriteCanvasTier;
    if (level >= EggShardLogic.customSpriteCanvasMaxLevel) return false;
    final cost = EggShardLogic.customSpriteCanvasCost;
    if (_state.eggShards < cost) return false;
    _state = _state.copyWith(
      eggShards: _state.eggShards - cost,
      customSpriteCanvasTier: level + 1,
    );
    notifyListeners();
    save();
    return true;
  }

  void devAddEggShards(int amount) {
    if (amount <= 0) return;
    _state = _state.copyWith(eggShards: _state.eggShards + amount);
    notifyListeners();
    save();
  }

  void devUnlockRottenShellRequirements() {
    final wins = Map<String, int>.from(_state.bossWins);
    for (final id in EggShardLogic.prerequisiteBossIds) {
      wins[id] = max(wins[id] ?? 0, 1);
    }
    _state = _state.copyWith(bossWins: wins, shadowPhoenixFlawlessWin: true);
    notifyListeners();
    save();
  }

  void devSetShadowPhoenixFlawlessWin(bool value) {
    _state = _state.copyWith(shadowPhoenixFlawlessWin: value);
    notifyListeners();
    save();
  }

  void devResetEggShardUpgrades() {
    _state = _state.copyWith(
      battleLimitBreakLevel: 0,
      extraLifeLimitBreakLevel: 0,
      eggRebirthReductionLevel: 0,
      customSpriteCanvasTier: 0,
    );
    notifyListeners();
    save();
  }

  void devResetBossWins() {
    _state = _state.copyWith(bossWins: const {});
    notifyListeners();
    save();
  }

  /// Applies the one-time Secret Reward Badge to an owned animal stack.
  /// Returns the display name on success, or null if unavailable.
  String? applySecretRewardBadge({
    required String animalId,
    required String mutationId,
    required bool isProtected,
  }) {
    if (_state.secretSpaceEggClaimed) return null;

    final animal = GameData.animalById(animalId);
    if (animal == null) return null;

    final updatedAnimals = List<OwnedAnimal>.from(_state.ownedAnimals);
    final index = _indexOfOwnedStack(
      updatedAnimals,
      animalId,
      mutationId,
      isProtected: isProtected,
    );
    if (index < 0) return null;

    final stack = updatedAnimals[index];
    if (stack.isSecretReward || stack.isEliteReward) return null;

    updatedAnimals[index] = stack.copyWith(
      isProtected: true,
      isSecretReward: true,
    );

    final mutation =
        GameData.mutationById(mutationId) ?? GameData.mutations.first;
    _state = _state.copyWith(
      ownedAnimals: updatedAnimals,
      secretSpaceEggClaimed: true,
    );
    _refreshQuestNotifications();
    notifyListeners();
    save();
    return mutation.fullName(animal);
  }

  /// Legacy void-egg claim — retired; badge flow replaces this reward.
  @Deprecated('Use applySecretRewardBadge instead')
  HatchResult? claimSecretVoidEggReward() => null;

  /// Legacy alias — secret reward is now a badge applied to one animal.
  @Deprecated('Use applySecretRewardBadge instead')
  HatchResult? claimSecretSpaceEggReward() => null;

  /// Debug: allow claiming/applying the secret badge again.
  void devResetSecretRewardBadgeClaim() {
    _state = _state.copyWith(secretSpaceEggClaimed: false);
    notifyListeners();
    save();
  }

  /// Debug: mark badge as unclaimed so it can be applied again in testing.
  void devGrantSecretRewardBadge() => devResetSecretRewardBadgeClaim();

  /// Test helper for injecting owned animals without changing hatch odds.
  @visibleForTesting
  void devSetOwnedAnimalsForTesting(List<OwnedAnimal> animals) {
    _state = _state.copyWith(ownedAnimals: animals);
    notifyListeners();
    save();
  }

  /// One-time reference overlay unlock cost for an animal.
  int referenceOverlayCostForAnimal(String animalId, {int? displayedReward}) {
    return SpriteRatingLogic.referenceOverlayCostForAnimal(
      animalId: animalId,
      currentCoins: _state.coins,
      displayedReward: displayedReward,
    );
  }

  bool canAffordReferenceOverlay(String animalId, {int? displayedReward}) {
    final cost = referenceOverlayCostForAnimal(
      animalId,
      displayedReward: displayedReward,
    );
    return cost > 0 && _state.coins >= cost;
  }

  /// Spends coins for a reference overlay unlock without affecting lifetime earnings.
  Future<bool> unlockReferenceOverlay(
    String animalId,
    SpriteReferenceOverlayService overlayService, {
    int? displayedReward,
  }) async {
    if (overlayService.isUnlocked(animalId)) return true;

    final cost = referenceOverlayCostForAnimal(
      animalId,
      displayedReward: displayedReward,
    );
    if (cost <= 0 || _state.coins < cost) return false;

    _state = _state.copyWith(coins: _state.coins - cost);
    notifyListeners();
    save();
    await overlayService.unlock(animalId);
    recordReferenceOverlayUnlocked();
    return true;
  }

  /// Records a successful Rate Sprite (Beta) rating on a supported animal.
  /// Returns true when this sprite version was newly counted for quest progress.
  bool recordSpriteRated({
    required String animalId,
    required int score,
    required String spriteHash,
  }) {
    final ratingKey = SpriteRatingLogic.questRatingKey(animalId, spriteHash);
    final alreadyCounted = _state.questProgress.questCountedRatedSpriteKeys
        .contains(ratingKey);

    var progress = _state.questProgress.copyWith(
      bestSpriteRatingScore: max(
        _state.questProgress.bestSpriteRatingScore,
        score,
      ),
    );

    if (!alreadyCounted) {
      progress = progress.copyWith(
        totalSpritesRated: progress.totalSpritesRated + 1,
        questCountedRatedSpriteKeys: [
          ...progress.questCountedRatedSpriteKeys,
          ratingKey,
        ],
      );
    }

    if (score == 10) {
      if (!progress.perfectRatedSpriteKeys.contains(ratingKey)) {
        progress = progress.copyWith(
          totalPerfectSpriteRatings: progress.totalPerfectSpriteRatings + 1,
          perfectRatedSpriteKeys: [
            ...progress.perfectRatedSpriteKeys,
            ratingKey,
          ],
        );
      }
    }

    _state = _state.copyWith(questProgress: progress);
    _refreshQuestNotifications();
    notifyListeners();
    save();
    return !alreadyCounted;
  }

  /// Whether quest progress already counted this exact sprite drawing.
  bool isSpriteRatingCountedForQuest(String animalId, String spriteHash) {
    return _state.questProgress.questCountedRatedSpriteKeys.contains(
      SpriteRatingLogic.questRatingKey(animalId, spriteHash),
    );
  }

  /// Records a successful sprite rating reward claim (not a duplicate).
  void recordSpriteRatingRewardClaimed() {
    _state = _state.copyWith(
      questProgress: _state.questProgress.copyWith(
        totalSpriteRatingRewardsClaimed:
            _state.questProgress.totalSpriteRatingRewardsClaimed + 1,
      ),
    );
    _refreshQuestNotifications();
    notifyListeners();
    save();
  }

  /// Records a newly purchased reference overlay unlock.
  void recordReferenceOverlayUnlocked() {
    _state = _state.copyWith(
      questProgress: _state.questProgress.copyWith(
        totalReferenceOverlaysUnlocked:
            _state.questProgress.totalReferenceOverlaysUnlocked + 1,
      ),
    );
    _refreshQuestNotifications();
    notifyListeners();
    save();
  }

  void recordCustomEggCreated() {
    _state = _state.copyWith(
      questProgress: _state.questProgress.copyWith(
        totalCustomEggsCreated: _state.questProgress.totalCustomEggsCreated + 1,
      ),
    );
    _refreshQuestNotifications();
    notifyListeners();
    save();
  }

  void devAddEggsHatched(int count) {
    if (count <= 0) return;
    _state = _state.copyWith(
      questProgress: _state.questProgress.copyWith(
        totalEggsHatched: _state.questProgress.totalEggsHatched + count,
      ),
    );
    _refreshQuestNotifications();
    notifyListeners();
    save();
  }

  void devAddEggMasteryHatches({int count = 10}) {
    if (count <= 0) return;
    final updated = Map<String, EggMasteryProgress>.from(_state.eggMastery);
    for (final egg in [...GameData.eggs, ...GameData.battleEggs]) {
      final current = updated[egg.id] ?? EggMasteryProgress(eggId: egg.id);
      updated[egg.id] = current
          .copyWith(hatchCount: current.hatchCount + count)
          .normalized();
    }
    _state = _state.copyWith(eggMastery: updated);
    notifyListeners();
    save();
  }

  void devMaxAllEggMastery() {
    final updated = <String, EggMasteryProgress>{};
    for (final egg in [...GameData.eggs, ...GameData.battleEggs]) {
      updated[egg.id] = EggMasteryProgress(
        eggId: egg.id,
        hatchCount: EggMasteryLogic.thresholds.last,
        masteryLevel: EggMasteryLogic.maxLevel,
      );
    }
    _state = _state.copyWith(eggMastery: updated);
    notifyListeners();
    save();
  }

  void devResetEggMastery() {
    _state = _state.copyWith(eggMastery: const {});
    _pendingMasteryNotifications.clear();
    notifyListeners();
    save();
  }

  void devAddMutationHatched({String mutationId = 'golden'}) {
    var progress = _state.questProgress.copyWith(
      totalMutationsHatched: _state.questProgress.totalMutationsHatched + 1,
    );
    switch (mutationId) {
      case 'golden':
        progress = progress.copyWith(
          totalGoldenHatched: progress.totalGoldenHatched + 1,
        );
      case 'rainbow':
        progress = progress.copyWith(
          totalRainbowHatched: progress.totalRainbowHatched + 1,
        );
      case 'shadow':
        progress = progress.copyWith(
          totalShadowHatched: progress.totalShadowHatched + 1,
        );
    }
    _state = _state.copyWith(questProgress: progress);
    _refreshQuestNotifications();
    notifyListeners();
    save();
  }

  void devAddAnimalUpgrade() {
    _state = _state.copyWith(
      questProgress: _state.questProgress.copyWith(
        totalAnimalUpgrades: _state.questProgress.totalAnimalUpgrades + 1,
      ),
    );
    _refreshQuestNotifications();
    notifyListeners();
    save();
  }

  /// Grants one normal copy of every base animal not yet owned.
  void devCollectAllAnimals() {
    final updatedAnimals = List<OwnedAnimal>.from(_state.ownedAnimals);
    final ownedIds = updatedAnimals.map((owned) => owned.animalId).toSet();

    for (final animal in GameData.animals) {
      if (ownedIds.contains(animal.id)) continue;
      updatedAnimals.add(OwnedAnimal(animalId: animal.id, quantity: 1));
      ownedIds.add(animal.id);
    }

    _state = _state.copyWith(ownedAnimals: updatedAnimals);
    _refreshQuestNotifications();
    notifyListeners();
    save();
  }

  void devResetQuestStats() {
    _state = _state.copyWith(
      questProgress: _state.questProgress.copyWith(
        totalEggsHatched: 0,
        totalSingleHatches: 0,
        totalTripleHatches: 0,
        totalMutationsHatched: 0,
        totalGoldenHatched: 0,
        totalRainbowHatched: 0,
        totalShadowHatched: 0,
        totalAnimalUpgrades: 0,
        totalLuckUpgrades: 0,
        totalCustomEggsCreated: 0,
        totalCustomEggHatches: 0,
        totalCustomTripleHatches: 0,
        totalSpritesRated: 0,
        totalSpriteRatingRewardsClaimed: 0,
        bestSpriteRatingScore: 0,
        totalPerfectSpriteRatings: 0,
        totalReferenceOverlaysUnlocked: 0,
        totalBossBattlesStarted: 0,
        totalBossBattlesWon: 0,
        totalBossBattlesLost: 0,
        slimeBossWins: 0,
        eggGolemWins: 0,
        shadowRoosterWins: 0,
        totalBattleTokensEarned: 0,
        totalBossEggsHatched: 0,
        totalBossMutationsApplied: 0,
        perfectRatedSpriteKeys: const [],
        questCountedRatedSpriteKeys: const [],
        notifiedCompletedQuestIds: const [],
      ),
    );
    _refreshQuestNotifications();
    notifyListeners();
    save();
  }

  void devResetBattleQuestStats() {
    _state = _state.copyWith(
      questProgress: _state.questProgress.copyWith(
        totalBossBattlesStarted: 0,
        totalBossBattlesWon: 0,
        totalBossBattlesLost: 0,
        slimeBossWins: 0,
        eggGolemWins: 0,
        shadowRoosterWins: 0,
        totalBattleTokensEarned: 0,
        totalBossEggsHatched: 0,
        totalBossMutationsApplied: 0,
        notifiedCompletedQuestIds: const [],
      ),
    );
    _refreshQuestNotifications();
    notifyListeners();
    save();
  }

  void devAddBossWin(String bossId) {
    final wins = Map<String, int>.from(_state.bossWins);
    wins[bossId] = (wins[bossId] ?? 0) + 1;
    var progress = _state.questProgress.copyWith(
      totalBossBattlesStarted: _state.questProgress.totalBossBattlesStarted + 1,
      totalBossBattlesWon: _state.questProgress.totalBossBattlesWon + 1,
    );
    switch (bossId) {
      case 'slime_boss':
        progress = progress.copyWith(slimeBossWins: progress.slimeBossWins + 1);
      case 'egg_golem':
        progress = progress.copyWith(eggGolemWins: progress.eggGolemWins + 1);
      case 'shadow_rooster':
        progress = progress.copyWith(
          shadowRoosterWins: progress.shadowRoosterWins + 1,
        );
    }
    _state = _state.copyWith(bossWins: wins, questProgress: progress);
    _refreshQuestNotifications();
    notifyListeners();
    save();
  }

  void devUnlockHardPhases() {
    final wins = Map<String, int>.from(_state.bossWins);
    for (final boss in BossData.standardBosses) {
      wins[boss.id] = max(
        wins[boss.id] ?? 0,
        BossBattleLogic.hardPhaseUnlockWins,
      );
    }
    _state = _state.copyWith(bossWins: wins);
    notifyListeners();
    save();
  }

  void devUnlockNightmareModes() {
    final hardWins = Map<String, int>.from(_state.hardPhaseWins);
    for (final boss in BossData.standardBosses) {
      hardWins[boss.id] = max(
        hardWins[boss.id] ?? 0,
        BossBattleLogic.nightmareUnlockHardWins,
      );
    }
    _state = _state.copyWith(hardPhaseWins: hardWins);
    notifyListeners();
    save();
  }

  void devUnlockEliteBosses() {
    final nightmareWins = Map<String, int>.from(_state.nightmareWins);
    for (final boss in BossData.standardBosses) {
      nightmareWins[boss.id] = max(
        nightmareWins[boss.id] ?? 0,
        BossBattleLogic.eliteUnlockNightmareWins,
      );
    }
    _state = _state.copyWith(nightmareWins: nightmareWins);
    notifyListeners();
    save();
  }

  void devMarkEliteRewardAnimals() {
    _state = _migrateEliteRewardAnimals(_state);
    notifyListeners();
    save();
  }

  void devGrantEliteBossAnimals() {
    for (final boss in BossData.eliteBosses) {
      final animalId = boss.rewardAnimalId;
      if (animalId != null) {
        grantBossRewardAnimal(animalId);
      }
    }
    notifyListeners();
    save();
  }

  void devGrantEliteBossAnimal(String animalId, {String? mutationId}) {
    grantBossRewardAnimal(animalId, mutationId: mutationId);
    notifyListeners();
    save();
  }

  void devClearClaimedQuests() {
    _state = _state.copyWith(
      questProgress: _state.questProgress.copyWith(claimedQuestIds: const []),
    );
    notifyListeners();
    save();
  }

  void devResetSpriteQuestStats() {
    _state = _state.copyWith(
      questProgress: _state.questProgress.copyWith(
        totalSpritesRated: 0,
        totalSpriteRatingRewardsClaimed: 0,
        bestSpriteRatingScore: 0,
        totalPerfectSpriteRatings: 0,
        totalReferenceOverlaysUnlocked: 0,
        perfectRatedSpriteKeys: const [],
        questCountedRatedSpriteKeys: const [],
        notifiedCompletedQuestIds: const [],
      ),
    );
    notifyListeners();
    save();
  }

  void devSetBestSpriteRatingScore(int score) {
    final clamped = score.clamp(0, 10);
    _state = _state.copyWith(
      questProgress: _state.questProgress.copyWith(
        bestSpriteRatingScore: clamped,
      ),
    );
    _refreshQuestNotifications();
    notifyListeners();
    save();
  }

  void devAddSpriteRated() {
    _state = _state.copyWith(
      questProgress: _state.questProgress.copyWith(
        totalSpritesRated: _state.questProgress.totalSpritesRated + 1,
      ),
    );
    _refreshQuestNotifications();
    notifyListeners();
    save();
  }

  void devAddSpriteRewardClaimed() {
    _state = _state.copyWith(
      questProgress: _state.questProgress.copyWith(
        totalSpriteRatingRewardsClaimed:
            _state.questProgress.totalSpriteRatingRewardsClaimed + 1,
      ),
    );
    _refreshQuestNotifications();
    notifyListeners();
    save();
  }

  void devAddOverlayUnlocked() {
    _state = _state.copyWith(
      questProgress: _state.questProgress.copyWith(
        totalReferenceOverlaysUnlocked:
            _state.questProgress.totalReferenceOverlaysUnlocked + 1,
      ),
    );
    _refreshQuestNotifications();
    notifyListeners();
    save();
  }

  void setForcedNextHatch(String animalId, String mutationId) {
    _forcedHatchQueue = [
      ForcedHatchResult(animalId: animalId, mutationId: mutationId),
    ];
    _forcedHatchMode = ForcedHatchMode.single;
    notifyListeners();
  }

  void setForcedNextTripleHatch(List<ForcedHatchResult> results) {
    _forcedHatchQueue = results
        .take(3)
        .map(
          (r) =>
              ForcedHatchResult(animalId: r.animalId, mutationId: r.mutationId),
        )
        .toList();
    _forcedHatchMode = _forcedHatchQueue.length >= 3
        ? ForcedHatchMode.triple
        : ForcedHatchMode.single;
    notifyListeners();
  }

  void clearForcedNextHatch() {
    _forcedHatchQueue = [];
    _forcedHatchMode = ForcedHatchMode.none;
    notifyListeners();
  }

  /// Hatch a purchased egg, roll for mutation, and add to the collection.
  ///
  /// Pass [customEgg] when hatching a player-created custom egg so weighted
  /// chances apply. Built-in eggs use equal random selection.
  HatchResult hatchEgg(Egg egg, {CustomEgg? customEgg}) {
    final result = _rollAndApplyHatch(
      egg,
      customEgg: customEgg,
      slotIndex: 0,
      isTripleHatchSession: false,
    );
    _recordHatchSession(
      results: [result],
      isTripleHatch: false,
      isCustomEgg: customEgg != null,
      eggId: egg.id,
    );
    _refreshQuestNotifications(deferDisplay: true);
    notifyListeners();
    save();
    return result;
  }

  /// Hatch multiple animals from one purchase.
  List<HatchResult> hatchEggMultiple(
    Egg egg,
    int count, {
    CustomEgg? customEgg,
  }) {
    if (count <= 0) return const [];

    final isTripleHatchSession = count >= 3;
    final results = <HatchResult>[];
    for (var i = 0; i < count; i++) {
      results.add(
        _rollAndApplyHatch(
          egg,
          customEgg: customEgg,
          slotIndex: i,
          isTripleHatchSession: isTripleHatchSession,
        ),
      );
    }

    _recordHatchSession(
      results: results,
      isTripleHatch: isTripleHatchSession,
      isCustomEgg: customEgg != null,
      eggId: egg.id,
    );
    _refreshQuestNotifications(deferDisplay: true);
    notifyListeners();
    save();
    return results;
  }

  ForcedHatchResult? _forcedResultForSlot(int slotIndex) {
    if (_forcedHatchQueue.isEmpty) return null;

    if (_forcedHatchMode == ForcedHatchMode.single) {
      return slotIndex == 0 ? _forcedHatchQueue.first : null;
    }

    if (slotIndex < _forcedHatchQueue.length) {
      return _forcedHatchQueue[slotIndex];
    }
    return null;
  }

  void _afterForcedSlotConsumed(
    int slotIndex, {
    required bool isTripleHatchSession,
  }) {
    if (_forcedHatchQueue.isEmpty) return;

    if (_forcedHatchMode == ForcedHatchMode.single) {
      if (slotIndex == 0) clearForcedNextHatch();
      return;
    }

    if (!isTripleHatchSession) {
      clearForcedNextHatch();
      return;
    }

    if (slotIndex >= 2) {
      clearForcedNextHatch();
    }
  }

  HatchResult _rollAndApplyHatch(
    Egg egg, {
    CustomEgg? customEgg,
    required int slotIndex,
    required bool isTripleHatchSession,
  }) {
    final Animal animal;
    final Mutation mutation;

    final forced = _forcedResultForSlot(slotIndex);
    if (forced != null) {
      animal = GameData.animalById(forced.animalId)!;
      mutation =
          GameData.mutationById(forced.mutationId) ?? GameData.mutations.first;
      _afterForcedSlotConsumed(
        slotIndex,
        isTripleHatchSession: isTripleHatchSession,
      );
    } else {
      final String animalId;
      if (customEgg != null && customEgg.isValid && customEgg.id == egg.id) {
        animalId = CustomEggLogic.weightedRandomAnimal(
          customEgg,
          _random,
          lifetimeCoinsEarned: _state.lifetimeCoinsEarned,
          rebirthLevel: _state.rebirthLevel,
        );
      } else {
        animalId = BuiltInEggLogic.rollAnimal(egg, _random);
      }
      animal = GameData.animalById(animalId)!;
      mutation = LuckLogic.rollMutation(
        _random,
        _state.luckLevel,
        bossMutationUnlocked: _state.bossMutationUnlocked,
      );
    }

    final updatedAnimals = List<OwnedAnimal>.from(_state.ownedAnimals);
    final existingIndex = _indexOfOwnedStack(
      updatedAnimals,
      animal.id,
      mutation.id,
      isProtected: false,
    );
    final hatchSourceEggId = EggMasteryLogic.isMasteryEligibleEgg(egg.id)
        ? egg.id
        : null;

    if (existingIndex >= 0) {
      final existing = updatedAnimals[existingIndex];
      updatedAnimals[existingIndex] = existing.copyWith(
        quantity: existing.quantity + 1,
        sourceEggId: _mergeSourceEggId(existing.sourceEggId, hatchSourceEggId),
        clearSourceEggId:
            existing.sourceEggId != null &&
            hatchSourceEggId != null &&
            existing.sourceEggId != hatchSourceEggId,
      );
    } else {
      updatedAnimals.add(
        OwnedAnimal(
          animalId: animal.id,
          quantity: 1,
          level: 1,
          mutationId: mutation.id,
          sourceEggId: hatchSourceEggId,
        ),
      );
    }

    _state = _state.copyWith(ownedAnimals: updatedAnimals);
    return HatchResult(animal: animal, mutation: mutation);
  }

  int _indexOfOwnedStack(
    List<OwnedAnimal> animals,
    String animalId,
    String mutationId, {
    required bool isProtected,
  }) {
    for (var i = 0; i < animals.length; i++) {
      final owned = animals[i];
      if (owned.animalId == animalId &&
          owned.mutationId == mutationId &&
          owned.isProtected == isProtected) {
        return i;
      }
    }
    return -1;
  }

  void _recordHatchSession({
    required List<HatchResult> results,
    required bool isTripleHatch,
    required bool isCustomEgg,
    String? eggId,
  }) {
    if (results.isEmpty) return;

    var progress = _state.questProgress;
    progress = progress.copyWith(
      totalEggsHatched: progress.totalEggsHatched + results.length,
      totalSingleHatches: isTripleHatch
          ? progress.totalSingleHatches
          : progress.totalSingleHatches + 1,
      totalTripleHatches: isTripleHatch
          ? progress.totalTripleHatches + 1
          : progress.totalTripleHatches,
    );

    if (isCustomEgg) {
      progress = progress.copyWith(
        totalCustomEggHatches: progress.totalCustomEggHatches + results.length,
      );
      if (isTripleHatch) {
        progress = progress.copyWith(
          totalCustomTripleHatches: progress.totalCustomTripleHatches + 1,
        );
      }
    }

    for (final result in results) {
      if (result.mutation.isNormal) continue;
      progress = progress.copyWith(
        totalMutationsHatched: progress.totalMutationsHatched + 1,
      );
      switch (result.mutation.id) {
        case 'golden':
          progress = progress.copyWith(
            totalGoldenHatched: progress.totalGoldenHatched + 1,
          );
        case 'rainbow':
          progress = progress.copyWith(
            totalRainbowHatched: progress.totalRainbowHatched + 1,
          );
        case 'shadow':
          progress = progress.copyWith(
            totalShadowHatched: progress.totalShadowHatched + 1,
          );
      }
    }

    if (eggId == 'boss_egg') {
      progress = progress.copyWith(
        totalBossEggsHatched: progress.totalBossEggsHatched + results.length,
      );
    }

    _state = _state.copyWith(questProgress: progress);
    _incrementDailyQuest(
      DailySystemLogic.hatchEggsType,
      amount: results.length,
    );
    if (eggId != null && EggMasteryLogic.isMasteryEligibleEgg(eggId)) {
      _applyEggMasteryHatches(eggId, results.length);
    }
  }

  String? _mergeSourceEggId(String? existing, String? hatchEggId) {
    if (hatchEggId == null) return existing;
    if (existing == null) return hatchEggId;
    if (existing == hatchEggId) return existing;
    return null;
  }

  void _applyEggMasteryHatches(String eggId, int hatchCount) {
    if (hatchCount <= 0) return;

    final egg = GameData.eggById(eggId);
    if (egg == null) return;

    final current =
        _state.eggMastery[eggId] ?? EggMasteryProgress(eggId: eggId);
    final previousLevel = current.masteryLevel;
    final updated = current
        .copyWith(hatchCount: current.hatchCount + hatchCount)
        .normalized();

    final updatedMap = Map<String, EggMasteryProgress>.from(_state.eggMastery)
      ..[eggId] = updated;
    _state = _state.copyWith(eggMastery: updatedMap);

    if (updated.masteryLevel > previousLevel) {
      for (
        var level = previousLevel + 1;
        level <= updated.masteryLevel;
        level++
      ) {
        _pendingMasteryNotifications.add(
          EggMasteryLogic.levelUpMessage(egg.name, level),
        );
      }
    }
  }

  OwnedAnimal? ownedAnimal(
    String animalId, {
    String mutationId = 'none',
    bool? isProtected,
  }) {
    for (final owned in _state.ownedAnimals) {
      if (owned.animalId != animalId || owned.mutationId != mutationId) {
        continue;
      }
      if (isProtected != null && owned.isProtected != isProtected) {
        continue;
      }
      return owned;
    }
    return null;
  }

  bool canAffordUpgrade(
    String animalId,
    String mutationId, {
    bool isProtected = false,
  }) {
    final owned = ownedAnimal(
      animalId,
      mutationId: mutationId,
      isProtected: isProtected,
    );
    final animal = GameData.animalById(animalId);
    if (owned == null || animal == null) return false;
    return _state.coins >= upgradeCostFor(animal, owned);
  }

  /// Upgrade a specific animal/mutation combo. Returns new level or null.
  int? upgradeAnimal(
    String animalId,
    String mutationId, {
    bool isProtected = false,
  }) {
    if (isStackAutoBattling(
      animalId: animalId,
      mutationId: mutationId,
      isProtected: isProtected,
    )) {
      return null;
    }

    final owned = ownedAnimal(
      animalId,
      mutationId: mutationId,
      isProtected: isProtected,
    );
    final animal = GameData.animalById(animalId);
    if (owned == null || animal == null) return null;

    final cost = upgradeCostFor(animal, owned);
    if (_state.coins < cost) return null;

    final updatedAnimals = List<OwnedAnimal>.from(_state.ownedAnimals);
    final index = _indexOfOwnedStack(
      updatedAnimals,
      animalId,
      mutationId,
      isProtected: isProtected,
    );
    if (index < 0) return null;

    final newLevel = owned.level + 1;
    updatedAnimals[index] = owned.copyWith(level: newLevel);

    _state = _state.copyWith(
      coins: _state.coins - cost,
      ownedAnimals: updatedAnimals,
      questProgress: _state.questProgress.copyWith(
        totalAnimalUpgrades: _state.questProgress.totalAnimalUpgrades + 1,
      ),
    );
    _incrementDailyQuest(DailySystemLogic.upgradeAnimalsType);
    _refreshQuestNotifications();
    notifyListeners();
    save();
    return newLevel;
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    save();
    super.dispose();
  }
}
