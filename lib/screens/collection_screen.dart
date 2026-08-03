import 'package:flutter/material.dart';

import '../models/background_theme.dart';
import '../services/custom_sprite_service.dart';
import '../services/game_service.dart';
import '../services/preferences_service.dart';
import '../theme/game_theme.dart';
import '../utils/format_utils.dart';
import '../utils/snackbar_utils.dart';
import '../utils/ui_sound.dart';
import '../navigation/app_page_route.dart';
import '../widgets/tutorial_screen_bindings.dart';
import '../widgets/tutorial_targets.dart';
import '../widgets/animal_fusion_panel.dart';
import '../widgets/coin_header.dart';
import '../widgets/game_background.dart';
import '../widgets/owned_animal_list.dart';
import '../widgets/phone_width_layout.dart';
import '../widgets/quest_notification_listener.dart';

/// Shows every animal the player owns with quantities, levels, and income.
class CollectionScreen extends StatelessWidget {
  const CollectionScreen({
    super.key,
    required this.game,
    required this.preferences,
    required this.customSprites,
  });

  final GameService game;
  final PreferencesService preferences;
  final CustomSpriteService customSprites;

  void _handleUpgrade(
    BuildContext context,
    String animalId,
    String mutationId,
    String displayName,
    bool isProtected,
  ) {
    final newLevel = game.upgradeAnimal(
      animalId,
      mutationId,
      isProtected: isProtected,
    );
    if (newLevel != null) {
      UiSound.purchase(context);
      showGameSnackBar(
        context,
        message: '$displayName upgraded to Level $newLevel!',
        backgroundColor: Colors.teal.shade400,
      );
    } else {
      UiSound.locked(context);
      showGameSnackBar(
        context,
        message: 'Not enough coins to upgrade $displayName.',
        backgroundColor: Colors.red.shade400,
      );
    }
  }

  void _handleSellOne(
    BuildContext context,
    String animalId,
    String mutationId,
    String displayName,
    bool isProtected, {
    bool isEliteReward = false,
    bool isSecretReward = false,
  }) {
    if (isProtected) {
      final message = isEliteReward
          ? 'Elite animals cannot be sold.'
          : isSecretReward
              ? 'Secret reward animals cannot be sold.'
              : 'Protected animals cannot be sold.';
      UiSound.locked(context);
      showGameSnackBar(
        context,
        message: message,
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    final coins = game.sellOwnedAnimal(
      animalId,
      mutationId,
      quantity: 1,
      isProtected: isProtected,
    );
    if (coins != null && context.mounted) {
      UiSound.rewardTriumph(context);
      showGameSnackBar(
        context,
        message: 'Sold $displayName for ${formatCoins(coins)} coins.',
        backgroundColor: preferences.selectedTheme.secondaryColor,
      );
    }
  }

  Future<void> _handleSellAll(
    BuildContext context,
    String animalId,
    String mutationId,
    String displayName,
    int quantity,
    int totalCoins,
    bool isProtected, {
    bool isEliteReward = false,
    bool isSecretReward = false,
  }) async {
    if (isProtected) {
      final message = isEliteReward
          ? 'Elite animals cannot be sold.'
          : isSecretReward
              ? 'Secret reward animals cannot be sold.'
              : 'Protected animals cannot be sold.';
      UiSound.locked(context);
      showGameSnackBar(
        context,
        message: message,
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    final theme = preferences.selectedTheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GameTheme.cardRadius),
        ),
        title: Text(
          'Sell All?',
          style: TextStyle(
            color: theme.cardTextPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Sell all $quantity $displayName for ${formatCoins(totalCoins)} coins?',
          style: TextStyle(
            color: theme.cardTextSecondaryColor,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.cardTextSecondaryColor),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.secondaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sell All'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final coins = game.sellOwnedAnimal(
      animalId,
      mutationId,
      quantity: quantity,
      isProtected: isProtected,
    );
    if (coins != null && context.mounted) {
      UiSound.rewardTriumph(context);
      showGameSnackBar(
        context,
        message: 'Sold $displayName for ${formatCoins(coins)} coins.',
        backgroundColor: theme.secondaryColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([game, preferences, customSprites]),
      builder: (context, _) {
        final bg = preferences.selectedTheme;

        return TutorialScreenBindings(
          onReturnToHatchery: () =>
              returnToHatcheryWithTransition(context, theme: bg),
          child: ReturnToHatcheryPopScope(
          theme: bg,
          child: QuestNotificationListener(
          game: game,
          preferences: preferences,
          child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PhoneWidthAppBar(
            title: '📚 Collection',
            titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            backgroundColor: bg.appBarColor,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            leading: ReturnToHatcheryBackButton(
              theme: bg,
              color: Colors.white,
              tutorialKey: TutorialTargets.screenBackButton,
            ),
          ),
          body: GameBackground(
            theme: bg,
            child: PhoneWidthLayout(
              child: Column(
                children: [
                  CoinHeader(
                    coins: game.coins,
                    coinsPerSecond: game.coinsPerSecond,
                    theme: bg,
                  ),
                  const SizedBox(height: 18),
                  AnimalFusionPanel(
                    game: game,
                    theme: bg,
                    customSprites: customSprites,
                    tutorialSectionKey: TutorialTargets.fusionSection,
                  ),
                  Expanded(
                    child: game.ownedAnimals.isEmpty
                        ? _EmptyCollection(theme: bg)
                        : OwnedAnimalList(
                            game: game,
                            theme: bg,
                            separatorHeight: 12,
                            customSprites: customSprites,
                            showSellButtons: true,
                            onUpgrade: (animalId, mutationId, name, isProtected) =>
                                _handleUpgrade(
                              context,
                              animalId,
                              mutationId,
                              name,
                              isProtected,
                            ),
                            onSellOne: (animalId, mutationId, name, _, isProtected) =>
                                _handleSellOne(
                              context,
                              animalId,
                              mutationId,
                              name,
                              isProtected,
                            ),
                            onSellAll:
                                (animalId, mutationId, name, qty, total, isProtected) =>
                                    _handleSellAll(
                              context,
                              animalId,
                              mutationId,
                              name,
                              qty,
                              total,
                              isProtected,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
        ),
        );
      },
    );
  }
}

class _EmptyCollection extends StatelessWidget {
  const _EmptyCollection({required this.theme});

  final BackgroundTheme theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        decoration: GameTheme.cardDecoration(
          theme,
          borderColor: theme.primaryColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📭', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 14),
            Text(
              'Your collection is empty.\nHatch some eggs first!',
              textAlign: TextAlign.center,
              style: GameTheme.emptyStateTitle(theme),
            ),
          ],
        ),
      ),
    );
  }
}
