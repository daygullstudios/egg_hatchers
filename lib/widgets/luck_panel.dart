import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../models/background_theme.dart';
import '../services/game_service.dart';
import '../theme/game_theme.dart';
import '../utils/format_utils.dart';
import '../utils/luck_logic.dart';
import '../utils/snackbar_utils.dart';
import '../utils/ui_sound.dart';

/// Hatchery panel for upgrading Luck and viewing mutation odds.
class LuckPanel extends StatelessWidget {
  const LuckPanel({
    super.key,
    required this.game,
    required this.theme,
  });

  final GameService game;
  final BackgroundTheme theme;

  void _upgrade(BuildContext context) {
    if (game.isLuckMaxed) {
      UiSound.locked(context);
      return;
    }

    if (!game.canAffordLuckUpgrade()) {
      UiSound.locked(context);
      showGameSnackBar(
        context,
        message: 'Not enough coins to upgrade Luck.',
        backgroundColor: Colors.red.shade400,
      );
      return;
    }

    final newLevel = game.upgradeLuck();
    if (newLevel != null && context.mounted) {
      UiSound.purchase(context);
      showGameSnackBar(
        context,
        message: 'Luck upgraded to Level $newLevel!',
        backgroundColor: theme.primaryColor,
      );
    }
  }

  String _formatPercent(double value) {
    if (value == value.roundToDouble()) {
      return '${value.round()}%';
    }
    return '${value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')}%';
  }

  @override
  Widget build(BuildContext context) {
    final luckLevel = game.luckLevel;
    final chances = LuckLogic.mutationPercentages(
      luckLevel,
      bossMutationUnlocked: game.bossMutationUnlocked,
    );
    final cost = game.luckUpgradeCost;
    final isMaxed = game.isLuckMaxed;
    final canAfford = game.canAffordLuckUpgrade();

    return Container(
      decoration: GameTheme.cardDecoration(theme),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('🍀', style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Luck Level $luckLevel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.cardTextPrimaryColor,
                      ),
                    ),
                    Text(
                      isMaxed
                          ? 'Max Level — best mutation odds'
                          : 'Better mutations when hatching eggs',
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
          Text(
            'Mutation chances',
            style: GameTheme.sectionTitle(theme, size: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final mutation in GameData.mutations)
                if (mutation.id != 'boss' || game.bossMutationUnlocked)
                  _ChanceChip(
                    label: mutation.isNormal
                        ? 'Normal'
                        : '${mutation.icon} ${mutation.displayName}',
                    percent: _formatPercent(chances[mutation.id] ?? 0),
                  color: mutation.isNormal
                      ? theme.cardTextSecondaryColor
                      : GameTheme.mutationAccent(mutation.id),
                  theme: theme,
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (isMaxed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.panelAccentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.cardBorderColor),
              ),
              child: Text(
                'Max Level',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            )
          else
            FilledButton.icon(
              onPressed: () => _upgrade(context),
              style: GameTheme.filledButton(
                theme,
                color: canAfford ? theme.secondaryColor : theme.disabledColor,
                height: 48,
              ),
              icon: const Icon(Icons.upgrade_rounded),
              label: Text(
                'Upgrade Luck · 🪙 ${formatCoins(cost)}',
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
}

class _ChanceChip extends StatelessWidget {
  const _ChanceChip({
    required this.label,
    required this.percent,
    required this.color,
    required this.theme,
  });

  final String label;
  final String percent;
  final Color color;
  final BackgroundTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        '$label $percent',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: theme.cardTextPrimaryColor,
        ),
      ),
    );
  }
}
