import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../models/background_theme.dart';
import '../models/owned_animal.dart';
import '../services/custom_sprite_service.dart';
import '../services/game_service.dart';
import '../theme/game_theme.dart';
import '../utils/animal_fusion_logic.dart';
import '../utils/ui_sound.dart';
import 'animal_fusion_animation.dart';
import 'game_sprite.dart';

/// Animal Fusion section for the Collection screen.
class AnimalFusionPanel extends StatefulWidget {
  const AnimalFusionPanel({
    super.key,
    required this.game,
    required this.theme,
    required this.customSprites,
    this.tutorialSectionKey,
  });

  final GameService game;
  final BackgroundTheme theme;
  final CustomSpriteService customSprites;
  final Key? tutorialSectionKey;

  static void showHelpDialog(BuildContext context, BackgroundTheme theme) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GameTheme.cardRadius),
        ),
        title: Text(
          'How Fusion Works',
          style: TextStyle(
            color: theme.cardTextPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Fuse 2 matching animals with the same mutation.\n\n'
          'Fusion has an 80% success chance.\n\n'
          'If it fails, both animals are lost.\n\n'
          'Successful fusion upgrades the mutation.\n\n'
          'Sometimes Fusion jumps ahead two mutation levels.\n\n'
          'Shadow and Boss Mutation animals cannot be fused.\n\n'
          'Elite, Secret Reward, and battling animals are protected.',
          style: TextStyle(
            color: theme.cardTextSecondaryColor,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext),
            style: FilledButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  State<AnimalFusionPanel> createState() => _AnimalFusionPanelState();
}

class _AnimalFusionPanelState extends State<AnimalFusionPanel> {
  var _fusionInProgress = false;

  List<OwnedAnimal> _fusionCandidates() {
    return widget.game.ownedAnimals
        .where(AnimalFusionLogic.shouldShowInFusionList)
        .toList()
      ..sort((a, b) {
        final animalA = GameData.animalById(a.animalId)?.name ?? a.animalId;
        final animalB = GameData.animalById(b.animalId)?.name ?? b.animalId;
        final nameCmp = animalA.compareTo(animalB);
        if (nameCmp != 0) return nameCmp;
        final indexA = AnimalFusionLogic.fusionLadder.indexOf(a.mutationId);
        final indexB = AnimalFusionLogic.fusionLadder.indexOf(b.mutationId);
        return indexA.compareTo(indexB);
      });
  }

  Future<void> _confirmAndFuse(BuildContext context, OwnedAnimal owned) async {
    if (_fusionInProgress) return;

    final animal = GameData.animalById(owned.animalId);
    final inputMutation =
        GameData.mutationById(owned.mutationId) ?? GameData.mutations.first;
    if (animal == null) return;

    final inputName = inputMutation.fullName(animal);
    final primaryName = AnimalFusionLogic.successResultLabel(
      owned.mutationId,
      animal,
    );
    final luckyName = AnimalFusionLogic.luckyResultLabel(owned.mutationId, animal);
    final successPct = (AnimalFusionLogic.successChance * 100).round();
    final failPct = (AnimalFusionLogic.failureChance * 100).round();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GameTheme.cardRadius),
        ),
        title: Text(
          'Fuse 2 $inputName?',
          style: TextStyle(
            color: widget.theme.cardTextPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consumes 2 $inputName.',
              style: TextStyle(color: widget.theme.cardTextSecondaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              '$successPct% chance: $primaryName',
              style: TextStyle(
                color: widget.theme.cardTextPrimaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$failPct% chance: Fusion fails and both are lost.',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (luckyName != null) ...[
              const SizedBox(height: 6),
              Text(
                'Rare lucky chance: $luckyName!',
                style: TextStyle(
                  color: Colors.amber.shade700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(dialogContext, false),
            icon: const Icon(Icons.close_rounded),
            label: Text(
              'Cancel',
              style: TextStyle(color: widget.theme.cardTextSecondaryColor),
            ),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: widget.theme.primaryColor,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.merge_rounded),
            label: const Text('Fuse'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    setState(() => _fusionInProgress = true);
    UiSound.confirm(context);

    final outcome = widget.game.fuseAnimals(owned);
    if (outcome == null) {
      if (mounted) setState(() => _fusionInProgress = false);
      return;
    }

    if (!context.mounted) {
      setState(() => _fusionInProgress = false);
      return;
    }

    await AnimalFusionAnimation.show(
      context,
      theme: widget.theme,
      customSprites: widget.customSprites,
      outcome: outcome,
    );

    if (mounted) setState(() => _fusionInProgress = false);
  }

  @override
  Widget build(BuildContext context) {
    final candidates = _fusionCandidates();

    return Container(
      key: widget.tutorialSectionKey,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: GameTheme.cardDecoration(
        widget.theme,
        borderColor: widget.theme.primaryColor.withValues(alpha: 0.55),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '⚗️ Fusion',
                style: TextStyle(
                  color: widget.theme.cardTextPrimaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              IconButton(
                tooltip: 'How Fusion Works',
                onPressed: () =>
                    AnimalFusionPanel.showHelpDialog(context, widget.theme),
                icon: Icon(
                  Icons.info_outline_rounded,
                  color: widget.theme.cardTextSecondaryColor,
                  size: 22,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              const Spacer(),
              Text(
                'Fuse 2 → 1',
                style: TextStyle(
                  color: widget.theme.cardTextSecondaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Fuse 2 matching animals with the same mutation to upgrade them.',
            style: TextStyle(
              color: widget.theme.cardTextSecondaryColor,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '80% success · 20% fail · Rare lucky upgrade chance!\n'
            'Normal → Golden → Rainbow → Shadow',
            style: TextStyle(
              color: widget.theme.cardTextSecondaryColor,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          if (candidates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No animals ready to fuse yet. Hatch duplicates and come back!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.theme.cardTextSecondaryColor,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: candidates.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _FusionRow(
                    owned: candidates[index],
                    theme: widget.theme,
                    customSprites: widget.customSprites,
                    inBattle: widget.game
                        .isOwnedStackAutoBattling(candidates[index]),
                    fusionLocked: _fusionInProgress,
                    onFuse: () => _confirmAndFuse(context, candidates[index]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _FusionRow extends StatelessWidget {
  const _FusionRow({
    required this.owned,
    required this.theme,
    required this.customSprites,
    required this.inBattle,
    required this.fusionLocked,
    required this.onFuse,
  });

  final OwnedAnimal owned;
  final BackgroundTheme theme;
  final CustomSpriteService customSprites;
  final bool inBattle;
  final bool fusionLocked;
  final VoidCallback onFuse;

  @override
  Widget build(BuildContext context) {
    final animal = GameData.animalById(owned.animalId);
    if (animal == null) return const SizedBox.shrink();

    final mutation =
        GameData.mutationById(owned.mutationId) ?? GameData.mutations.first;
    final displayName = mutation.fullName(animal);
    final canFuse = !fusionLocked &&
        AnimalFusionLogic.canFuseStack(owned, inBattle: inBattle);
    final blockReason =
        AnimalFusionLogic.blockReasonText(owned, inBattle: inBattle);
    final successName =
        AnimalFusionLogic.successResultLabel(owned.mutationId, animal);
    final luckyName =
        AnimalFusionLogic.luckyResultLabel(owned.mutationId, animal);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canFuse
              ? theme.primaryColor.withValues(alpha: 0.45)
              : theme.cardTextSecondaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          GameSprite(
            customSprite: customSprites.getDisplaySprite(animal.id),
            animalId: animal.id,
            spritePath: animal.spritePath,
            fallbackEmoji: mutation.displayEmoji(animal),
            size: 44,
            semanticLabel: displayName,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.cardTextPrimaryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Qty: ${owned.quantity}',
                  style: TextStyle(
                    color: theme.cardTextSecondaryColor,
                    fontSize: 12,
                  ),
                ),
                if (owned.mutationId != 'shadow' && owned.mutationId != 'boss')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '80% success · 20% fail',
                        style: TextStyle(
                          color: theme.cardTextSecondaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Success: $successName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.cardTextSecondaryColor,
                          fontSize: 11,
                        ),
                      ),
                      if (luckyName != null)
                        Text(
                          'Lucky: $luckyName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      Text(
                        'Fail: lose both',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                if (fusionLocked)
                  Text(
                    'Fusion in progress…',
                    style: TextStyle(
                      color: theme.cardTextSecondaryColor,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else if (blockReason != null)
                  Text(
                    blockReason,
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: canFuse ? onFuse : null,
            style: FilledButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              minimumSize: const Size(0, 36),
            ),
            icon: const Icon(Icons.merge_rounded),
            label: const Text('Fuse 2'),
          ),
        ],
      ),
    );
  }
}
