import 'package:flutter/material.dart';

import '../models/background_theme.dart';
import '../services/game_service.dart';
import '../theme/game_theme.dart';
import '../utils/format_utils.dart';
import '../utils/snackbar_utils.dart';
import '../utils/ui_sound.dart';

class DailyRewardCard extends StatelessWidget {
  const DailyRewardCard({
    super.key,
    required this.game,
    required this.theme,
  });

  final GameService game;
  final BackgroundTheme theme;

  void _claim(BuildContext context) {
    if (!game.canClaimDailyReward) return;

    final reward = game.upcomingDailyReward;
    if (!game.claimDailyReward()) return;

    if (!context.mounted) return;

    UiSound.rewardTriumph(context);

    final parts = <String>[];
    if (reward.coins > 0) {
      parts.add('${formatCoins(reward.coins)} coins');
    }
    if (reward.battleTokens > 0) {
      parts.add('${reward.battleTokens} Battle Tokens');
    }

    showGameSnackBar(
      context,
      message: 'Daily reward claimed! +${parts.join(' + ')}',
      backgroundColor: theme.secondaryColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final claimed = game.hasClaimedDailyRewardToday;
    final reward = game.upcomingDailyReward;
    final streak = game.dailyRewardStreak;
    final best = game.bestDailyRewardStreak;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GameTheme.cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Daily Reward',
            style: GameTheme.sectionTitle(theme, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Streak: $streak day${streak == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.cardTextPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Best: $best',
            style: TextStyle(
              fontSize: 13,
              color: theme.cardTextSecondaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            claimed ? "Today's reward claimed" : "Today's reward: ${reward.label}",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.cardTextPrimaryColor,
            ),
          ),
          if (claimed) ...[
            const SizedBox(height: 6),
            Text(
              'Come back tomorrow!',
              style: TextStyle(
                fontSize: 13,
                color: theme.cardTextSecondaryColor,
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: claimed ? null : () => _claim(context),
            style: GameTheme.filledButton(
              theme,
              color: claimed ? theme.disabledColor : theme.primaryColor,
            ),
            icon: Icon(claimed ? Icons.check_circle_rounded : Icons.redeem_rounded),
            label: Text(claimed ? 'Claimed Today' : 'Claim'),
          ),
        ],
      ),
    );
  }
}

class DailyQuestsSummaryCard extends StatelessWidget {
  const DailyQuestsSummaryCard({
    super.key,
    required this.game,
    required this.theme,
    required this.onOpenQuests,
  });

  final GameService game;
  final BackgroundTheme theme;
  final VoidCallback onOpenQuests;

  @override
  Widget build(BuildContext context) {
    final complete = game.dailyQuestsCompleteCount;
    final total = game.dailyQuests.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: GameTheme.cardDecoration(theme),
      child: Row(
        children: [
          const Text('📅', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Quests: $complete/$total complete',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.cardTextPrimaryColor,
                  ),
                ),
                Text(
                  'Random quests refresh daily · Tap to view',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.cardTextSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onOpenQuests,
            icon: const Icon(Icons.visibility_rounded),
            label: const Text('View'),
          ),
        ],
      ),
    );
  }
}
