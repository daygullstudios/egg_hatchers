import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../models/background_theme.dart';
import '../models/owned_animal.dart';
import '../navigation/app_page_route.dart';
import '../services/custom_sprite_service.dart';
import '../services/game_service.dart';
import '../theme/game_theme.dart';
import '../utils/collection_quest_logic.dart';
import '../utils/egg_shard_logic.dart';
import '../utils/format_utils.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/game_background.dart';
import '../widgets/game_sprite.dart';
import '../widgets/phone_width_layout.dart';
import '../widgets/tutorial_overlay.dart';
import '../widgets/tutorial_targets.dart';
import 'developer_screen.dart';

/// Player-facing secret screen unlocked by tapping the Hatchery coin 3 times.
class SecretToolsScreen extends StatelessWidget {
  const SecretToolsScreen({
    super.key,
    required this.game,
    required this.customSprites,
    required this.theme,
  });

  final GameService game;
  final CustomSpriteService customSprites;
  final BackgroundTheme theme;

  Future<void> _useSecretRewardBadge(BuildContext context) async {
    if (!game.canUseSecretRewardBadge) {
      if (game.ownedAnimals.isEmpty && context.mounted) {
        showGameSnackBar(
          context,
          message: 'Hatch an animal first.',
          duration: kGameSnackBarDurationShort,
        );
      }
      return;
    }

    final chosen = await _pickSecretRewardTarget(context);
    if (chosen == null || !context.mounted) return;

    final name = game.applySecretRewardBadge(
      animalId: chosen.animalId,
      mutationId: chosen.mutationId,
      isProtected: chosen.isProtected,
    );
    if (!context.mounted) return;

    if (name == null) {
      showGameSnackBar(
        context,
        message: 'Could not apply Secret Reward Badge.',
        duration: kGameSnackBarDurationShort,
      );
      return;
    }

    showGameSnackBar(context, message: 'Secret Reward Badge applied to $name!');
  }

  Future<OwnedAnimal?> _pickSecretRewardTarget(BuildContext context) {
    final candidates =
        game.ownedAnimals.where((owned) => owned.quantity > 0).toList()..sort(
          (a, b) => GameData.compareOwnedAnimals(a.animalId, b.animalId),
        );

    return showModalBottomSheet<OwnedAnimal>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.disabledColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose Animal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.cardTextPrimaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pick one animal to protect forever.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.cardTextSecondaryColor,
                  ),
                ),
                const SizedBox(height: 14),
                if (candidates.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Hatch an animal first.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.cardTextSecondaryColor),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: candidates.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final owned = candidates[index];
                        final animal = GameData.animalById(owned.animalId);
                        if (animal == null) return const SizedBox.shrink();
                        final mutation =
                            GameData.mutationById(owned.mutationId) ??
                            GameData.mutations.first;
                        final alreadyBadged =
                            owned.isSecretReward || owned.isEliteReward;

                        return ListTile(
                          tileColor: theme.panelColor.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: theme.cardBorderColor),
                          ),
                          leading: GameAnimalPortrait(
                            customSprite: customSprites.getDisplaySprite(
                              animal.id,
                            ),
                            animalId: animal.id,
                            spritePath: animal.spritePath,
                            fallbackEmoji: mutation.displayEmoji(animal),
                            size: 48,
                            mutation: mutation,
                          ),
                          title: Text(
                            mutation.fullName(animal),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.cardTextPrimaryColor,
                            ),
                          ),
                          subtitle: Text(
                            alreadyBadged
                                ? 'Already has badge'
                                : 'Lv ${owned.level} · x${owned.quantity}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.cardTextSecondaryColor,
                            ),
                          ),
                          trailing: FilledButton.icon(
                            onPressed: alreadyBadged
                                ? null
                                : () => Navigator.pop(sheetContext, owned),
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.secondaryColor,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Choose'),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final collected = CollectionQuestLogic.collectedBaseAnimalCount(
          game.state,
        );
        final total = CollectionQuestLogic.totalBaseAnimalCount;
        final claimed = game.secretRewardBadgeClaimed;
        final vaultUnlocked = game.collectorsVaultUnlocked;
        final hasAnimals = game.ownedAnimals.isNotEmpty;
        final rottenPrerequisites = EggShardLogic.defeatedPrerequisiteCount(
          game.state,
        );
        final rottenPrerequisiteTotal =
            EggShardLogic.prerequisiteBossIds.length;
        final rottenUnlocked = EggShardLogic.isRottenShellUnlocked(game.state);

        return ReturnToHatcheryPopScope(
          theme: theme,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: PhoneWidthAppBar(
              title: '🔐 Secret Hatchery',
              titleStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
              backgroundColor: theme.appBarColor,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              leading: ReturnToHatcheryBackButton(
                theme: theme,
                color: Colors.white,
              ),
            ),
            body: GameBackground(
              theme: theme,
              child: PhoneWidthLayout(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: GameTheme.panelDecoration(theme),
                      child: Column(
                        children: [
                          const Text('🥚✨', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            'You found the secret hatchery!',
                            textAlign: TextAlign.center,
                            style: GameTheme.sectionTitle(theme, size: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Shhh… only curious hatchers make it here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.cardTextSecondaryColor,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      key: TutorialTargets.secretStatsSection,
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: GameTheme.panelDecoration(theme),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your stats',
                            style: GameTheme.sectionTitle(theme, size: 16),
                          ),
                          const SizedBox(height: 12),
                          _StatRow(
                            theme: theme,
                            icon: '🔄',
                            label: 'Rebirth level',
                            value: '${game.rebirthLevel}',
                          ),
                          const SizedBox(height: 8),
                          _StatRow(
                            theme: theme,
                            icon: '🐾',
                            label: 'Collection',
                            value: '$collected / $total animals',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      key: TutorialTargets.secretLateGameGuide,
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: GameTheme.panelDecoration(theme),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Late-game path',
                            style: GameTheme.sectionTitle(theme, size: 16),
                          ),
                          const SizedBox(height: 10),
                          _StatRow(
                            theme: theme,
                            icon: 'R',
                            label: 'Animal income this Rebirth',
                            value:
                                '${formatCoins(game.lifetimeCoinsEarned)} / ${formatCoins(game.rebirthRequirement)}',
                          ),
                          const SizedBox(height: 8),
                          _StatRow(
                            theme: theme,
                            icon: 'E',
                            label: 'Rebirth eggs',
                            value: '1 Ancient / 2 Royal / 3 Celestial / 5 Void',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      key: TutorialTargets.secretRottenShellGuide,
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: GameTheme.panelDecoration(theme),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Rotten Shell',
                            style: GameTheme.sectionTitle(theme, size: 16),
                          ),
                          const SizedBox(height: 10),
                          _StatRow(
                            theme: theme,
                            icon: 'B',
                            label: 'Bosses defeated',
                            value:
                                '$rottenPrerequisites / $rottenPrerequisiteTotal',
                          ),
                          const SizedBox(height: 8),
                          _StatRow(
                            theme: theme,
                            icon: 'F',
                            label: 'Flawless Shadow Phoenix',
                            value: game.shadowPhoenixFlawlessWin
                                ? 'Done'
                                : 'Needed',
                          ),
                          const SizedBox(height: 8),
                          _StatRow(
                            theme: theme,
                            icon: 'S',
                            label: 'Status',
                            value: rottenUnlocked ? 'Unlocked' : 'Locked',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: GameTheme.panelDecoration(theme),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            vaultUnlocked
                                ? "Collector's Vault"
                                : "🔒 Collector's Vault",
                            style: GameTheme.sectionTitle(theme, size: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            vaultUnlocked
                                ? 'Secret Reward Badge\n'
                                      'Choose one treasured animal to protect forever.'
                                : 'Complete the base-animal collection to open '
                                      'this vault and earn its treasure.\n\n'
                                      'Collection progress: $collected / $total',
                            style: TextStyle(
                              color: theme.cardTextSecondaryColor,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          if (!vaultUnlocked) ...[
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: total == 0 ? 0 : collected / total,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(8),
                              color: theme.secondaryColor,
                              backgroundColor: theme.panelAccentColor
                                  .withValues(alpha: 0.18),
                            ),
                          ] else ...[
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              onPressed: claimed
                                  ? null
                                  : () => _useSecretRewardBadge(context),
                              icon: Text(claimed ? '✅' : '🏅'),
                              label: Text(
                                claimed
                                    ? 'Secret Reward Badge used'
                                    : hasAnimals
                                    ? 'Use Badge'
                                    : 'Choose Animal',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.secondaryColor,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: theme.panelAccentColor
                                    .withValues(alpha: 0.35),
                                disabledForegroundColor:
                                    theme.cardTextSecondaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ],
                          if (vaultUnlocked && !claimed && !hasAnimals) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Hatch an animal first.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.cardTextSecondaryColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: GameTheme.panelDecoration(theme),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Help',
                            style: GameTheme.sectionTitle(theme, size: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Follow the late-game path from rebirths to Rotten Shell.',
                            style: TextStyle(
                              color: theme.cardTextSecondaryColor,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: () {
                              TutorialOverlay.showAdvancedSecret(
                                context,
                                game: game,
                                theme: theme,
                              );
                            },
                            icon: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 18,
                            ),
                            label: const Text('Advanced Tutorial'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.cardTextPrimaryColor,
                              side: BorderSide(
                                color: theme.panelAccentColor.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (kDebugMode) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          pushDevToolsRoute(
                            context,
                            builder: (_) => DeveloperScreen(
                              game: game,
                              customSprites: customSprites,
                              returnTheme: theme,
                            ),
                          );
                        },
                        icon: const Icon(Icons.build_outlined, size: 18),
                        label: const Text('Developer Tools (Debug)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.cardTextSecondaryColor,
                          side: BorderSide(
                            color: theme.panelAccentColor.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.theme,
    required this.icon,
    required this.label,
    required this.value,
  });

  final BackgroundTheme theme;
  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: theme.cardTextSecondaryColor, fontSize: 14),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.cardTextPrimaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
