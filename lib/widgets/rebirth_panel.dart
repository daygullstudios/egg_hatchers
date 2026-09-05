import 'package:flutter/material.dart';

import '../models/background_theme.dart';
import '../services/game_service.dart';
import '../theme/game_theme.dart';
import '../utils/format_utils.dart';
import '../utils/rebirth_logic.dart';
import '../utils/snackbar_utils.dart';
import '../utils/ui_sound.dart';

/// Hatchery panel for rebirth status and confirmation.
class RebirthPanel extends StatefulWidget {
  const RebirthPanel({super.key, required this.game, required this.theme});

  final GameService game;
  final BackgroundTheme theme;

  @override
  State<RebirthPanel> createState() => _RebirthPanelState();
}

class _RebirthPanelState extends State<RebirthPanel> {
  bool _rebirthDialogOpen = false;

  GameService get game => widget.game;
  BackgroundTheme get theme => widget.theme;

  Future<void> _onRebirthPressed(BuildContext context) async {
    if (game.hasActiveAutoBattle) {
      UiSound.locked(context);
      showGameSnackBar(
        context,
        message: 'Finish auto battle before rebirthing.',
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    if (!game.canRebirth) {
      UiSound.locked(context);
      showGameSnackBar(
        context,
        message:
            'Earn ${formatCoins(game.rebirthRequirement)} animal income to rebirth.',
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    if (_rebirthDialogOpen) return;

    _rebirthDialogOpen = true;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) =>
            _RebirthConfirmDialog(game: game, theme: theme),
      );

      if (!context.mounted) return;

      if (confirmed == true) {
        final success = game.performRebirth();
        if (success && context.mounted) {
          UiSound.rewardBigTriumph(context);
          showGameSnackBar(
            context,
            message: 'Rebirth complete! Permanent income boost increased.',
            backgroundColor: theme.primaryColor,
          );
        }
      }
    } finally {
      _rebirthDialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rebirthLevel = game.rebirthLevel;
    final currentMultiplier = game.incomeMultiplier;
    final nextMultiplier = RebirthLogic.nextIncomeMultiplier(rebirthLevel);
    final canRebirth = game.canRebirth;
    final lifetime = game.lifetimeCoinsEarned;
    final requirement = game.rebirthRequirement;

    return Container(
      decoration: GameTheme.cardDecoration(
        theme,
        borderColor: canRebirth ? theme.panelAccentColor : null,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('🔁', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rebirth Level $rebirthLevel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.cardTextPrimaryColor,
                      ),
                    ),
                    Text(
                      canRebirth
                          ? 'Ready to rebirth for a permanent income boost'
                          : 'Earn ${formatCoins(requirement)} animal income to rebirth',
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
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final stackChips = constraints.maxWidth < 280;
              final chips = [
                _InfoChip(
                  label: 'Income',
                  value: RebirthLogic.formatMultiplier(currentMultiplier),
                  theme: theme,
                  color: theme.primaryColor,
                ),
                _InfoChip(
                  label: 'Next Rebirth',
                  value: RebirthLogic.formatMultiplier(nextMultiplier),
                  theme: theme,
                  color: theme.secondaryColor,
                ),
              ];

              if (stackChips) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [chips[0], const SizedBox(height: 8), chips[1]],
                );
              }

              return Row(
                children: [
                  Expanded(child: chips[0]),
                  const SizedBox(width: 8),
                  Expanded(child: chips[1]),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Animal Income This Rebirth: ${formatCoins(lifetime)} / ${formatCoins(requirement)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.cardTextSecondaryColor,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => _onRebirthPressed(context),
            style: GameTheme.filledButton(
              theme,
              color: canRebirth ? theme.panelAccentColor : theme.disabledColor,
              height: 48,
            ),
            icon: Icon(
              canRebirth ? Icons.autorenew_rounded : Icons.lock_rounded,
            ),
            label: Text(
              canRebirth
                  ? 'Rebirth · Next ${RebirthLogic.formatMultiplier(nextMultiplier)}'
                  : 'Rebirth Locked',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _RebirthConfirmDialog extends StatelessWidget {
  const _RebirthConfirmDialog({required this.game, required this.theme});

  final GameService game;
  final BackgroundTheme theme;

  @override
  Widget build(BuildContext context) {
    final currentLevel = game.rebirthLevel;
    final newLevel = currentLevel + 1;
    final currentMultiplier = game.incomeMultiplier;
    final newMultiplier = RebirthLogic.incomeMultiplier(newLevel);
    final requirement = game.rebirthRequirement;

    return AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GameTheme.cardRadius),
      ),
      title: Text(
        'Rebirth?',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.cardTextPrimaryColor,
        ),
      ),
      content: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rebirth resets your coins, animals, upgrades, Luck, and quest '
                  'progress, but permanently doubles your total income. Secret '
                  'reward animals are kept.',
                  style: TextStyle(
                    height: 1.4,
                    color: theme.cardTextSecondaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                _DialogRow(
                  label: 'Rebirth Level',
                  current: '$currentLevel',
                  next: '$newLevel',
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _DialogRow(
                  label: 'Income Multiplier',
                  current: RebirthLogic.formatMultiplier(currentMultiplier),
                  next: RebirthLogic.formatMultiplier(newMultiplier),
                  theme: theme,
                ),
                const SizedBox(height: 8),
                Text(
                  'Requirement met: ${formatCoins(game.lifetimeCoinsEarned)} / '
                  '${formatCoins(requirement)} animal income',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.cardTextSecondaryColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: theme.cardTextSecondaryColor,
          ),
          icon: const Icon(Icons.close_rounded),
          label: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: theme.panelAccentColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          icon: const Icon(Icons.autorenew_rounded),
          label: const Text('Rebirth'),
        ),
      ],
    );
  }
}

class _DialogRow extends StatelessWidget {
  const _DialogRow({
    required this.label,
    required this.current,
    required this.next,
    required this.theme,
  });

  final String label;
  final String current;
  final String next;
  final BackgroundTheme theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.cardTextPrimaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: Text(current)),
            const Text('→'),
            Expanded(
              child: Text(
                next,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
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
    return Container(
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
            style: TextStyle(fontSize: 11, color: theme.cardTextSecondaryColor),
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
    );
  }
}
