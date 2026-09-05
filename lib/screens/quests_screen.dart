import 'package:flutter/material.dart';

import '../data/quest_data.dart';
import '../models/background_theme.dart';
import '../models/daily_quest_progress.dart';
import '../models/quest.dart';
import '../navigation/app_page_route.dart';
import '../services/game_service.dart';
import '../services/preferences_service.dart';
import '../theme/game_theme.dart';
import '../utils/format_utils.dart';
import '../utils/quest_logic.dart';
import '../utils/snackbar_utils.dart';
import '../utils/ui_sound.dart';
import '../widgets/daily_quest_card.dart';
import '../widgets/game_background.dart';
import '../widgets/game_primary_navigation.dart';
import '../widgets/phone_width_layout.dart';
import '../widgets/quest_card.dart';
import '../widgets/tutorial_screen_bindings.dart';
import '../widgets/tutorial_targets.dart';

/// Prioritized quest hub with a single-open category accordion.
class QuestsScreen extends StatefulWidget {
  const QuestsScreen({
    super.key,
    required this.game,
    required this.preferences,
  });

  final GameService game;
  final PreferencesService preferences;

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  QuestCategory? _openCategory = QuestCategory.beginner;
  final Set<QuestCategory> _showClaimed = {};
  final Map<QuestCategory, GlobalKey> _categoryKeys = {
    for (final category in QuestData.categoryOrder) category: GlobalKey(),
  };

  GameService get game => widget.game;
  PreferencesService get preferences => widget.preferences;

  void _selectCategory(QuestCategory category) {
    setState(() => _openCategory = category);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = _categoryKeys[category]?.currentContext;
      if (!mounted || targetContext == null) return;
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: 0.02,
      );
    });
  }

  Future<void> _claimQuest(BuildContext context, Quest quest) async {
    final secretWasAlreadyDiscovered = game.secretHatcheryDiscovered;
    final reward = game.claimQuest(quest.id);
    if (reward == null || !context.mounted) return;

    UiSound.rewardTriumph(context);

    if (reward.collectorsVaultUnlocked) {
      await _showCollectorsVaultDialog(
        context,
        wasAlreadyDiscovered: secretWasAlreadyDiscovered,
      );
      return;
    }

    if (reward.coins > 0) {
      showGameSnackBar(
        context,
        message: 'Quest complete! +${formatCoins(reward.coins)} coins',
        backgroundColor: preferences.selectedTheme.secondaryColor,
      );
    } else if (reward.battleTokens > 0) {
      showGameSnackBar(
        context,
        message: 'Quest complete! +${reward.battleTokens} Battle Tokens',
        backgroundColor: preferences.selectedTheme.secondaryColor,
      );
    }
  }

  Future<void> _showCollectorsVaultDialog(
    BuildContext context, {
    required bool wasAlreadyDiscovered,
  }) {
    final theme = preferences.selectedTheme;
    final message = wasAlreadyDiscovered
        ? 'You found the Secret Hatchery ahead of schedule. Your complete '
              'collection has opened the Collector’s Vault.'
        : 'Your complete collection has revealed the Secret Hatchery. Tap '
              'the Hatchery coin three times to enter. The Collector’s Vault '
              'is now open.';
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GameTheme.cardRadius),
        ),
        title: Text(
          'Collector’s Vault Unlocked',
          style: TextStyle(
            color: theme.cardTextPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: theme.cardTextSecondaryColor,
            fontSize: 15,
            height: 1.4,
          ),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext),
            icon: const Icon(Icons.lock_open_rounded),
            label: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _claimAll(
    BuildContext context,
    List<Quest> readyToClaim,
    List<DailyQuestProgress> dailyReady,
  ) {
    var coins = 0;
    var tokens = 0;
    var claimed = 0;
    for (final quest in readyToClaim) {
      if (quest.showsSecretHintOnClaim || !quest.hasClaimableReward) continue;
      final reward = game.claimQuest(quest.id);
      if (reward == null) continue;
      coins += reward.coins;
      tokens += reward.battleTokens;
      claimed++;
    }
    for (final quest in dailyReady) {
      if (!game.claimDailyQuest(quest.id)) continue;
      coins += quest.rewardCoins;
      tokens += quest.rewardBattleTokens;
      claimed++;
    }
    if (claimed == 0 || !context.mounted) return;

    UiSound.rewardTriumph(context);
    final rewards = <String>[
      if (coins > 0) '+${formatCoins(coins)} coins',
      if (tokens > 0) '+$tokens Battle Tokens',
    ];
    showGameSnackBar(
      context,
      message: '$claimed quest rewards claimed: ${rewards.join(' · ')}',
      backgroundColor: preferences.selectedTheme.secondaryColor,
    );
  }

  void _claimDailyQuest(BuildContext context, DailyQuestProgress quest) {
    if (!game.claimDailyQuest(quest.id) || !context.mounted) return;

    UiSound.rewardTriumph(context);
    final message = quest.rewardCoins > 0
        ? 'Daily quest complete! +${formatCoins(quest.rewardCoins)} coins'
        : 'Daily quest complete! +${quest.rewardBattleTokens} Battle Tokens';
    showGameSnackBar(
      context,
      message: message,
      backgroundColor: preferences.selectedTheme.secondaryColor,
    );
  }

  List<Quest> _activeQuests(QuestCategory category, Set<String> readyIds) {
    final quests = QuestData.forCategory(category)
        .where(
          (quest) =>
              !readyIds.contains(quest.id) &&
              QuestLogic.status(quest, game.state) != QuestStatus.claimed,
        )
        .toList();
    quests.sort((a, b) {
      final aRatio = QuestLogic.currentValue(a, game.state) / a.target;
      final bRatio = QuestLogic.currentValue(b, game.state) / b.target;
      final ratio = bRatio.compareTo(aRatio);
      if (ratio != 0) return ratio;
      return QuestData.all.indexOf(a).compareTo(QuestData.all.indexOf(b));
    });
    return quests;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([game, preferences]),
      builder: (context, _) {
        final theme = preferences.selectedTheme;
        final shell = MainGameShellScope.maybeOf(context);
        final readyToClaim = QuestLogic.readyToClaimQuests(game.state);
        final dailyReady = game.dailyQuests
            .where((quest) => quest.isComplete && !quest.claimed)
            .toList();
        final dailyOther = game.dailyQuests
            .where(
              (quest) => !dailyReady.any((ready) => ready.id == quest.id),
            )
            .toList();
        final readyIds = readyToClaim.map((quest) => quest.id).toSet();
        final claimAllCount = readyToClaim
            .where(
              (quest) =>
                  !quest.showsSecretHintOnClaim && quest.hasClaimableReward,
            )
            .length +
            dailyReady.length;

        return TutorialScreenBindings(
          enabled: shell == null || shell.current == MainGameDestination.quests,
          onReturnToHatchery: () =>
              returnToHatcheryWithTransition(context, theme: theme),
          child: ReturnToHatcheryPopScope(
            theme: theme,
            enabled: shell == null,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: PhoneWidthAppBar(
                title: '🎯 Quests',
                titleStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
                backgroundColor: theme.appBarColor,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                leading: shell == null
                    ? ReturnToHatcheryBackButton(
                        theme: theme,
                        color: Colors.white,
                        tutorialKey: TutorialTargets.screenBackButton,
                      )
                    : null,
                bottom: shell == null
                    ? null
                    : GamePrimaryNavigation(
                        theme: theme,
                        hostDestination: MainGameDestination.quests,
                      ),
              ),
              body: GameBackground(
                theme: theme,
                child: PhoneWidthLayout(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _QuestOverview(
                        theme: theme,
                        readyCount: readyToClaim.length + dailyReady.length,
                      ),
                      const SizedBox(height: 10),
                      _CategoryJump(
                        theme: theme,
                        selected: _openCategory,
                        onSelected: _selectCategory,
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView(
                          key: const PageStorageKey<String>('quests-list'),
                          children: [
                            if (readyToClaim.isNotEmpty ||
                                dailyReady.isNotEmpty) ...[
                              _ReadySection(
                                theme: theme,
                                quests: readyToClaim,
                                dailyQuests: dailyReady,
                                claimAllCount: claimAllCount,
                                game: game,
                                onClaim: (quest) => _claimQuest(context, quest),
                                onClaimDaily: (quest) =>
                                    _claimDailyQuest(context, quest),
                                onClaimAll: () =>
                                    _claimAll(context, readyToClaim, dailyReady),
                              ),
                              const SizedBox(height: 14),
                            ],
                            if (dailyOther.isNotEmpty) ...[
                              DailyQuestsSection(
                                game: game,
                                theme: theme,
                                quests: dailyOther,
                                onClaim: (quest) =>
                                    _claimDailyQuest(context, quest),
                              ),
                              const SizedBox(height: 14),
                            ],
                            for (final category in QuestData.categoryOrder) ...[
                              _QuestCategoryAccordion(
                                key: _categoryKeys[category],
                                category: category,
                                theme: theme,
                                game: game,
                                expanded: _openCategory == category,
                                showClaimed: _showClaimed.contains(category),
                                activeQuests: _activeQuests(category, readyIds),
                                onToggle: () {
                                  setState(() {
                                    _openCategory = _openCategory == category
                                        ? null
                                        : category;
                                  });
                                },
                                onToggleClaimed: () {
                                  setState(() {
                                    if (!_showClaimed.add(category)) {
                                      _showClaimed.remove(category);
                                    }
                                  });
                                },
                                onClaim: (quest) => _claimQuest(context, quest),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuestOverview extends StatelessWidget {
  const _QuestOverview({required this.theme, required this.readyCount});

  final BackgroundTheme theme;
  final int readyCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: GameTheme.cardDecoration(theme),
      child: Row(
        children: [
          const Text('🗺️', style: TextStyle(fontSize: 25)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Goals & Rewards',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.cardTextPrimaryColor,
                  ),
                ),
                Text(
                  readyCount > 0
                      ? '$readyCount ready to claim'
                      : 'Choose one category to explore.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.cardTextSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryJump extends StatelessWidget {
  const _CategoryJump({
    required this.theme,
    required this.selected,
    required this.onSelected,
  });

  final BackgroundTheme theme;
  final QuestCategory? selected;
  final ValueChanged<QuestCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<QuestCategory>(
      key: ValueKey<QuestCategory?>(selected),
      initialValue: selected,
      isExpanded: true,
      dropdownColor: theme.cardColor,
      decoration: InputDecoration(
        labelText: 'Jump to category',
        prefixIcon: const Icon(Icons.low_priority_rounded),
        filled: true,
        fillColor: theme.cardColor,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      items: [
        for (final category in QuestData.categoryOrder)
          DropdownMenuItem(
            value: category,
            child: Text(QuestData.forCategory(category).first.categoryLabel),
          ),
      ],
      onChanged: (category) {
        if (category != null) onSelected(category);
      },
    );
  }
}

class _ReadySection extends StatelessWidget {
  const _ReadySection({
    required this.theme,
    required this.quests,
    required this.dailyQuests,
    required this.claimAllCount,
    required this.game,
    required this.onClaim,
    required this.onClaimDaily,
    required this.onClaimAll,
  });

  final BackgroundTheme theme;
  final List<Quest> quests;
  final List<DailyQuestProgress> dailyQuests;
  final int claimAllCount;
  final GameService game;
  final ValueChanged<Quest> onClaim;
  final ValueChanged<DailyQuestProgress> onClaimDaily;
  final VoidCallback onClaimAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: GameTheme.cardDecoration(
        theme,
        borderColor: theme.secondaryColor,
        backgroundColor: theme.secondaryColor.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '🎉 Ready to Claim (${quests.length + dailyQuests.length})',
                  style: GameTheme.sectionTitle(theme, size: 16),
                ),
              ),
              if (claimAllCount > 1)
                FilledButton.icon(
                  onPressed: onClaimAll,
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text('Claim All'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < quests.length; index++) ...[
            if (index > 0) const SizedBox(height: 10),
            QuestCard(
              quest: quests[index],
              game: game,
              theme: theme,
              onClaim: () => onClaim(quests[index]),
            ),
          ],
          for (var index = 0; index < dailyQuests.length; index++) ...[
            if (quests.isNotEmpty || index > 0) const SizedBox(height: 10),
            DailyQuestCard(
              quest: dailyQuests[index],
              game: game,
              theme: theme,
              onClaim: () => onClaimDaily(dailyQuests[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestCategoryAccordion extends StatelessWidget {
  const _QuestCategoryAccordion({
    super.key,
    required this.category,
    required this.theme,
    required this.game,
    required this.expanded,
    required this.showClaimed,
    required this.activeQuests,
    required this.onToggle,
    required this.onToggleClaimed,
    required this.onClaim,
  });

  final QuestCategory category;
  final BackgroundTheme theme;
  final GameService game;
  final bool expanded;
  final bool showClaimed;
  final List<Quest> activeQuests;
  final VoidCallback onToggle;
  final VoidCallback onToggleClaimed;
  final ValueChanged<Quest> onClaim;

  @override
  Widget build(BuildContext context) {
    final quests = QuestData.forCategory(category);
    final completeCount = quests
        .where(
          (quest) =>
              QuestLogic.status(quest, game.state) != QuestStatus.inProgress,
        )
        .length;
    final readyCount = quests
        .where(
          (quest) =>
              QuestLogic.status(quest, game.state) == QuestStatus.readyToClaim,
        )
        .length;
    final claimed = quests
        .where(
          (quest) =>
              QuestLogic.status(quest, game.state) == QuestStatus.claimed,
        )
        .toList();
    final sample = quests.first;

    return Container(
      decoration: GameTheme.cardDecoration(theme),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        sample.categoryEmoji,
                        style: const TextStyle(fontSize: 21),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sample.categoryLabel,
                              style: TextStyle(
                                color: theme.cardTextPrimaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '$completeCount/${quests.length} complete'
                              '${readyCount > 0 ? ' · $readyCount reward${readyCount == 1 ? '' : 's'} ready' : ''}',
                              style: TextStyle(
                                color: readyCount > 0
                                    ? theme.secondaryColor
                                    : theme.cardTextSecondaryColor,
                                fontSize: 12,
                                fontWeight: readyCount > 0
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: theme.cardTextSecondaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  LinearProgressIndicator(
                    value: quests.isEmpty ? 0 : completeCount / quests.length,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(6),
                    color: completeCount == quests.length
                        ? Colors.green
                        : theme.primaryColor,
                    backgroundColor: theme.panelAccentColor.withValues(
                      alpha: 0.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Divider(height: 1, color: theme.cardBorderColor),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (activeQuests.isEmpty && claimed.isEmpty)
                    Text(
                      readyCount > 0
                          ? 'Ready quests are shown at the top.'
                          : 'No quests in this category yet.',
                      style: TextStyle(color: theme.cardTextSecondaryColor),
                    ),
                  for (var index = 0; index < activeQuests.length; index++) ...[
                    if (index > 0) const SizedBox(height: 10),
                    QuestCard(
                      quest: activeQuests[index],
                      game: game,
                      theme: theme,
                      onClaim: () => onClaim(activeQuests[index]),
                    ),
                  ],
                  if (claimed.isNotEmpty) ...[
                    if (activeQuests.isNotEmpty) const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: onToggleClaimed,
                      icon: Icon(
                        showClaimed
                            ? Icons.expand_less_rounded
                            : Icons.check_circle_outline_rounded,
                      ),
                      label: Text('Completed (${claimed.length})'),
                    ),
                    if (showClaimed) ...[
                      const SizedBox(height: 10),
                      for (var index = 0; index < claimed.length; index++) ...[
                        if (index > 0) const SizedBox(height: 10),
                        QuestCard(
                          quest: claimed[index],
                          game: game,
                          theme: theme,
                          onClaim: () {},
                        ),
                      ],
                    ],
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
