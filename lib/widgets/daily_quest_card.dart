import 'package:flutter/material.dart';

import '../models/background_theme.dart';
import '../models/daily_quest_progress.dart';
import '../services/game_service.dart';
import '../theme/game_theme.dart';
import '../utils/daily_system_logic.dart';

class DailyQuestCard extends StatelessWidget {
  const DailyQuestCard({
    super.key,
    required this.quest,
    required this.game,
    required this.theme,
    required this.onClaim,
  });

  final DailyQuestProgress quest;
  final GameService game;
  final BackgroundTheme theme;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final reward = DailySystemLogic.rewardLabel(
      rewardCoins: quest.rewardCoins,
      rewardBattleTokens: quest.rewardBattleTokens,
    );
    final canClaim = quest.isComplete && !quest.claimed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: GameTheme.cardDecoration(
        theme,
        borderColor: canClaim ? theme.secondaryColor : null,
        backgroundColor: canClaim
            ? theme.secondaryColor.withValues(alpha: 0.08)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            quest.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.cardTextPrimaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Progress: ${quest.progress} / ${quest.target}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.cardTextPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Reward: $reward',
            style: TextStyle(
              fontSize: 13,
              color: theme.cardTextSecondaryColor,
            ),
          ),
          const SizedBox(height: 10),
          if (quest.claimed)
            Text(
              'Claimed',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.secondaryColor,
              ),
            )
          else
            FilledButton.icon(
              onPressed: canClaim ? onClaim : null,
              style: GameTheme.filledButton(
                theme,
                color: canClaim ? theme.secondaryColor : theme.disabledColor,
              ),
              icon: Icon(canClaim ? Icons.redeem_rounded : Icons.hourglass_bottom_rounded),
              label: Text(canClaim ? 'Claim' : 'In progress'),
            ),
        ],
      ),
    );
  }
}

class DailyQuestsSection extends StatelessWidget {
  const DailyQuestsSection({
    super.key,
    required this.game,
    required this.theme,
    required this.onClaim,
  });

  final GameService game;
  final BackgroundTheme theme;
  final void Function(DailyQuestProgress quest) onClaim;

  @override
  Widget build(BuildContext context) {
    final quests = game.dailyQuests;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Daily Quests',
          style: GameTheme.sectionTitle(theme, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          'New random quests every day',
          style: TextStyle(
            fontSize: 13,
            color: theme.cardTextSecondaryColor,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < quests.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          DailyQuestCard(
            quest: quests[i],
            game: game,
            theme: theme,
            onClaim: () => onClaim(quests[i]),
          ),
        ],
      ],
    );
  }
}
