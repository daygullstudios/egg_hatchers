import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../models/animal.dart';
import '../models/background_theme.dart';
import '../models/mutation.dart';
import '../services/custom_sprite_service.dart';
import '../theme/game_theme.dart';
import '../utils/format_utils.dart';
import 'game_sprite.dart';
import 'battling_dots_text.dart';

/// A rounded card showing one animal, mutation, stats, and an upgrade button.
class AnimalCard extends StatelessWidget {
  const AnimalCard({
    super.key,
    required this.animal,
    required this.theme,
    this.mutation,
    this.quantity,
    this.level,
    this.typeIncome,
    this.upgradeCost,
    this.showUpgradeButton = false,
    this.canAffordUpgrade = false,
    this.onUpgrade,
    this.upgradeButtonKey,
    this.compact = false,
    this.customSprites,
    this.useBaseNameForTitle = false,
    this.showSellButtons = false,
    this.sellValue,
    this.onSellOne,
    this.onSellAll,
    this.isProtected = false,
    this.isSecretReward = false,
    this.isEliteReward = false,
    this.isAutoBattling = false,
    this.autoBattleBossName,
    this.autoBattleCurrentHp,
    this.autoBattleMaxHp,
    this.autoBattleWins,
    this.autoBattleTimeRemaining,
    this.onBattlingTap,
  });

  final Animal animal;
  final BackgroundTheme theme;
  final CustomSpriteService? customSprites;
  final Mutation? mutation;
  final int? quantity;
  final int? level;
  final int? typeIncome;
  final int? upgradeCost;
  final bool showUpgradeButton;
  final bool canAffordUpgrade;
  final VoidCallback? onUpgrade;
  final GlobalKey? upgradeButtonKey;
  final bool compact;
  final bool useBaseNameForTitle;
  final bool showSellButtons;
  final int? sellValue;
  final VoidCallback? onSellOne;
  final VoidCallback? onSellAll;
  final bool isProtected;
  final bool isSecretReward;
  final bool isEliteReward;
  final bool isAutoBattling;
  final String? autoBattleBossName;
  final int? autoBattleCurrentHp;
  final int? autoBattleMaxHp;
  final int? autoBattleWins;
  final Duration? autoBattleTimeRemaining;
  final VoidCallback? onBattlingTap;

  String _formatCountdown(Duration duration) {
    final totalSeconds = duration.inSeconds;
    if (totalSeconds <= 0) return 'Resolving...';
    if (totalSeconds >= 60) {
      return '${totalSeconds ~/ 60}m ${totalSeconds % 60}s';
    }
    return '${totalSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final isOwned = quantity != null;
    final activeMutation = mutation ?? GameData.mutations.first;
    final displayName = useBaseNameForTitle
        ? animal.name
        : activeMutation.fullName(animal);
    final rarityColor = GameTheme.rarityAccent(animal.rarity);
    final rarityBorder = GameTheme.rarityBorderColor(animal.rarity, theme);
    final mutationColor = GameTheme.mutationAccent(activeMutation.id);
    final borderColor = activeMutation.isNormal ? rarityBorder : mutationColor;
    final textPrimary = activeMutation.isNormal
        ? theme.cardTextPrimaryColor
        : const Color(0xFF5D4037);
    final textSecondary = activeMutation.isNormal
        ? theme.cardTextSecondaryColor
        : const Color(0xFF795548);
    final showUpgrade = showUpgradeButton && !isAutoBattling;
    final showSell = showSellButtons && !isAutoBattling;

    if (isAutoBattling) {
      return _BattlingAnimalCard(
        animal: animal,
        theme: theme,
        activeMutation: activeMutation,
        displayName: displayName,
        borderColor: borderColor,
        rarityColor: rarityColor,
        compact: compact,
        customSprites: customSprites,
        isProtected: isProtected,
        isSecretReward: isSecretReward,
        isEliteReward: isEliteReward,
        autoBattleBossName: autoBattleBossName,
        autoBattleCurrentHp: autoBattleCurrentHp,
        autoBattleMaxHp: autoBattleMaxHp,
        autoBattleWins: autoBattleWins,
        autoBattleTimeRemaining: autoBattleTimeRemaining,
        onBattlingTap: onBattlingTap,
        formatCountdown: _formatCountdown,
      );
    }

    return Container(
      decoration: GameTheme.cardDecoration(
        theme,
        borderColor: borderColor,
        backgroundColor: activeMutation.isNormal
            ? null
            : GameTheme.mutationTint(activeMutation.id),
        extraShadows: activeMutation.isNormal
            ? GameTheme.rarityCardShadows(animal.rarity, theme)
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: compact ? 64 : 76,
                  height: compact ? 64 : 76,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: rarityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: borderColor.withValues(
                        alpha: (animal.rarity == Rarity.unknown ||
                                animal.rarity == Rarity.boss)
                            ? 0.95
                            : 0.45,
                      ),
                      width: (animal.rarity == Rarity.unknown ||
                              animal.rarity == Rarity.boss)
                          ? 2.5
                          : 2,
                    ),
                  ),
                  child: GameAnimalPortrait(
                    customSprite: customSprites?.getDisplaySprite(animal.id),
                    animalId: animal.id,
                    spritePath: animal.spritePath,
                    fallbackEmoji: activeMutation.displayEmoji(animal),
                    size: compact ? 48 : 58,
                    mutation: activeMutation,
                    semanticLabel: displayName,
                    emojiFontSize: compact ? 34 : 42,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: compact ? 17 : 21,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _RarityBadge(rarity: animal.rarity, theme: theme),
                          if (!activeMutation.isNormal)
                            _MutationBadge(mutation: activeMutation),
                          if (isEliteReward)
                            const _EliteBadge()
                          else if (isSecretReward)
                            const _SecretRewardBadge(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (isOwned) ...[
                        _InfoRow(
                          icon: '📦',
                          label: 'Owned: $quantity  •  Level $level',
                          compact: compact,
                          color: activeMutation.isNormal
                              ? theme.primaryColor
                              : const Color(0xFF4DB6AC),
                        ),
                        const SizedBox(height: 4),
                        _InfoRow(
                          icon: '💰',
                          label: 'Income: $typeIncome / sec',
                          compact: compact,
                          highlight: true,
                          color: activeMutation.isNormal
                              ? theme.secondaryColor
                              : const Color(0xFFE65100),
                        ),
                      ] else
                        _InfoRow(
                          icon: '💰',
                          label: 'Base: ${animal.coinsPerSecond} / sec',
                          compact: compact,
                          color: textSecondary,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (showUpgrade && upgradeCost != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.cardBorderColor.withValues(alpha: 0.35),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stackUpgrade = constraints.maxWidth < 340;

                    if (stackUpgrade) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Upgrade: 🪙 $upgradeCost',
                            style: TextStyle(
                              fontSize: compact ? 14 : 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          KeyedSubtree(
                            key: upgradeButtonKey,
                            child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: onUpgrade,
                              style: GameTheme.filledButton(
                                theme,
                                color: canAffordUpgrade
                                    ? theme.primaryColor
                                    : theme.disabledColor,
                                height: compact ? 44 : 48,
                              ),
                              icon: const Icon(Icons.upgrade_rounded),
                              label: const Text('Upgrade'),
                            ),
                          ),
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Upgrade: 🪙 $upgradeCost',
                            style: TextStyle(
                              fontSize: compact ? 14 : 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        KeyedSubtree(
                          key: upgradeButtonKey,
                          child: FilledButton.icon(
                          onPressed: onUpgrade,
                          style: GameTheme.filledButton(
                            theme,
                            color: canAffordUpgrade
                                ? theme.primaryColor
                                : theme.disabledColor,
                            height: compact ? 44 : 48,
                          ).copyWith(
                            padding: WidgetStatePropertyAll(
                              EdgeInsets.symmetric(
                                horizontal: compact ? 14 : 18,
                                vertical: compact ? 10 : 12,
                              ),
                            ),
                            minimumSize: WidgetStatePropertyAll(
                              Size(0, compact ? 44 : 48),
                            ),
                            textStyle: WidgetStatePropertyAll(
                              TextStyle(
                                fontSize: compact ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.upgrade_rounded),
                          label: const Text('Upgrade'),
                        ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            if (showSell && !isProtected && sellValue != null && isOwned) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.secondaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.cardBorderColor.withValues(alpha: 0.35),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stackActions = constraints.maxWidth < 340;
                    final sellAllVisible =
                        (quantity ?? 0) > 1 && onSellAll != null;

                    final sellLabel = Text(
                      'Sell: 🪙 $sellValue',
                      style: TextStyle(
                        fontSize: compact ? 14 : 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    );

                    final sellOneButton = FilledButton.icon(
                      onPressed: onSellOne,
                      style: GameTheme.filledButton(
                        theme,
                        color: theme.secondaryColor,
                        height: compact ? 40 : 44,
                      ).copyWith(
                        padding: WidgetStatePropertyAll(
                          EdgeInsets.symmetric(
                            horizontal: compact ? 12 : 16,
                            vertical: compact ? 8 : 10,
                          ),
                        ),
                        minimumSize: WidgetStatePropertyAll(
                          Size(0, compact ? 40 : 44),
                        ),
                      ),
                      icon: const Icon(Icons.sell_rounded),
                      label: const Text('Sell 1'),
                    );

                    final sellAllButton = sellAllVisible
                        ? OutlinedButton.icon(
                            onPressed: onSellAll,
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size(0, compact ? 40 : 44),
                              side: BorderSide(color: theme.secondaryColor),
                              foregroundColor: theme.secondaryColor,
                            ),
                            icon: const Icon(Icons.sell_outlined),
                            label: const Text('Sell All'),
                          )
                        : null;

                    if (stackActions) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          sellLabel,
                          const SizedBox(height: 10),
                          sellOneButton,
                          if (sellAllButton != null) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: sellAllButton,
                            ),
                          ],
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: sellLabel),
                        const SizedBox(width: 8),
                        sellOneButton,
                        if (sellAllButton != null) ...[
                          const SizedBox(width: 8),
                          sellAllButton,
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact battle-focused card layout while an animal is auto battling.
class _BattlingAnimalCard extends StatelessWidget {
  const _BattlingAnimalCard({
    required this.animal,
    required this.theme,
    required this.activeMutation,
    required this.displayName,
    required this.borderColor,
    required this.rarityColor,
    required this.compact,
    required this.customSprites,
    required this.isProtected,
    required this.isSecretReward,
    required this.isEliteReward,
    required this.autoBattleBossName,
    required this.autoBattleCurrentHp,
    required this.autoBattleMaxHp,
    required this.autoBattleWins,
    required this.autoBattleTimeRemaining,
    required this.onBattlingTap,
    required this.formatCountdown,
  });

  final Animal animal;
  final BackgroundTheme theme;
  final Mutation activeMutation;
  final String displayName;
  final Color borderColor;
  final Color rarityColor;
  final bool compact;
  final CustomSpriteService? customSprites;
  final bool isProtected;
  final bool isSecretReward;
  final bool isEliteReward;
  final String? autoBattleBossName;
  final int? autoBattleCurrentHp;
  final int? autoBattleMaxHp;
  final int? autoBattleWins;
  final Duration? autoBattleTimeRemaining;
  final VoidCallback? onBattlingTap;
  final String Function(Duration) formatCountdown;

  @override
  Widget build(BuildContext context) {
    final spriteSize = compact ? 52.0 : 58.0;
    final wins = autoBattleWins ?? 0;
    final nextText = autoBattleTimeRemaining != null
        ? formatCountdown(autoBattleTimeRemaining!)
        : null;

    return Container(
      decoration: GameTheme.cardDecoration(
        theme,
        borderColor: borderColor.withValues(alpha: 0.65),
        backgroundColor: Color.alphaBlend(
          Colors.black.withValues(alpha: 0.42),
          activeMutation.isNormal
              ? theme.cardColor
              : GameTheme.mutationTint(activeMutation.id),
        ),
        extraShadows: activeMutation.isNormal
            ? GameTheme.rarityCardShadows(animal.rarity, theme)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onBattlingTap,
          borderRadius: BorderRadius.circular(GameTheme.cardRadius),
          child: Padding(
            padding: EdgeInsets.all(compact ? 12 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: spriteSize + 8,
                      height: spriteSize + 8,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: rarityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: borderColor.withValues(alpha: 0.55),
                          width: (animal.rarity == Rarity.unknown ||
                                  animal.rarity == Rarity.boss)
                              ? 2
                              : 1.5,
                        ),
                      ),
                      child: Opacity(
                        opacity: 0.85,
                        child: GameAnimalPortrait(
                          customSprite:
                              customSprites?.getDisplaySprite(animal.id),
                          animalId: animal.id,
                          spritePath: animal.spritePath,
                          fallbackEmoji: activeMutation.displayEmoji(animal),
                          size: spriteSize,
                          mutation: activeMutation,
                          semanticLabel: displayName,
                          emojiFontSize: compact ? 30 : 34,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compact ? 15 : 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withValues(alpha: 0.95),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              _RarityBadge(rarity: animal.rarity, theme: theme),
                              if (!activeMutation.isNormal)
                                _MutationBadge(mutation: activeMutation),
                              if (isEliteReward)
                                const _EliteBadge()
                              else if (isSecretReward)
                                const _SecretRewardBadge(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                BattlingDotsText(
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 6),
                    ],
                  ),
                ),
                if (autoBattleBossName != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'vs $autoBattleBossName',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: compact ? 12 : 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (autoBattleCurrentHp != null &&
                    autoBattleMaxHp != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'HP: ${formatCoins(autoBattleCurrentHp!)} / '
                    '${formatCoins(autoBattleMaxHp!)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (nextText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Wins: $wins · Next: $nextText',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: compact ? 11 : 12,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                    'Wins: $wins',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: compact ? 11 : 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.compact,
    required this.color,
    this.highlight = false,
  });

  final String icon;
  final String label;
  final bool compact;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: TextStyle(fontSize: compact ? 13 : 15)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: compact ? 13 : 15,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _RarityBadge extends StatelessWidget {
  const _RarityBadge({
    required this.rarity,
    required this.theme,
  });

  final Rarity rarity;
  final BackgroundTheme theme;

  @override
  Widget build(BuildContext context) {
    final isSpecialRarity =
        rarity == Rarity.unknown || rarity == Rarity.boss;
    final color = GameTheme.rarityAccent(rarity);
    final borderColor = GameTheme.rarityBorderColor(rarity, theme);
    final textColor = GameTheme.rarityBadgeTextColor(rarity, theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: isSpecialRarity
            ? null
            : LinearGradient(
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.08),
                ],
              ),
        color: isSpecialRarity ? GameTheme.rarityBadgeFill(rarity) : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: rarity == Rarity.boss ? 2 : isSpecialRarity ? 2 : 1.5,
        ),
        boxShadow: isSpecialRarity
            ? GameTheme.rarityCardShadows(rarity, theme)
            : null,
      ),
      child: Text(
        rarity.label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: isSpecialRarity ? 0.5 : 0,
        ),
      ),
    );
  }
}

class _MutationBadge extends StatelessWidget {
  const _MutationBadge({required this.mutation});

  final Mutation mutation;

  @override
  Widget build(BuildContext context) {
    final color = GameTheme.mutationAccent(mutation.id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        '${mutation.icon} ${mutation.displayName}'.trim(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SecretRewardBadge extends StatelessWidget {
  const _SecretRewardBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF7E57C2).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7E57C2), width: 1.5),
      ),
      child: const Text(
        'Secret Reward',
        style: TextStyle(
          color: Color(0xFF7E57C2),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EliteBadge extends StatelessWidget {
  const _EliteBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8F00).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF8F00), width: 1.5),
      ),
      child: const Text(
        'Elite',
        style: TextStyle(
          color: Color(0xFFE65100),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
