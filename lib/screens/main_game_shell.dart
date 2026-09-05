import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';
import '../services/custom_egg_service.dart';
import '../services/custom_sprite_service.dart';
import '../services/game_service.dart';
import '../services/preferences_service.dart';
import '../services/sprite_rating_service.dart';
import '../services/sprite_reference_overlay_service.dart';
import '../widgets/game_primary_navigation.dart';
import 'battles_screen.dart';
import 'collection_screen.dart';
import 'custom_sprites_screen.dart';
import 'hatchery_screen.dart';
import 'quests_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';

/// Persistent shell for the primary game destinations.
class MainGameShell extends StatefulWidget {
  const MainGameShell({
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
  State<MainGameShell> createState() => _MainGameShellState();
}

class _MainGameShellState extends State<MainGameShell> {
  var _current = MainGameDestination.hatchery;
  late final VoidCallback _selectHatchery;

  @override
  void initState() {
    super.initState();
    _selectHatchery = () => _select(MainGameDestination.hatchery);
    AppNavigationTracker.instance.attachShellHatcherySelector(_selectHatchery);
    AppNavigationTracker.instance.setShellRouteName(kHatcheryRouteName);
  }

  @override
  void dispose() {
    AppNavigationTracker.instance.detachShellHatcherySelector(_selectHatchery);
    super.dispose();
  }

  String _routeName(MainGameDestination destination) {
    return switch (destination) {
      MainGameDestination.hatchery => kHatcheryRouteName,
      MainGameDestination.shop => kShopRouteName,
      MainGameDestination.battles => kBattlesRouteName,
      MainGameDestination.collection => kCollectionRouteName,
      MainGameDestination.quests => kQuestsRouteName,
      MainGameDestination.customAnimals => kCustomSpritesRouteName,
      MainGameDestination.settings => kSettingsRouteName,
    };
  }

  void _select(MainGameDestination destination) {
    if (_current == destination) return;
    setState(() => _current = destination);
    AppNavigationTracker.instance.setShellRouteName(_routeName(destination));
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HatcheryScreen(
        game: widget.game,
        preferences: widget.preferences,
        customSprites: widget.customSprites,
        customEggs: widget.customEggs,
      ),
      ShopScreen(
        game: widget.game,
        preferences: widget.preferences,
        customSprites: widget.customSprites,
        customEggs: widget.customEggs,
      ),
      BattlesScreen(
        game: widget.game,
        preferences: widget.preferences,
        customSprites: widget.customSprites,
      ),
      CollectionScreen(
        game: widget.game,
        preferences: widget.preferences,
        customSprites: widget.customSprites,
      ),
      QuestsScreen(game: widget.game, preferences: widget.preferences),
      CustomSpritesScreen(
        preferences: widget.preferences,
        customSprites: widget.customSprites,
        game: widget.game,
        spriteRating: widget.spriteRating,
        referenceOverlay: widget.referenceOverlay,
      ),
      SettingsScreen(preferences: widget.preferences, game: widget.game),
    ];

    return MainGameShellScope(
      current: _current,
      game: widget.game,
      onSelect: _select,
      child: PopScope(
        canPop: _current == MainGameDestination.hatchery,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _current != MainGameDestination.hatchery) {
            _select(MainGameDestination.hatchery);
          }
        },
        child: IndexedStack(index: _current.index, children: pages),
      ),
    );
  }
}
