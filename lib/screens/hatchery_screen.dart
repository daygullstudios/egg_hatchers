import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../models/background_theme.dart';
import '../services/custom_egg_service.dart';
import '../services/custom_sprite_service.dart';
import '../services/game_service.dart';
import '../services/preferences_service.dart';
import '../services/sprite_rating_service.dart';
import '../services/sprite_reference_overlay_service.dart';
import '../data/audio_assets.dart';
import '../navigation/app_page_route.dart';
import '../theme/game_theme.dart';
import '../utils/snackbar_utils.dart';
import '../utils/ui_sound.dart';
import '../widgets/audio_scope.dart';
import '../widgets/auto_battle_notification_listener.dart';
import '../services/tutorial_service.dart';
import '../widgets/daily_reward_popup.dart';
import '../widgets/daily_system_cards.dart';
import '../widgets/coin_header.dart';
import '../widgets/game_background.dart';
import '../widgets/luck_panel.dart';
import '../widgets/owned_animal_list.dart';
import '../widgets/phone_width_layout.dart';
import '../widgets/quest_notification_listener.dart';
import '../widgets/rebirth_panel.dart';
import '../data/tutorial_data.dart';
import '../services/tutorial_target_registry.dart';
import '../widgets/tutorial_targets.dart';
import 'battles_screen.dart';
import 'collection_screen.dart';
import 'custom_sprites_screen.dart';
import 'quests_screen.dart';
import 'secret_tools_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';

/// Main home screen: coins, income, owned animals, and navigation.
class HatcheryScreen extends StatefulWidget {
  const HatcheryScreen({
    super.key,
    required this.game,
    required this.preferences,
    required this.customSprites,
    required this.customEggs,
    required this.spriteRating,
    required this.referenceOverlay,
  });

  final GameService game;
  final PreferencesService preferences;
  final CustomSpriteService customSprites;
  final CustomEggService customEggs;
  final SpriteRatingService spriteRating;
  final SpriteReferenceOverlayService referenceOverlay;

  @override
  State<HatcheryScreen> createState() => _HatcheryScreenState();
}

class _HatcheryScreenState extends State<HatcheryScreen> {
  int _coinTapCount = 0;
  var _tutorialAutoStartChecked = false;
  var _wasTutorialActive = false;
  late final TutorialService _tutorialService;

  static const _hatcheryTutorialTargets = [
    TutorialTargetIds.shopButton,
    TutorialTargetIds.collectionButton,
    TutorialTargetIds.questsButton,
    TutorialTargetIds.battlesButton,
    TutorialTargetIds.upgradeButton,
  ];

  GameService get game => widget.game;
  PreferencesService get preferences => widget.preferences;
  CustomSpriteService get customSprites => widget.customSprites;
  CustomEggService get customEggs => widget.customEggs;

  @override
  void initState() {
    super.initState();
    _tutorialService = TutorialService.instance;
    _wasTutorialActive = _tutorialService.isActive;
    _tutorialService.addListener(_onTutorialServiceChanged);
    AppNavigationTracker.instance.addRouteListener(_onNavigationRouteChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAutoStartTutorial();
      _scheduleDailyRewardPopup();
      if (mounted) {
        AudioScope.of(context).playMusic(MusicTrack.hatchery);
      }
    });
  }

  @override
  void dispose() {
    AppNavigationTracker.instance.removeRouteListener(
      _onNavigationRouteChanged,
    );
    _tutorialService.removeListener(_onTutorialServiceChanged);
    TutorialTargetRegistry.unregisterAll(_hatcheryTutorialTargets);
    super.dispose();
  }

  void _onNavigationRouteChanged() {
    if (!mounted) return;
    if (AppNavigationTracker.instance.topRouteName != null) return;
    AudioScope.of(context).playMusic(MusicTrack.hatchery);
  }

  void _onTutorialServiceChanged() {
    final active = _tutorialService.isActive;
    if (_wasTutorialActive && !active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scheduleDailyRewardPopup();
      });
    }
    _wasTutorialActive = active;
  }

  void _scheduleDailyRewardPopup() {
    if (!mounted) return;
    DailyRewardPopup.showIfEligible(
      context,
      game: game,
      theme: preferences.selectedTheme,
    );
  }

  void _registerTutorialTargets() {
    if (!mounted) return;

    TutorialTargetRegistry.register(TutorialTargetIds.shopButton, () {
      if (!mounted) return;
      final bg = preferences.selectedTheme;
      openShopWithTransition(
        context,
        theme: bg,
        builder: (_) => ShopScreen(
          game: game,
          preferences: preferences,
          customSprites: customSprites,
          customEggs: customEggs,
        ),
      );
    });

    TutorialTargetRegistry.register(TutorialTargetIds.collectionButton, () {
      if (!mounted) return;
      final bg = preferences.selectedTheme;
      openWithThemedTransition(
        context,
        theme: bg,
        icon: '🐾',
        label: 'Opening Collection',
        settings: const RouteSettings(name: kCollectionRouteName),
        builder: (_) => CollectionScreen(
          game: game,
          preferences: preferences,
          customSprites: customSprites,
        ),
      );
    });

    TutorialTargetRegistry.register(TutorialTargetIds.questsButton, () {
      if (!mounted) return;
      final bg = preferences.selectedTheme;
      openWithThemedTransition(
        context,
        theme: bg,
        icon: '⭐',
        label: 'Opening Quests',
        settings: const RouteSettings(name: kQuestsRouteName),
        builder: (_) => QuestsScreen(game: game, preferences: preferences),
      );
    });

    TutorialTargetRegistry.register(TutorialTargetIds.battlesButton, () {
      if (!mounted) return;
      final bg = preferences.selectedTheme;
      openBattlesWithTransition(
        context,
        theme: bg,
        builder: (_) => BattlesScreen(
          game: game,
          preferences: preferences,
          customSprites: customSprites,
        ),
      );
    });

    TutorialTargetRegistry.register(TutorialTargetIds.upgradeButton, () {
      if (!mounted) return;
      final owned = game.normalAnimals.isNotEmpty
          ? game.normalAnimals.first
          : game.mutatedAnimals.isEmpty
          ? null
          : game.mutatedAnimals.first;
      if (owned == null) return;
      final animal = GameData.animalById(owned.animalId);
      if (animal == null) return;
      final mutation =
          GameData.mutationById(owned.mutationId) ?? GameData.mutations.first;
      _handleUpgrade(
        context,
        animal.id,
        owned.mutationId,
        mutation.fullName(animal),
        owned.isProtected,
      );
    });
  }

  void _maybeAutoStartTutorial() {
    if (!mounted || _tutorialAutoStartChecked) return;
    _tutorialAutoStartChecked = true;
    _registerTutorialTargets();
    if (!game.shouldAutoStartTutorial) return;
    TutorialService.instance.attach(
      game: game,
      theme: preferences.selectedTheme,
    );
    TutorialService.instance.maybeAutoStartWelcome(game);
    _wasTutorialActive = TutorialService.instance.isActive;
  }

  void _onCoinTap() {
    _coinTapCount++;
    if (_coinTapCount >= 3) {
      _coinTapCount = 0;
      final bg = preferences.selectedTheme;
      openSecretToolsWithTransition(
        context,
        theme: bg,
        builder: (_) => SecretToolsScreen(
          game: game,
          customSprites: customSprites,
          theme: bg,
        ),
      );
    }
  }

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
      TutorialService.instance.notifyAnimalUpgraded();
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([game, preferences, customSprites]),
      builder: (context, _) {
        final bg = preferences.selectedTheme;

        return AutoBattleNotificationListener(
          game: game,
          theme: bg,
          child: QuestNotificationListener(
            game: game,
            preferences: preferences,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              extendBody: true,
              appBar: PhoneWidthAppBar(
                title: '🐣 Egg Hatchers',
                titleStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
                backgroundColor: bg.appBarColor,
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    tooltip: 'Settings',
                    onPressed: () => openWithThemedTransition(
                      context,
                      theme: bg,
                      icon: '⚙️',
                      label: 'Opening Settings',
                      settings: const RouteSettings(name: kSettingsRouteName),
                      builder: (_) => SettingsScreen(
                        preferences: preferences,
                        customSprites: customSprites,
                        game: game,
                        spriteRating: widget.spriteRating,
                        referenceOverlay: widget.referenceOverlay,
                      ),
                    ),
                    icon: const Icon(Icons.settings_rounded),
                  ),
                ],
              ),
              body: GameBackground(
                theme: bg,
                child: PhoneWidthLayout(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CoinHeader(
                          coins: game.coins,
                          coinsPerSecond: game.coinsPerSecond,
                          lifetimeCoinsEarned: game.lifetimeCoinsEarned,
                          onCoinTap: _onCoinTap,
                          theme: bg,
                        ),
                        const SizedBox(height: 14),
                        DailyRewardCard(game: game, theme: bg),
                        const SizedBox(height: 14),
                        DailyQuestsSummaryCard(
                          game: game,
                          theme: bg,
                          onOpenQuests: () => openWithThemedTransition(
                            context,
                            theme: bg,
                            icon: '⭐',
                            label: 'Opening Quests',
                            settings: const RouteSettings(
                              name: kQuestsRouteName,
                            ),
                            builder: (_) => QuestsScreen(
                              game: game,
                              preferences: preferences,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        LuckPanel(game: game, theme: bg),
                        const SizedBox(height: 14),
                        RebirthPanel(
                          key: TutorialTargets.rebirthPanel,
                          game: game,
                          theme: bg,
                        ),
                        const SizedBox(height: 18),
                        _HatcheryNavGrid(
                          theme: bg,
                          items: [
                            _HatcheryNavItem(
                              tutorialKey: TutorialTargets.battlesButton,
                              label: '⚔️ Battles',
                              color: bg.panelAccentColor.withValues(alpha: 0.9),
                              onTap: () => openBattlesWithTransition(
                                context,
                                theme: bg,
                                builder: (_) => BattlesScreen(
                                  game: game,
                                  preferences: preferences,
                                  customSprites: customSprites,
                                ),
                              ),
                            ),
                            _HatcheryNavItem(
                              tutorialKey: TutorialTargets.shopButton,
                              label: '🛒 Shop',
                              color: bg.secondaryColor,
                              onTap: () => openShopWithTransition(
                                context,
                                theme: bg,
                                builder: (_) => ShopScreen(
                                  game: game,
                                  preferences: preferences,
                                  customSprites: customSprites,
                                  customEggs: customEggs,
                                ),
                              ),
                            ),
                            _HatcheryNavItem(
                              tutorialKey: TutorialTargets.questsButton,
                              label: '🎯 Quests',
                              color: bg.panelAccentColor,
                              onTap: () => openWithThemedTransition(
                                context,
                                theme: bg,
                                icon: '⭐',
                                label: 'Opening Quests',
                                settings: const RouteSettings(
                                  name: kQuestsRouteName,
                                ),
                                builder: (_) => QuestsScreen(
                                  game: game,
                                  preferences: preferences,
                                ),
                              ),
                            ),
                            _HatcheryNavItem(
                              tutorialKey: TutorialTargets.collectionButton,
                              label: '📚 Collection',
                              color: bg.primaryColor,
                              onTap: () => openWithThemedTransition(
                                context,
                                theme: bg,
                                icon: '🐾',
                                label: 'Opening Collection',
                                settings: const RouteSettings(
                                  name: kCollectionRouteName,
                                ),
                                builder: (_) => CollectionScreen(
                                  game: game,
                                  preferences: preferences,
                                  customSprites: customSprites,
                                ),
                              ),
                            ),
                            _HatcheryNavItem(
                              label: '✏️ Custom Animals',
                              color: bg.secondaryColor.withValues(alpha: 0.85),
                              onTap: () => openWithThemedTransition(
                                context,
                                theme: bg,
                                icon: '✏️',
                                label: 'Opening Custom Animals',
                                settings: const RouteSettings(
                                  name: kCustomSpritesRouteName,
                                ),
                                builder: (_) => CustomSpritesScreen(
                                  preferences: preferences,
                                  customSprites: customSprites,
                                  game: game,
                                  spriteRating: widget.spriteRating,
                                  referenceOverlay: widget.referenceOverlay,
                                  returnToHatcheryOnBack: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        KeyedSubtree(
                          key: TutorialTargets.animalsSection,
                          child: Text(
                            'Your Animals',
                            style: GameTheme.sectionTitle(bg),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (game.ownedAnimals.isEmpty)
                          _EmptyHatchery(theme: bg)
                        else
                          OwnedAnimalList(
                            game: game,
                            theme: bg,
                            compact: true,
                            embedInParentScroll: true,
                            customSprites: customSprites,
                            firstCardUpgradeKey: TutorialTargets.upgradeButton,
                            onUpgrade:
                                (animalId, mutationId, name, isProtected) =>
                                    _handleUpgrade(
                                      context,
                                      animalId,
                                      mutationId,
                                      name,
                                      isProtected,
                                    ),
                          ),
                        SizedBox(
                          height: MediaQuery.paddingOf(context).bottom + 24,
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

class _HatcheryNavItem {
  const _HatcheryNavItem({
    this.tutorialKey,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final Key? tutorialKey;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _HatcheryNavGrid extends StatelessWidget {
  const _HatcheryNavGrid({required this.theme, required this.items});

  final BackgroundTheme theme;
  final List<_HatcheryNavItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final useTwoColumns = constraints.maxWidth >= 340;
        final itemWidth = useTwoColumns
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: _NavButton(
                  key: item.tutorialKey,
                  label: item.label,
                  theme: theme,
                  color: item.color,
                  onTap: item.onTap,
                  compact: useTwoColumns,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    super.key,
    required this.label,
    required this.theme,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final BackgroundTheme theme;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: GameTheme.filledButton(
        theme,
        color: color,
        height: compact ? 50 : 56,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: compact ? 16 : 18),
      ),
    );
  }
}

class _EmptyHatchery extends StatelessWidget {
  const _EmptyHatchery({required this.theme});

  final BackgroundTheme theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        decoration: GameTheme.cardDecoration(theme),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🥚', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 14),
            Text(
              'No animals yet.\nHatch your first egg!',
              textAlign: TextAlign.center,
              style: GameTheme.emptyStateTitle(theme),
            ),
            const SizedBox(height: 8),
            Text(
              'Visit the Shop to get started 🐣',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.cardTextSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
