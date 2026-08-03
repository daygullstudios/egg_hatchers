import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../models/animal.dart';
import '../models/background_theme.dart';
import '../models/egg.dart';
import '../models/egg_mastery_progress.dart';
import '../services/custom_sprite_service.dart';
import '../utils/built_in_egg_logic.dart';
import '../utils/egg_mastery_logic.dart';
import '../theme/game_theme.dart';
import '../utils/format_utils.dart';
import 'game_sprite.dart';

/// A shop card for buying an egg.
class EggCard extends StatelessWidget {
  const EggCard({
    super.key,
    required this.egg,
    required this.isUnlocked,
    required this.canAfford,
    required this.lifetimeCoinsEarned,
    required this.onBuy,
    required this.theme,
    this.buyButtonKey,
    this.isCustomEgg = false,
    this.customSprites,
    this.tripleHatchCost,
    this.canAffordTripleHatch = false,
    this.onTripleHatch,
    this.battleTokens,
    this.masteryProgress,
    this.unlockMessageOverride,
  });

  final Egg egg;
  final bool isUnlocked;
  final bool canAfford;
  final int lifetimeCoinsEarned;
  final VoidCallback onBuy;
  final GlobalKey? buyButtonKey;
  final BackgroundTheme theme;
  final bool isCustomEgg;
  final CustomSpriteService? customSprites;
  final int? tripleHatchCost;
  final bool canAffordTripleHatch;
  final VoidCallback? onTripleHatch;
  final int? battleTokens;
  final EggMasteryProgress? masteryProgress;
  final String? unlockMessageOverride;

  bool get _showEggMastery => EggMasteryLogic.isMasteryEligibleEgg(egg.id);

  bool get _usesBattleTokens => egg.usesBattleTokens;

  String get _notEnoughMessage =>
      _usesBattleTokens ? 'Not enough Battle Tokens.' : 'Not enough coins';

  @override
  Widget build(BuildContext context) {
    final possibleAnimals = egg.possibleAnimalIds
        .map(GameData.animalById)
        .whereType<Animal>()
        .toList();

    final unlockProgress = egg.unlockLifetimeCoins > 0
        ? (lifetimeCoinsEarned / egg.unlockLifetimeCoins).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      decoration: GameTheme.cardDecoration(theme, locked: !isUnlocked),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final stackPrice = constraints.maxWidth < 360;
                final titleStyle = TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked
                      ? theme.cardTextPrimaryColor
                      : theme.disabledColor,
                );
                final priceChip = _PriceChip(
                  theme: theme,
                  cost: egg.cost,
                  usesBattleTokens: _usesBattleTokens,
                );

                if (stackPrice) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _EggArtwork(
                            egg: egg,
                            theme: theme,
                            isUnlocked: isUnlocked,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  egg.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: titleStyle,
                                ),
                                if (egg.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    egg.description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.cardTextSecondaryColor,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      priceChip,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EggArtwork(
                      egg: egg,
                      theme: theme,
                      isUnlocked: isUnlocked,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            egg.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle,
                          ),
                          if (egg.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              egg.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.cardTextSecondaryColor,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    priceChip,
                  ],
                );
              },
            ),
            if (_usesBattleTokens && battleTokens != null) ...[
              const SizedBox(height: 10),
              Text(
                'Your Battle Tokens: $battleTokens',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryColor,
                ),
              ),
            ],
            if (!isUnlocked && !isCustomEgg) ...[
              const SizedBox(height: 14),
              Text(
                _usesBattleTokens
                    ? 'Hatch an animal to unlock Boss Battles and Battle Eggs.'
                    : (unlockMessageOverride ?? egg.unlockMessage),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryColor,
                ),
              ),
              if (egg.unlockLifetimeCoins > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: unlockProgress,
                    minHeight: 8,
                    backgroundColor:
                        theme.disabledColor.withValues(alpha: 0.2),
                    color: theme.secondaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Progress: ${formatCoins(lifetimeCoinsEarned)} / ${formatCoins(egg.unlockLifetimeCoins)} lifetime',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.cardTextSecondaryColor,
                  ),
                ),
              ],
            ],
            if (_showEggMastery) ...[
              const SizedBox(height: 14),
              _EggMasterySection(
                theme: theme,
                progress: masteryProgress ??
                    EggMasteryProgress(eggId: egg.id),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              'Possible animals:',
              style: GameTheme.sectionTitle(theme, size: 14).copyWith(
                color: theme.cardTextPrimaryColor,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final animal in possibleAnimals)
                  Chip(
                    avatar: SizedBox(
                      width: 24,
                      height: 24,
                      child: GameSprite(
                        customSprite:
                            customSprites?.getDisplaySprite(animal.id),
                        animalId: animal.id,
                        spritePath: animal.spritePath,
                        fallbackEmoji: animal.emoji,
                        size: 24,
                        emojiFontSize: 16,
                      ),
                    ),
                    label: Text(
                      '${animal.name} · '
                      '${BuiltInEggLogic.roundedChancePercent(egg, animal.id)}%',
                    ),
                    backgroundColor: animal.rarity == Rarity.unknown
                        ? GameTheme.rarityBadgeFill(animal.rarity)
                        : GameTheme.rarityAccent(animal.rarity)
                            .withValues(alpha: 0.12),
                    side: BorderSide(
                      color: GameTheme.rarityBorderColor(animal.rarity, theme),
                      width: animal.rarity == Rarity.unknown ? 2 : 1.5,
                    ),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: animal.rarity == Rarity.unknown
                          ? GameTheme.rarityBadgeTextColor(animal.rarity, theme)
                          : GameTheme.rarityAccent(animal.rarity),
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            KeyedSubtree(
              key: buyButtonKey,
              child: FilledButton(
              onPressed: onBuy,
              style: GameTheme.filledButton(
                theme,
                color: !isUnlocked || !canAfford
                    ? theme.disabledColor
                    : theme.primaryColor,
              ),
              child: Text(
                !isUnlocked
                    ? 'Locked 🔒'
                    : canAfford
                        ? 'Buy & Hatch 🐣'
                        : _notEnoughMessage,
              ),
            ),
            ),
            if (onTripleHatch != null && tripleHatchCost != null) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: isUnlocked ? onTripleHatch : onBuy,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  foregroundColor: isUnlocked && canAffordTripleHatch
                      ? theme.secondaryColor
                      : theme.disabledColor,
                  side: BorderSide(
                    color: isUnlocked && canAffordTripleHatch
                        ? theme.secondaryColor
                        : theme.disabledColor,
                  ),
                ),
                child: isUnlocked
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Triple Hatch',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _usesBattleTokens
                                ? '⚔️ $tripleHatchCost'
                                : '🪙 ${formatCoins(tripleHatchCost!)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Triple Hatch',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EggMasterySection extends StatelessWidget {
  const _EggMasterySection({
    required this.theme,
    required this.progress,
  });

  final BackgroundTheme theme;
  final EggMasteryProgress progress;

  @override
  Widget build(BuildContext context) {
    final level = progress.masteryLevel;
    final maxLevel = EggMasteryLogic.maxLevel;
    final bonusPercent = EggMasteryLogic.incomeBonusPercent(level);
    final atMax = level >= maxLevel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.secondaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.secondaryColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Egg Mastery',
            style: GameTheme.sectionTitle(theme, size: 14).copyWith(
              color: theme.cardTextPrimaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mastery Lv. $level / $maxLevel',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: theme.cardTextPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            atMax
                ? 'Max Mastery'
                : EggMasteryLogic.progressLabel(progress),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.cardTextSecondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Income bonus: +$bonusPercent%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.secondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _EggArtwork extends StatelessWidget {
  const _EggArtwork({
    required this.egg,
    required this.theme,
    required this.isUnlocked,
  });

  final Egg egg;
  final BackgroundTheme theme;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isUnlocked
            ? theme.secondaryColor.withValues(alpha: 0.18)
            : theme.disabledColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked
              ? theme.secondaryColor.withValues(alpha: 0.45)
              : theme.disabledColor,
        ),
      ),
      child: isUnlocked
          ? GameEggSprite(
              egg: egg,
              size: 56,
              semanticLabel: egg.name,
              emojiFontSize: 40,
            )
          : Text(
              '🔒',
              style: TextStyle(
                fontSize: 40,
                color: theme.disabledColor,
              ),
            ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({
    required this.theme,
    required this.cost,
    required this.usesBattleTokens,
  });

  final BackgroundTheme theme;
  final int cost;
  final bool usesBattleTokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.panelAccentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.panelAccentColor.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        usesBattleTokens ? '⚔️ $cost' : '🪙 ${formatCoins(cost)}',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.cardTextPrimaryColor,
        ),
      ),
    );
  }
}
