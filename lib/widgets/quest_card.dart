import 'package:flutter/material.dart';

import '../models/background_theme.dart';
import '../models/quest.dart';
import '../services/game_service.dart';
import '../theme/game_theme.dart';
import '../utils/format_utils.dart';
import '../utils/quest_logic.dart';

/// One quest row with progress, reward, and claim action.
class QuestCard extends StatelessWidget {
  const QuestCard({
    super.key,
    required this.quest,
    required this.game,
    required this.theme,
    required this.onClaim,
  });

  final Quest quest;
  final GameService game;
  final BackgroundTheme theme;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final status = QuestLogic.status(quest, game.state);
    final progressText = QuestLogic.progressText(quest, game.state);
    final isReady = status == QuestStatus.readyToClaim;
    final isClaimed = status == QuestStatus.claimed;

    final accent = isReady
        ? theme.secondaryColor
        : isClaimed
            ? theme.cardTextSecondaryColor
            : theme.primaryColor;

    return Container(
      decoration: GameTheme.cardDecoration(
        theme,
        borderColor: isReady ? theme.secondaryColor : null,
        backgroundColor: isReady
            ? theme.secondaryColor.withValues(alpha: 0.08)
            : isClaimed
                ? theme.panelAccentColor.withValues(alpha: 0.06)
                : null,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isClaimed ? '✅' : isReady ? '🎉' : '📋',
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.cardTextPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      quest.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.cardTextSecondaryColor,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                label: 'Progress',
                value: progressText,
                theme: theme,
                color: accent,
              ),
              _InfoChip(
                label: 'Reward',
                value: quest.rewardDisplayLabel ?? _rewardText(quest),
                theme: theme,
                color: quest.grantsBattleTokensOnClaim
                    ? theme.primaryColor
                    : theme.secondaryColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isClaimed)
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: theme.panelAccentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.cardBorderColor),
              ),
              child: Text(
                'Claimed',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.cardTextSecondaryColor,
                ),
              ),
            )
          else
            FilledButton.icon(
              onPressed: isReady ? onClaim : null,
              style: GameTheme.filledButton(
                theme,
                color: isReady ? theme.secondaryColor : theme.disabledColor,
                height: 44,
              ),
              icon: Icon(
                isReady ? Icons.redeem_rounded : Icons.hourglass_bottom_rounded,
              ),
              label: Text(
                isReady ? 'Claim Reward' : 'In Progress',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _rewardText(Quest quest) {
    if (quest.grantsBattleTokensOnClaim && quest.grantsCoinsOnClaim) {
      return '🪙 ${formatCoins(quest.rewardCoins)} · '
          '⚔️ +${quest.rewardBattleTokens}';
    }
    if (quest.grantsBattleTokensOnClaim) {
      return '⚔️ +${quest.rewardBattleTokens} Battle Tokens';
    }
    return '🪙 ${formatCoins(quest.rewardCoins)}';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
    required this.theme,
    required this.color,
  });

  final String label;
  final String value;
  final BackgroundTheme theme;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: theme.cardTextSecondaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.cardTextPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
