import 'package:flutter/material.dart';

import '../data/boss_data.dart';
import '../data/game_data.dart';
import '../models/background_theme.dart';
import '../models/owned_animal.dart';
import '../services/custom_sprite_service.dart';
import '../services/game_service.dart';
import '../theme/game_theme.dart';
import '../utils/snackbar_utils.dart';
import 'animal_card.dart';

/// Lists owned animals in separate Normal and Mutated sections.
class OwnedAnimalList extends StatelessWidget {
  const OwnedAnimalList({
    super.key,
    required this.game,
    required this.onUpgrade,
    required this.theme,
    this.compact = false,
    this.separatorHeight = 8,
    this.embedInParentScroll = false,
    this.customSprites,
    this.showSellButtons = false,
    this.onSellOne,
    this.onSellAll,
    this.firstCardUpgradeKey,
    this.entries,
    this.showSectionHeaders = true,
    this.sortEntries = true,
  });

  final GameService game;
  final BackgroundTheme theme;
  final CustomSpriteService? customSprites;
  final GlobalKey? firstCardUpgradeKey;
  final void Function(
    String animalId,
    String mutationId,
    String displayName,
    bool isProtected,
  )
  onUpgrade;
  final void Function(
    String animalId,
    String mutationId,
    String displayName,
    int coins,
    bool isProtected,
  )?
  onSellOne;
  final void Function(
    String animalId,
    String mutationId,
    String displayName,
    int quantity,
    int totalCoins,
    bool isProtected,
  )?
  onSellAll;
  final bool showSellButtons;
  final bool compact;
  final double separatorHeight;
  final bool embedInParentScroll;
  final List<OwnedAnimal>? entries;
  final bool showSectionHeaders;
  final bool sortEntries;

  @override
  Widget build(BuildContext context) {
    final source = entries ?? game.ownedAnimals;
    final normal = _sorted(
      source.where((owned) => owned.mutationId == 'none').toList(),
    );
    final mutated = _sorted(
      source.where((owned) => owned.mutationId != 'none').toList(),
    );

    if (normal.isEmpty && mutated.isEmpty) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[
      if (normal.isNotEmpty) ...[
        if (showSectionHeaders) ...[
          _SectionHeader(
            title: '🐾 Normal Animals',
            compact: compact,
            theme: theme,
          ),
          SizedBox(height: separatorHeight),
        ],
        ..._buildCards(context, normal, firstCardIndexOffset: 0),
      ],
      if (mutated.isNotEmpty) ...[
        if (showSectionHeaders) ...[
          SizedBox(height: separatorHeight * 2),
          _SectionHeader(
            title: '✨ Mutated Animals',
            compact: compact,
            theme: theme,
          ),
          SizedBox(height: separatorHeight),
        ] else if (normal.isNotEmpty)
          SizedBox(height: separatorHeight),
        ..._buildCards(context, mutated, firstCardIndexOffset: normal.length),
      ],
    ];

    if (embedInParentScroll) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: children,
      );
    }

    return ListView(children: children);
  }

  List<OwnedAnimal> _sorted(List<OwnedAnimal> entries) {
    final copy = List<OwnedAnimal>.from(entries);
    if (sortEntries) {
      copy.sort((a, b) => GameData.compareOwnedAnimals(a.animalId, b.animalId));
    }
    return copy;
  }

  List<Widget> _buildCards(
    BuildContext context,
    List<OwnedAnimal> entries, {
    required int firstCardIndexOffset,
  }) {
    return [
      for (var i = 0; i < entries.length; i++) ...[
        if (i > 0) SizedBox(height: separatorHeight),
        _buildCard(
          context,
          entries[i],
          isFirstCard: firstCardIndexOffset + i == 0,
        ),
      ],
    ];
  }

  Widget _buildCard(
    BuildContext context,
    OwnedAnimal owned, {
    bool isFirstCard = false,
  }) {
    final animal = GameData.animalById(owned.animalId);
    if (animal == null) return const SizedBox.shrink();

    final mutation =
        GameData.mutationById(owned.mutationId) ?? GameData.mutations.first;
    final displayName = mutation.fullName(animal);
    final isBattling = game.isOwnedStackAutoBattling(owned);
    final activeBattle = game.activeAutoBattle;
    final boss = activeBattle != null
        ? BossData.bossById(activeBattle.bossId)
        : null;
    final canSell = showSellButtons && !owned.isProtected && !isBattling;

    return AnimalCard(
      animal: animal,
      theme: theme,
      upgradeButtonKey: isFirstCard ? firstCardUpgradeKey : null,
      mutation: mutation,
      quantity: owned.quantity,
      level: owned.level,
      typeIncome: isBattling ? 0 : game.incomeForOwned(animal, owned),
      upgradeCost: GameService.upgradeCostFor(animal, owned),
      showUpgradeButton: true,
      canAffordUpgrade:
          !isBattling &&
          game.canAffordUpgrade(
            animal.id,
            owned.mutationId,
            isProtected: owned.isProtected,
          ),
      onUpgrade: () => onUpgrade(
        animal.id,
        owned.mutationId,
        displayName,
        owned.isProtected,
      ),
      showSellButtons: canSell,
      isProtected: owned.isProtected,
      isSecretReward: owned.isSecretReward,
      isEliteReward: owned.isEliteReward,
      isAutoBattling: isBattling,
      autoBattleBossName: isBattling ? boss?.name : null,
      autoBattleCurrentHp: isBattling ? activeBattle?.currentHp : null,
      autoBattleMaxHp: isBattling ? activeBattle?.maxHp : null,
      autoBattleWins: isBattling ? activeBattle?.battlesWon : null,
      autoBattleTimeRemaining: isBattling
          ? game.timeUntilNextAutoBattleFight()
          : null,
      onBattlingTap: isBattling
          ? () {
              showGameSnackBar(
                context,
                message: 'This animal is battling.',
                backgroundColor: Colors.orange.shade700,
              );
            }
          : null,
      sellValue: canSell ? GameService.sellValueFor(animal, owned) : null,
      onSellOne: canSell && onSellOne != null
          ? () {
              final coins = GameService.sellValueFor(animal, owned);
              onSellOne!(
                animal.id,
                owned.mutationId,
                displayName,
                coins,
                owned.isProtected,
              );
            }
          : null,
      onSellAll: canSell && owned.quantity > 1 && onSellAll != null
          ? () {
              final unit = GameService.sellValueFor(animal, owned);
              onSellAll!(
                animal.id,
                owned.mutationId,
                displayName,
                owned.quantity,
                unit * owned.quantity,
                owned.isProtected,
              );
            }
          : null,
      compact: compact,
      customSprites: customSprites,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.compact,
    required this.theme,
  });

  final String title;
  final bool compact;
  final BackgroundTheme theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GameTheme.sectionTitle(theme, size: compact ? 16 : 18),
    );
  }
}
