import 'package:flutter/material.dart';

import '../models/background_theme.dart';
import '../services/game_service.dart';
import '../services/tutorial_service.dart';
import '../theme/game_theme.dart';
import '../utils/format_utils.dart';
import '../utils/ui_sound.dart';
import '../utils/snackbar_utils.dart';

/// Centered daily reward modal shown after tutorial and on eligible launches.
class DailyRewardPopup {
  DailyRewardPopup._();

  static var _isShowing = false;

  static Future<void> showIfEligible(
    BuildContext context, {
    required GameService game,
    required BackgroundTheme theme,
  }) async {
    if (_isShowing || !context.mounted) return;
    if (TutorialService.instance.isActive) return;
    if (!game.shouldAutoShowDailyRewardPopup) return;

    _isShowing = true;
    game.markDailyRewardPopupShown();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: theme.scaffoldColor.withValues(alpha: 0.88),
      builder: (dialogContext) => _DailyRewardDialog(
        game: game,
        theme: theme,
        onClaim: () {
          final reward = game.upcomingDailyReward;
          if (!game.claimDailyReward()) return;

          UiSound.rewardTriumph(context);

          Navigator.pop(dialogContext);
          if (!context.mounted) return;

          final parts = <String>[];
          if (reward.coins > 0) {
            parts.add('${formatCoins(reward.coins)} coins');
          }
          if (reward.battleTokens > 0) {
            parts.add('${reward.battleTokens} Battle Tokens');
          }

          showGameSnackBar(
            context,
            message: parts.isEmpty
                ? 'Daily reward claimed!'
                : 'Daily reward claimed! +${parts.join(' + ')}',
            backgroundColor: theme.secondaryColor,
          );
        },
        onLater: () {
          game.dismissDailyRewardPopup();
          Navigator.pop(dialogContext);
        },
      ),
    );

    _isShowing = false;
  }
}

class _DailyRewardDialog extends StatelessWidget {
  const _DailyRewardDialog({
    required this.game,
    required this.theme,
    required this.onClaim,
    required this.onLater,
  });

  final GameService game;
  final BackgroundTheme theme;
  final VoidCallback onClaim;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final claimed = game.hasClaimedDailyRewardToday;
    final reward = game.upcomingDailyReward;
    final streak = game.displayDailyRewardStreak;
    final best = game.bestDailyRewardStreak;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Material(
              color: theme.cardColor,
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GameTheme.cardRadius),
                side: BorderSide(
                  color: theme.primaryColor.withValues(alpha: 0.35),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Daily Reward',
                            style: GameTheme.sectionTitle(theme, size: 22),
                          ),
                        ),
                        IconButton(
                          onPressed: onLater,
                          icon: Icon(
                            Icons.close,
                            color: theme.cardTextSecondaryColor,
                          ),
                          tooltip: 'Later',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '🎁',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 44),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Streak: $streak day${streak == 1 ? '' : 's'}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.cardTextPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Best: $best',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.cardTextSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      claimed
                          ? 'Claimed Today'
                          : 'Today: ${reward.label}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.cardTextPrimaryColor,
                      ),
                    ),
                    if (claimed) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Come back tomorrow!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.cardTextSecondaryColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (claimed)
                      FilledButton.icon(
                        onPressed: () => Navigator.pop(context),
                        style: GameTheme.filledButton(
                          theme,
                          color: theme.disabledColor,
                        ),
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Claimed Today'),
                      )
                    else ...[
                      FilledButton.icon(
                        onPressed: onClaim,
                        style: GameTheme.filledButton(theme),
                        icon: const Icon(Icons.redeem_rounded),
                        label: const Text('Claim'),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: onLater,
                        icon: const Icon(Icons.schedule_rounded),
                        label: Text(
                          'Later',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.cardTextSecondaryColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
