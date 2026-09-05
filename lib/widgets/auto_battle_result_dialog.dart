import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../models/background_theme.dart';
import '../models/boss_battle.dart';
import '../services/custom_sprite_service.dart';
import '../theme/game_theme.dart';
import '../utils/format_utils.dart';
import 'boss_sprite.dart';
import 'game_sprite.dart';

/// Summary dialog after an auto battle run completes.
class AutoBattleResultDialog extends StatelessWidget {
  const AutoBattleResultDialog({
    super.key,
    required this.theme,
    required this.result,
    required this.customSprites,
  });

  final BackgroundTheme theme;
  final AutoBattleResult result;
  final CustomSpriteService customSprites;

  static Future<void> show(
    BuildContext context, {
    required BackgroundTheme theme,
    required AutoBattleResult result,
    required CustomSpriteService customSprites,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AutoBattleResultDialog(
        theme: theme,
        result: result,
        customSprites: customSprites,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final animal = GameData.animalById(result.fighter.animalId);
    final mutation = GameData.mutationById(result.fighter.mutationId) ??
        GameData.mutations.first;
    final lastLog = result.lastFightResult?.damageLog ?? const [];

    final title = result.wonAtLeastOne && !result.endedInDefeat
        ? 'Auto Battle Complete!'
        : result.wonAtLeastOne
            ? 'Auto Battle Over'
            : 'Auto Battle Failed';

    return AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GameTheme.cardRadius),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: result.wonAtLeastOne
              ? theme.secondaryColor
              : theme.disabledColor,
        ),
      ),
      content: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (animal != null)
                      GameSprite(
                        customSprite:
                            customSprites.getDisplaySprite(animal.id),
                        animalId: animal.id,
                        spritePath: animal.spritePath,
                        fallbackEmoji: mutation.displayEmoji(animal),
                        size: 56,
                        emojiFontSize: 32,
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.fighterDisplayName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.cardTextPrimaryColor,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'vs ${result.boss.name}',
                            style: TextStyle(
                              color: theme.cardTextSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    BossSprite(
                      spritePath: result.boss.spritePath,
                      fallbackEmoji: result.boss.emoji,
                      bossId: result.boss.id,
                      size: 64,
                      semanticLabel: result.boss.name,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SummaryRow(
                  theme: theme,
                  label: 'Bosses defeated',
                  value: '${result.bossesDefeated}',
                ),
                _SummaryRow(
                  theme: theme,
                  label: 'Fights attempted',
                  value: '${result.fightsAttempted}',
                ),
                _SummaryRow(
                  theme: theme,
                  label: 'Coins earned',
                  value: formatCoins(result.totalCoinsEarned),
                ),
                _SummaryRow(
                  theme: theme,
                  label: 'Battle Tokens earned',
                  value: '+${result.totalBattleTokensEarned}',
                ),
                _SummaryRow(
                  theme: theme,
                  label: 'Final animal HP',
                  value: formatCoins(result.finalAnimalHp),
                ),
                if (result.hitAutoBattleCap) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Auto battle limit reached.',
                    style: TextStyle(
                      color: theme.secondaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (result.fightsAttempted > 1) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Battle 1 was shown in detail. '
                    'Battles 2–${result.fightsAttempted} were auto-resolved.',
                    style: TextStyle(
                      color: theme.cardTextSecondaryColor,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
                if (lastLog.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Last fight log',
                    style: GameTheme.sectionTitle(theme, size: 14),
                  ),
                  const SizedBox(height: 6),
                  for (final entry in lastLog.take(6))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        entry.text,
                        style: TextStyle(
                          color: theme.cardTextSecondaryColor,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: const Text('Done'),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.theme,
    required this.label,
    required this.value,
  });

  final BackgroundTheme theme;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: theme.cardTextSecondaryColor,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.cardTextPrimaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
