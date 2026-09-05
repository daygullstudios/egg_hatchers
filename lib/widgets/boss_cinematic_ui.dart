import 'package:flutter/material.dart';

import '../models/background_theme.dart';
import '../utils/format_utils.dart';

/// Shared victory title, reward chips, and skip button for boss cinematics.
class BossCinematicVictoryOverlay extends StatelessWidget {
  const BossCinematicVictoryOverlay({
    super.key,
    required this.theme,
    required this.bossName,
    required this.defeatTitle,
    required this.coinReward,
    required this.tokenReward,
    this.animalRewardName,
    this.eggShardReward = 0,
    required this.titleProgress,
    required this.titleOpacity,
    required this.rewardsOpacity,
    required this.rewardsSlide,
    required this.canSkip,
    required this.onSkip,
  });

  final BackgroundTheme theme;
  final String bossName;
  final String defeatTitle;
  final int coinReward;
  final int tokenReward;
  final String? animalRewardName;
  final int eggShardReward;
  final double titleProgress;
  final double titleOpacity;
  final double rewardsOpacity;
  final double rewardsSlide;
  final bool canSkip;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 88),
            Opacity(
              opacity: titleOpacity,
              child: Transform.scale(
                scale: 0.75 + titleProgress * 0.25,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    defeatTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Color(0xFFFFEB3B),
                      shadows: [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 12,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Opacity(
              opacity: titleOpacity * 0.9,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bossName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.cardTextPrimaryColor.withValues(alpha: 0.95),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Opacity(
              opacity: rewardsOpacity,
              child: Transform.translate(
                offset: Offset(0, rewardsSlide),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (coinReward > 0)
                        BossCinematicRewardChip(
                          label: '🪙 +${formatCoins(coinReward)}',
                          color: Colors.amber.shade700,
                        ),
                      if (tokenReward > 0)
                        BossCinematicRewardChip(
                          label: '⚔️ +$tokenReward',
                          color: const Color(0xFF1565C0),
                        ),
                      if (eggShardReward > 0)
                        BossCinematicRewardChip(
                          label: '🥚 +$eggShardReward Shards',
                          color: const Color(0xFF558B2F),
                        ),
                      if (animalRewardName != null)
                        BossCinematicRewardChip(
                          label: 'Elite: $animalRewardName',
                          color: Colors.deepPurple.shade400,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (canSkip)
          Positioned(
            right: 16,
            bottom: 16,
            child: TextButton.icon(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                backgroundColor: Colors.black45,
              ),
              icon: const Icon(Icons.fast_forward_rounded),
              label: const Text('Skip'),
            ),
          ),
      ],
    );
  }
}

class BossCinematicRewardChip extends StatelessWidget {
  const BossCinematicRewardChip({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.75)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }
}
