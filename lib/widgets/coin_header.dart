import 'package:flutter/material.dart';

import '../models/background_theme.dart';
import '../utils/format_utils.dart';

/// Shows income details that complement the persistent AppBar coin balance.
class CoinStatsStrip extends StatelessWidget {
  const CoinStatsStrip({
    super.key,
    required this.coinsPerSecond,
    required this.theme,
    this.lifetimeCoinsEarned,
  });

  final int coinsPerSecond;
  final BackgroundTheme theme;
  final int? lifetimeCoinsEarned;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          _StatChip(
            icon: '⚡',
            label: '+$coinsPerSecond / sec',
            color: theme.primaryColor,
          ),
          if (lifetimeCoinsEarned != null)
            _StatChip(
              icon: '🏆',
              label: '${formatCoins(lifetimeCoinsEarned!)} earned',
              color: theme.secondaryColor,
              tooltip: 'Animal income earned this Rebirth.',
              showInfoIcon: true,
              onTap: () => _showAnimalIncomeExplanation(context),
            ),
        ],
      ),
    );
  }

  Future<void> _showAnimalIncomeExplanation(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          'Total animal income',
          style: TextStyle(
            color: theme.cardTextPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Coins earned by your animals since you started—or since your last '
          'Rebirth. Spending coins doesn’t reduce this total. It unlocks eggs '
          'and counts toward your next Rebirth.',
          style: TextStyle(
            color: theme.cardTextSecondaryColor,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
    this.tooltip,
    this.showInfoIcon = false,
    this.onTap,
  });

  final String icon;
  final String label;
  final Color color;
  final String? tooltip;
  final bool showInfoIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              if (showInfoIcon) ...[
                const SizedBox(width: 4),
                Icon(Icons.info_outline_rounded, size: 15, color: color),
              ],
            ],
          ),
        ),
      ),
    );

    if (tooltip == null) return chip;
    return Tooltip(
      message: tooltip,
      child: Semantics(button: onTap != null, label: tooltip, child: chip),
    );
  }
}
