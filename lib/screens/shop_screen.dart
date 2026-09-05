import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../models/egg.dart';
import '../utils/custom_egg_logic.dart';
import '../utils/egg_mastery_logic.dart';
import '../data/audio_assets.dart';
import '../navigation/app_page_route.dart';
import '../services/custom_egg_service.dart';
import '../services/custom_sprite_service.dart';
import '../services/game_service.dart';
import '../services/preferences_service.dart';
import '../theme/game_theme.dart';
import '../utils/quest_notification_utils.dart';
import '../utils/snackbar_utils.dart';
import '../utils/ui_sound.dart';
import '../widgets/audio_scope.dart';
import '../widgets/egg_card.dart';
import '../widgets/game_background.dart';
import '../widgets/game_primary_navigation.dart';
import '../widgets/hatch_dialog.dart';
import '../data/tutorial_data.dart';
import '../services/tutorial_service.dart';
import '../widgets/tutorial_screen_bindings.dart';
import '../widgets/tutorial_targets.dart';
import '../widgets/multi_hatch_dialog.dart';
import '../widgets/phone_width_layout.dart';
import '../widgets/quest_notification_listener.dart';
import '../models/background_theme.dart';
import 'custom_egg_editor_screen.dart';
import 'custom_eggs_screen.dart';

enum _ShopSection { hatchery, battle, custom }

/// Screen where the player buys eggs to hatch.
class ShopScreen extends StatefulWidget {
  const ShopScreen({
    super.key,
    required this.game,
    required this.preferences,
    required this.customSprites,
    required this.customEggs,
  });

  final GameService game;
  final PreferencesService preferences;
  final CustomSpriteService customSprites;
  final CustomEggService customEggs;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  _ShopSection _selectedSection = _ShopSection.hatchery;

  GameService get game => widget.game;
  PreferencesService get preferences => widget.preferences;
  CustomSpriteService get customSprites => widget.customSprites;
  CustomEggService get customEggs => widget.customEggs;

  Duration _hatchLeadIn(BuildContext context) {
    final audio = AudioScope.maybeOf(context);
    if (audio?.sfxEnabled == true && audio?.userUnlocked == true) {
      return const Duration(milliseconds: 2850);
    }
    return const Duration(milliseconds: 900);
  }

  void _openCustomEggsScreen(BuildContext context) {
    final theme = preferences.selectedTheme;
    openWithThemedTransition(
      context,
      theme: theme,
      icon: '🥚',
      label: 'Opening Custom Eggs',
      builder: (_) => CustomEggsScreen(
        game: game,
        preferences: preferences,
        customEggs: customEggs,
        customSprites: customSprites,
      ),
    );
  }

  void _openCreateCustomEgg(BuildContext context) {
    final theme = preferences.selectedTheme;
    pushThemedAppRoute(
      context,
      theme: theme,
      builder: (_) => CustomEggEditorScreen(
        key: ValueKey('create_${DateTime.now().microsecondsSinceEpoch}'),
        game: game,
        preferences: preferences,
        customEggs: customEggs,
        customSprites: customSprites,
      ),
    );
  }

  Future<void> _tripleHatch(BuildContext context, Egg egg) async {
    final bg = preferences.selectedTheme;

    if (!game.isEggUnlocked(egg)) {
      AudioScope.maybeOf(context)?.playSfx(Sfx.errorLocked);
      showGameSnackBar(
        context,
        message: game.eggLockedDisplayMessage(egg),
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    if (!game.canAffordTripleHatch(egg)) {
      AudioScope.maybeOf(context)?.playSfx(Sfx.errorLocked);
      showGameSnackBar(
        context,
        message: egg.usesBattleTokens
            ? 'Not enough Battle Tokens.'
            : 'Not enough coins for Triple Hatch.',
        backgroundColor: Colors.red.shade400,
      );
      return;
    }

    final customDefinition = CustomEggLogic.isCustomEggId(egg.id)
        ? customEggs.getById(egg.id)
        : null;

    game.buyTripleHatch(egg);
    UiSound.purchase(context);
    final results = game.hatchEggMultiple(egg, 3, customEgg: customDefinition);

    if (context.mounted) {
      await MultiHatchDialog.show(
        context,
        egg: egg,
        results: results,
        theme: bg,
        customSprites: customSprites,
        sourceEggId: EggMasteryLogic.isMasteryEligibleEgg(egg.id)
            ? egg.id
            : null,
        masteryLevel: game.masteryLevelForEgg(egg.id),
        initialDelay: _hatchLeadIn(context),
      );
      if (context.mounted) {
        showPendingHatchNotifications(
          context,
          game: game,
          preferences: preferences,
        );
      }
    }
  }

  Future<void> _buyAndHatch(BuildContext context, Egg egg) async {
    final bg = preferences.selectedTheme;

    if (!game.isEggUnlocked(egg)) {
      AudioScope.maybeOf(context)?.playSfx(Sfx.errorLocked);
      showGameSnackBar(
        context,
        message: egg.usesBattleTokens
            ? 'Hatch an animal to unlock Boss Battles and Battle Eggs.'
            : game.eggLockedDisplayMessage(egg),
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    if (!game.canAfford(egg)) {
      AudioScope.maybeOf(context)?.playSfx(Sfx.errorLocked);
      showGameSnackBar(
        context,
        message: egg.usesBattleTokens
            ? 'Not enough Battle Tokens.'
            : 'You need ${egg.cost - game.coins} more coins for ${egg.name}!',
        backgroundColor: Colors.red.shade400,
      );
      return;
    }

    final customDefinition = CustomEggLogic.isCustomEggId(egg.id)
        ? customEggs.getById(egg.id)
        : null;

    game.buyEgg(egg);
    UiSound.purchase(context);
    TutorialService.instance.notifyEggPurchased();
    final result = game.hatchEgg(egg, customEgg: customDefinition);

    if (context.mounted) {
      TutorialService.instance.notifyHatchDialogOpening();
      await HatchDialog.show(
        context,
        egg: egg,
        result: result,
        theme: bg,
        customSprites: customSprites,
        initialDelay: _hatchLeadIn(context),
      );
      TutorialService.instance.notifyHatchDialogClosed();
      if (context.mounted) {
        showPendingHatchNotifications(
          context,
          game: game,
          preferences: preferences,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        game,
        preferences,
        customEggs,
        customSprites,
      ]),
      builder: (context, _) {
        final bg = preferences.selectedTheme;
        final shell = MainGameShellScope.maybeOf(context);
        final lifetime = game.lifetimeCoinsEarned;
        final builtInShopEggs = game.visibleShopEggs;
        final customShopEggs = customEggs.shopEggs(
          lifetime,
          rebirthLevel: game.rebirthLevel,
        );
        final hasSavedCustomEggs = customEggs.allEggs.isNotEmpty;
        final hasHiddenCustomEggs =
            hasSavedCustomEggs && customShopEggs.isEmpty;

        return TutorialScreenBindings(
          enabled: shell == null || shell.current == MainGameDestination.shop,
          onReturnToHatchery: () =>
              returnToHatcheryWithTransition(context, theme: bg),
          handlers: {
            TutorialTargetIds.basicEggBuyButton: () =>
                _buyAndHatch(context, GameData.eggs.first),
          },
          child: ReturnToHatcheryPopScope(
            theme: bg,
            enabled: shell == null,
            child: QuestNotificationListener(
              game: game,
              preferences: preferences,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: PhoneWidthAppBar(
                  title: '🛒 Egg Shop',
                  titleStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                  backgroundColor: bg.appBarColor,
                  foregroundColor: Colors.white,
                  automaticallyImplyLeading: false,
                  leading: shell == null
                      ? ReturnToHatcheryBackButton(
                          theme: bg,
                          color: Colors.white,
                          tutorialKey: TutorialTargets.screenBackButton,
                        )
                      : null,
                  bottom: shell == null
                      ? null
                      : GamePrimaryNavigation(
                          theme: bg,
                          hostDestination: MainGameDestination.shop,
                        ),
                  actions: [
                    CompactAppBarIconAction(
                      icon: Icons.design_services_rounded,
                      tooltip: 'Custom Eggs',
                      onPressed: () => _openCustomEggsScreen(context),
                    ),
                  ],
                ),
                body: GameBackground(
                  theme: bg,
                  child: PhoneWidthLayout(
                    child: Column(
                      children: [
                        _ShopSectionSelector(
                          theme: bg,
                          selected: _selectedSection,
                          hatcherySummary: _shopSectionSummary(
                            readyCount: builtInShopEggs
                                .where(
                                  (egg) =>
                                      game.isEggUnlocked(egg) &&
                                      game.canAfford(egg),
                                )
                                .length,
                            totalCount: builtInShopEggs.length,
                          ),
                          battleSummary: '${game.battleTokens} tokens',
                          customSummary: customShopEggs.isEmpty
                              ? 'Create'
                              : '${customShopEggs.length} available',
                          onSelected: (section) {
                            if (_selectedSection == section) return;
                            UiSound.click(context);
                            setState(() => _selectedSection = section);
                          },
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView(
                            key: PageStorageKey<String>(
                              'shop-${_selectedSection.name}',
                            ),
                            children: [
                              if (_selectedSection == _ShopSection.hatchery)
                                for (
                                  var i = 0;
                                  i < builtInShopEggs.length;
                                  i++
                                ) ...[
                                  if (i > 0) const SizedBox(height: 14),
                                  EggCard(
                                    egg: builtInShopEggs[i],
                                    theme: bg,
                                    buyButtonKey: i == 0
                                        ? TutorialTargets.basicEggBuyButton
                                        : null,
                                    isUnlocked: game.isEggUnlocked(
                                      builtInShopEggs[i],
                                    ),
                                    unlockMessageOverride: game
                                        .eggLockedDisplayMessage(
                                          builtInShopEggs[i],
                                        ),
                                    canAfford: game.canAfford(
                                      builtInShopEggs[i],
                                    ),
                                    lifetimeCoinsEarned:
                                        game.lifetimeCoinsEarned,
                                    tripleHatchCost:
                                        GameService.tripleHatchCost(
                                          builtInShopEggs[i],
                                        ),
                                    canAffordTripleHatch: game
                                        .canAffordTripleHatch(
                                          builtInShopEggs[i],
                                        ),
                                    onBuy: () => _buyAndHatch(
                                      context,
                                      builtInShopEggs[i],
                                    ),
                                    onTripleHatch: () => _tripleHatch(
                                      context,
                                      builtInShopEggs[i],
                                    ),
                                    masteryProgress: game.eggMasteryProgress(
                                      builtInShopEggs[i].id,
                                    ),
                                  ),
                                ],
                              if (_selectedSection == _ShopSection.battle)
                                for (
                                  var i = 0;
                                  i < GameData.battleEggs.length;
                                  i++
                                ) ...[
                                  if (i > 0) const SizedBox(height: 14),
                                  EggCard(
                                    egg: GameData.battleEggs[i],
                                    theme: bg,
                                    isUnlocked: game.isEggUnlocked(
                                      GameData.battleEggs[i],
                                    ),
                                    canAfford: game.canAfford(
                                      GameData.battleEggs[i],
                                    ),
                                    lifetimeCoinsEarned:
                                        game.lifetimeCoinsEarned,
                                    battleTokens: game.battleTokens,
                                    tripleHatchCost:
                                        GameService.tripleHatchCost(
                                          GameData.battleEggs[i],
                                        ),
                                    canAffordTripleHatch: game
                                        .canAffordTripleHatch(
                                          GameData.battleEggs[i],
                                        ),
                                    onBuy: () => _buyAndHatch(
                                      context,
                                      GameData.battleEggs[i],
                                    ),
                                    onTripleHatch: () => _tripleHatch(
                                      context,
                                      GameData.battleEggs[i],
                                    ),
                                    masteryProgress: game.eggMasteryProgress(
                                      GameData.battleEggs[i].id,
                                    ),
                                  ),
                                ],
                              if (_selectedSection == _ShopSection.custom &&
                                  customShopEggs.isNotEmpty) ...[
                                for (
                                  var i = 0;
                                  i < customShopEggs.length;
                                  i++
                                ) ...[
                                  if (i > 0) const SizedBox(height: 14),
                                  Builder(
                                    builder: (context) {
                                      final customEgg = customShopEggs[i];
                                      final eggModel = customEgg.toEgg(
                                        lifetimeCoinsEarned: lifetime,
                                        rebirthLevel: game.rebirthLevel,
                                      );
                                      return EggCard(
                                        egg: eggModel,
                                        theme: bg,
                                        isUnlocked: true,
                                        canAfford: game.canAfford(eggModel),
                                        lifetimeCoinsEarned: lifetime,
                                        isCustomEgg: true,
                                        customSprites: customSprites,
                                        tripleHatchCost:
                                            GameService.tripleHatchCost(
                                              eggModel,
                                            ),
                                        canAffordTripleHatch: game
                                            .canAffordTripleHatch(eggModel),
                                        onBuy: () =>
                                            _buyAndHatch(context, eggModel),
                                        onTripleHatch: () =>
                                            _tripleHatch(context, eggModel),
                                      );
                                    },
                                  ),
                                ],
                                const SizedBox(height: 14),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      _openCreateCustomEgg(context),
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Create Custom Egg'),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(
                                      double.infinity,
                                      44,
                                    ),
                                    foregroundColor: bg.primaryColor,
                                    side: BorderSide(color: bg.primaryColor),
                                  ),
                                ),
                              ] else if (_selectedSection ==
                                      _ShopSection.custom &&
                                  hasHiddenCustomEggs)
                                _CustomEggsShopNotice(
                                  theme: bg,
                                  message:
                                      'You have custom eggs, but none are '
                                      'enabled for the shop.',
                                  buttonLabel: 'Manage Custom Eggs',
                                  onPressed: () =>
                                      _openCustomEggsScreen(context),
                                )
                              else if (_selectedSection == _ShopSection.custom)
                                _CustomEggsShopNotice(
                                  theme: bg,
                                  message:
                                      'No custom eggs yet.\n'
                                      'Create your own egg to hatch your '
                                      'favorite animals.',
                                  buttonLabel: 'Create Custom Egg',
                                  onPressed: () =>
                                      _openCreateCustomEgg(context),
                                ),
                            ],
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

  String _shopSectionSummary({
    required int readyCount,
    required int totalCount,
  }) {
    if (readyCount > 0) return '$readyCount ready';
    return '$totalCount eggs';
  }
}

class _ShopSectionSelector extends StatelessWidget {
  const _ShopSectionSelector({
    required this.theme,
    required this.selected,
    required this.hatcherySummary,
    required this.battleSummary,
    required this.customSummary,
    required this.onSelected,
  });

  final BackgroundTheme theme;
  final _ShopSection selected;
  final String hatcherySummary;
  final String battleSummary;
  final String customSummary;
  final ValueChanged<_ShopSection> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ShopSectionButton(
            key: const ValueKey('shop-section-hatchery'),
            theme: theme,
            icon: Icons.storefront_rounded,
            label: 'Hatchery',
            summary: hatcherySummary,
            selected: selected == _ShopSection.hatchery,
            onTap: () => onSelected(_ShopSection.hatchery),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ShopSectionButton(
            key: const ValueKey('shop-section-battle'),
            theme: theme,
            icon: Icons.shield_rounded,
            label: 'Battle',
            summary: battleSummary,
            selected: selected == _ShopSection.battle,
            onTap: () => onSelected(_ShopSection.battle),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ShopSectionButton(
            key: const ValueKey('shop-section-custom'),
            theme: theme,
            icon: Icons.auto_awesome_rounded,
            label: 'Custom',
            summary: customSummary,
            selected: selected == _ShopSection.custom,
            onTap: () => onSelected(_ShopSection.custom),
          ),
        ),
      ],
    );
  }
}

class _ShopSectionButton extends StatelessWidget {
  const _ShopSectionButton({
    super.key,
    required this.theme,
    required this.icon,
    required this.label,
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  final BackgroundTheme theme;
  final IconData icon;
  final String label;
  final String summary;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : theme.cardTextPrimaryColor;
    return Semantics(
      selected: selected,
      button: true,
      label: '$label shop, $summary',
      child: Material(
        color: selected ? theme.primaryColor : theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? theme.primaryColor : theme.cardBorderColor,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 19, color: foreground),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground.withValues(alpha: 0.78),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomEggsShopNotice extends StatelessWidget {
  const _CustomEggsShopNotice({
    required this.theme,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  final BackgroundTheme theme;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: GameTheme.cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: theme.cardTextSecondaryColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onPressed,
            style: GameTheme.filledButton(
              theme,
              color: theme.secondaryColor,
              height: 48,
            ),
            icon: Icon(
              buttonLabel.toLowerCase().contains('unlock')
                  ? Icons.lock_open_rounded
                  : Icons.auto_awesome_rounded,
            ),
            label: Text(
              buttonLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
