import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../models/animal.dart';
import '../models/background_theme.dart';
import '../models/custom_egg.dart';
import '../navigation/app_page_route.dart';
import '../services/custom_egg_service.dart';
import '../services/custom_sprite_service.dart';
import '../services/game_service.dart';
import '../services/preferences_service.dart';
import '../theme/game_theme.dart';
import '../utils/format_utils.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/game_background.dart';
import '../widgets/game_sprite.dart';
import '../widgets/phone_width_layout.dart';
import 'custom_egg_editor_screen.dart';

/// Lists saved custom eggs and lets the player create or manage them.
class CustomEggsScreen extends StatelessWidget {
  const CustomEggsScreen({
    super.key,
    required this.game,
    required this.preferences,
    required this.customEggs,
    required this.customSprites,
  });

  final GameService game;
  final PreferencesService preferences;
  final CustomEggService customEggs;
  final CustomSpriteService customSprites;

  Future<void> _confirmDelete(
    BuildContext context,
    BackgroundTheme theme,
    CustomEgg egg,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GameTheme.cardRadius),
        ),
        title: Text(
          'Delete ${egg.name}?',
          style: TextStyle(
            color: theme.cardTextPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This custom egg will be removed from your device.',
          style: TextStyle(
            color: theme.cardTextSecondaryColor,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(dialogContext, false),
            icon: const Icon(Icons.close_rounded),
            label: Text(
              'Cancel',
              style: TextStyle(color: theme.cardTextSecondaryColor),
            ),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await customEggs.deleteEgg(egg.id);
    if (!context.mounted) return;

    showGameSnackBar(
      context,
      message: '${egg.name} deleted.',
      backgroundColor: Colors.red.shade400,
    );
  }

  void _openEditor(BuildContext context, {CustomEgg? egg}) {
    openWithThemedTransition(
      context,
      theme: preferences.selectedTheme,
      icon: '🥚✏️',
      label: 'Editing Egg',
      duration: kEditorThemedPreNavDuration,
      builder: (_) => CustomEggEditorScreen(
        key: egg == null
            ? ValueKey('create_${DateTime.now().microsecondsSinceEpoch}')
            : ValueKey('edit_${egg.id}'),
        game: game,
        preferences: preferences,
        customEggs: customEggs,
        customSprites: customSprites,
        existing: egg,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([game, preferences, customEggs, customSprites]),
      builder: (context, _) {
        final theme = preferences.selectedTheme;
        final eggs = customEggs.allEggs;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PhoneWidthAppBar(
            title: '🥚 Custom Eggs',
            titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            backgroundColor: theme.appBarColor,
            foregroundColor: Colors.white,
          ),
          body: GameBackground(
            theme: theme,
            child: PhoneWidthLayout(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Text(
                    'Create eggs that hatch your favorite animals!',
                    style: GameTheme.sectionTitle(theme, size: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Custom eggs are saved only on this device and are '
                    'not shared online.',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.cardTextSecondaryColor,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _openEditor(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text(
                      'Create Custom Egg',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: GameTheme.filledButton(
                      theme,
                      color: theme.primaryColor,
                      height: 52,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (eggs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: GameTheme.cardDecoration(theme),
                      child: Text(
                        'No custom eggs yet.\nTap Create to make your first!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: theme.cardTextSecondaryColor,
                          height: 1.4,
                        ),
                      ),
                    )
                  else
                    for (final egg in eggs) ...[
                      _CustomEggTile(
                        egg: egg,
                        theme: theme,
                        customSprites: customSprites,
                        onEdit: () => _openEditor(context, egg: egg),
                        onDelete: () => _confirmDelete(context, theme, egg),
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CustomEggTile extends StatelessWidget {
  const _CustomEggTile({
    required this.egg,
    required this.theme,
    required this.customSprites,
    required this.onEdit,
    required this.onDelete,
  });

  final CustomEgg egg;
  final BackgroundTheme theme;
  final CustomSpriteService customSprites;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final validCount = egg.validAnimalIds.length;
    final previewAnimals = egg.validAnimalIds
        .map(GameData.animalById)
        .whereType<Animal>()
        .toList();
    final status = !egg.isValid
        ? 'Needs animals'
        : egg.isEnabled
            ? 'Enabled · in shop'
            : 'Disabled · hidden';

    return Container(
      decoration: GameTheme.cardDecoration(
        theme,
        locked: !egg.isValid,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(egg.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      egg.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.cardTextPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🪙 ${formatCoins(egg.cost)}  •  $validCount animals',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.cardTextSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: egg.isEnabled && egg.isValid
                            ? theme.primaryColor
                            : theme.secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (previewAnimals.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final animal in previewAnimals)
                  Tooltip(
                    message: animal.name,
                    child: GameSprite(
                      customSprite: customSprites.getDisplaySprite(animal.id),
                      animalId: animal.id,
                      spritePath: animal.spritePath,
                      fallbackEmoji: animal.emoji,
                      size: 32,
                      semanticLabel: animal.name,
                      emojiFontSize: 22,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    foregroundColor: theme.cardTextPrimaryColor,
                    side: BorderSide(color: theme.cardBorderColor),
                  ),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
