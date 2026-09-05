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
              label: '${formatCoins(lifetimeCoinsEarned!)} lifetime',
              color: theme.secondaryColor,
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
  });

  final String icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
