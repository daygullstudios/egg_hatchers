import 'package:flutter/material.dart';

import '../data/audio_assets.dart';
import '../services/game_service.dart';
import '../theme/game_theme.dart';
import '../models/background_theme.dart';
import '../utils/egg_shard_logic.dart';
import '../utils/snackbar_utils.dart';
import '../utils/ui_sound.dart';
import 'audio_scope.dart';

/// Egg Shard limit-break upgrades on the Battles screen.
class EggShardUpgradesCard extends StatelessWidget {
  const EggShardUpgradesCard({
    super.key,
    required this.theme,
    required this.game,
  });

  final BackgroundTheme theme;
  final GameService game;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: GameTheme.cardDecoration(theme),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '🥚',
                style: TextStyle(fontSize: 24, color: theme.primaryColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Egg Shard Upgrades',
                  style: GameTheme.sectionTitle(theme, size: 18),
                ),
              ),
              Text(
                '${game.eggShards} Shards',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.secondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _EggShardUpgradeTile(
            theme: theme,
            title: 'Battle Limit Break',
            description:
                'Raises Homing and Shot Speed max levels by +2 each.',
            level: game.battleLimitBreakLevel,
            maxLevel: EggShardLogic.battleLimitBreakMaxLevel,
            nextCost: EggShardLogic.battleLimitBreakCost(
              game.battleLimitBreakLevel,
            ),
            canAfford: game.eggShards >=
                EggShardLogic.battleLimitBreakCost(
                  game.battleLimitBreakLevel,
                ),
            statusLine:
                'Homing/Speed max: ${game.battleHomingMaxLevel}',
            onUpgrade: () => _purchase(
              context,
              game.purchaseBattleLimitBreak(),
              'Battle Limit Break purchased!',
            ),
          ),
          const SizedBox(height: 14),
          _EggShardUpgradeTile(
            theme: theme,
            title: 'Extra Life Limit Break',
            description: 'Raises Extra Life max level by +1.',
            level: game.extraLifeLimitBreakLevel,
            maxLevel: EggShardLogic.extraLifeLimitBreakMaxLevel,
            nextCost: EggShardLogic.extraLifeLimitBreakCost,
            canAfford:
                game.eggShards >= EggShardLogic.extraLifeLimitBreakCost,
            statusLine: 'Extra Life max: ${game.battleExtraLifeMaxLevel}',
            onUpgrade: () => _purchase(
              context,
              game.purchaseExtraLifeLimitBreak(),
              'Extra Life Limit Break purchased!',
            ),
          ),
          const SizedBox(height: 14),
          _EggShardUpgradeTile(
            theme: theme,
            title: 'Ancient Path Shortcut',
            description:
                'Reduces rebirth level required for rebirth-locked eggs by 1.',
            level: game.eggRebirthReductionLevel,
            maxLevel: EggShardLogic.eggRebirthReductionMaxLevel,
            nextCost: EggShardLogic.eggRebirthReductionCost(
              game.eggRebirthReductionLevel,
            ),
            canAfford: game.eggShards >=
                EggShardLogic.eggRebirthReductionCost(
                  game.eggRebirthReductionLevel,
                ),
            statusLine:
                'Rebirth reduction: -${game.eggRebirthReductionLevel}',
            onUpgrade: () => _purchase(
              context,
              game.purchaseEggRebirthReduction(),
              'Ancient Path Shortcut purchased!',
            ),
          ),
          const SizedBox(height: 14),
          _EggShardUpgradeTile(
            theme: theme,
            title: 'Sprite Canvas Plus',
            description:
                'Unlock 24×24 custom sprite canvas for new sprites.',
            level: game.customSpriteCanvasTier,
            maxLevel: EggShardLogic.customSpriteCanvasMaxLevel,
            nextCost: EggShardLogic.customSpriteCanvasCost,
            canAfford: game.eggShards >= EggShardLogic.customSpriteCanvasCost,
            statusLine:
                'Max canvas: ${game.maxCustomSpriteGridSize}×${game.maxCustomSpriteGridSize}',
            onUpgrade: () => _purchase(
              context,
              game.purchaseCustomSpriteCanvas(),
              'Sprite Canvas Plus unlocked!',
            ),
          ),
        ],
      ),
    );
  }

  void _purchase(BuildContext context, bool success, String message) {
    if (!success) {
      AudioScope.maybeOf(context)?.playSfx(Sfx.errorLocked);
      showGameSnackBar(
        context,
        message: 'Not enough Egg Shards.',
        backgroundColor: Colors.red.shade400,
      );
      return;
    }
    UiSound.purchase(context);
    showGameSnackBar(
      context,
      message: message,
      backgroundColor: Colors.green.shade700,
    );
  }
}

class _EggShardUpgradeTile extends StatelessWidget {
  const _EggShardUpgradeTile({
    required this.theme,
    required this.title,
    required this.description,
    required this.level,
    required this.maxLevel,
    required this.nextCost,
    required this.canAfford,
    required this.onUpgrade,
    this.statusLine,
  });

  final BackgroundTheme theme;
  final String title;
  final String description;
  final int level;
  final int maxLevel;
  final int nextCost;
  final bool canAfford;
  final VoidCallback onUpgrade;
  final String? statusLine;

  @override
  Widget build(BuildContext context) {
    final atMax = level >= maxLevel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: theme.cardTextPrimaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 13,
            color: theme.cardTextSecondaryColor,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Level $level / $maxLevel',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.cardTextPrimaryColor,
          ),
        ),
        if (statusLine != null) ...[
          const SizedBox(height: 4),
          Text(
            statusLine!,
            style: TextStyle(
              fontSize: 13,
              color: theme.cardTextSecondaryColor,
            ),
          ),
        ],
        if (!atMax) ...[
          const SizedBox(height: 4),
          Text(
            'Cost: $nextCost Egg Shards',
            style: TextStyle(
              fontSize: 13,
              color: theme.cardTextSecondaryColor,
            ),
          ),
        ],
        const SizedBox(height: 10),
        FilledButton(
          onPressed: atMax ? null : onUpgrade,
          style: GameTheme.filledButton(
            theme,
            color: atMax
                ? theme.disabledColor
                : (canAfford ? theme.primaryColor : theme.disabledColor),
          ),
          child: Text(atMax ? 'Max Level' : 'Upgrade'),
        ),
      ],
    );
  }
}
