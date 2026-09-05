import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../models/background_theme.dart';
import '../models/owned_animal.dart';
import '../services/custom_sprite_service.dart';
import '../services/game_service.dart';
import '../services/preferences_service.dart';
import '../services/tutorial_service.dart';
import '../theme/game_theme.dart';
import '../utils/format_utils.dart';
import '../utils/snackbar_utils.dart';
import '../utils/ui_sound.dart';
import '../navigation/app_page_route.dart';
import '../widgets/tutorial_screen_bindings.dart';
import '../widgets/tutorial_targets.dart';
import '../widgets/animal_fusion_panel.dart';
import '../widgets/game_background.dart';
import '../widgets/game_primary_navigation.dart';
import '../widgets/owned_animal_list.dart';
import '../widgets/phone_width_layout.dart';
import '../widgets/quest_notification_listener.dart';

/// Shows every animal the player owns with quantities, levels, and income.
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({
    super.key,
    required this.game,
    required this.preferences,
    required this.customSprites,
  });

  final GameService game;
  final PreferencesService preferences;
  final CustomSpriteService customSprites;

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

enum _CollectionMode { animals, fusion }

enum _CollectionMutationFilter { all, normal, mutated }

enum _CollectionSort { rarity, name, income, level, quantity }

class _CollectionScreenState extends State<CollectionScreen> {
  var _mode = _CollectionMode.animals;
  var _mutationFilter = _CollectionMutationFilter.all;
  var _sort = _CollectionSort.rarity;
  var _searchQuery = '';

  GameService get game => widget.game;
  PreferencesService get preferences => widget.preferences;
  CustomSpriteService get customSprites => widget.customSprites;

  @override
  void initState() {
    super.initState();
    TutorialService.instance.addListener(_syncTutorialMode);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncTutorialMode());
  }

  @override
  void dispose() {
    TutorialService.instance.removeListener(_syncTutorialMode);
    super.dispose();
  }

  void _syncTutorialMode() {
    if (!mounted) return;
    if (TutorialService.instance.currentStep?.id != 'fusion') return;
    if (_mode == _CollectionMode.fusion) return;
    setState(() => _mode = _CollectionMode.fusion);
  }

  List<OwnedAnimal> _visibleAnimals() {
    final query = _searchQuery.trim().toLowerCase();
    final animals = game.ownedAnimals.where((owned) {
      final isNormal = owned.mutationId == 'none';
      if (_mutationFilter == _CollectionMutationFilter.normal && !isNormal) {
        return false;
      }
      if (_mutationFilter == _CollectionMutationFilter.mutated && isNormal) {
        return false;
      }
      if (query.isEmpty) return true;
      final animal = GameData.animalById(owned.animalId);
      final mutation = GameData.mutationById(owned.mutationId);
      final name = animal == null
          ? owned.animalId
          : (mutation ?? GameData.mutations.first).fullName(animal);
      return name.toLowerCase().contains(query);
    }).toList();

    animals.sort((a, b) {
      final animalA = GameData.animalById(a.animalId);
      final animalB = GameData.animalById(b.animalId);
      switch (_sort) {
        case _CollectionSort.rarity:
          return GameData.compareOwnedAnimals(a.animalId, b.animalId);
        case _CollectionSort.name:
          return (animalA?.name ?? a.animalId).compareTo(
            animalB?.name ?? b.animalId,
          );
        case _CollectionSort.income:
          final incomeA = animalA == null ? 0 : game.incomeForOwned(animalA, a);
          final incomeB = animalB == null ? 0 : game.incomeForOwned(animalB, b);
          return incomeB.compareTo(incomeA);
        case _CollectionSort.level:
          return b.level.compareTo(a.level);
        case _CollectionSort.quantity:
          return b.quantity.compareTo(a.quantity);
      }
    });
    return animals;
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
              backgroundColor: theme.secondaryColor,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.sell_rounded),
            label: const Text('Sell All'),
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
        final shell = MainGameShellScope.maybeOf(context);
        final visibleAnimals = _visibleAnimals();

        return TutorialScreenBindings(
          enabled:
              shell == null || shell.current == MainGameDestination.collection,
          onReturnToHatchery: () =>
              returnToHatcheryWithTransition(context, theme: bg),
          child: ReturnToHatcheryPopScope(
            theme: bg,
            enabled: shell == null,
            child: QuestNotificationListener(
              game: game,
              preferences: preferences,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: PhoneWidthAppBar(
                  title: '📚 Collection',
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
                          hostDestination: MainGameDestination.collection,
                        ),
                ),
                body: GameBackground(
                  theme: bg,
                  child: PhoneWidthLayout(
                    child: Column(
                      children: [
                        _CollectionModeSelector(
                          theme: bg,
                          selected: _mode,
                          animalCount: game.ownedAnimals.length,
                          fusionCount: game.ownedAnimals
                              .where(
                                (owned) =>
                                    owned.quantity >= 2 &&
                                    owned.mutationId != 'shadow' &&
                                    owned.mutationId != 'boss',
                              )
                              .length,
                          onSelected: (mode) => setState(() => _mode = mode),
                        ),
                        const SizedBox(height: 10),
                        if (_mode == _CollectionMode.animals)
                          _CollectionControls(
                            theme: bg,
                            mutationFilter: _mutationFilter,
                            sort: _sort,
                            onSearchChanged: (value) =>
                                setState(() => _searchQuery = value),
                            onMutationFilterChanged: (value) =>
                                setState(() => _mutationFilter = value),
                            onSortChanged: (value) =>
                                setState(() => _sort = value),
                          ),
                        if (_mode == _CollectionMode.animals)
                          const SizedBox(height: 10),
                        Expanded(
                          child: _mode == _CollectionMode.fusion
                              ? SingleChildScrollView(
                                  child: AnimalFusionPanel(
                                    game: game,
                                    theme: bg,
                                    customSprites: customSprites,
                                    tutorialSectionKey:
                                        TutorialTargets.fusionSection,
                                  ),
                                )
                              : game.ownedAnimals.isEmpty
                              ? _EmptyCollection(theme: bg)
                              : visibleAnimals.isEmpty
                              ? _NoCollectionMatches(theme: bg)
                              : OwnedAnimalList(
                                  game: game,
                                  theme: bg,
                                  separatorHeight: 12,
                                  customSprites: customSprites,
                                  entries: visibleAnimals,
                                  sortEntries: false,
                                  showSellButtons: true,
                                  onUpgrade:
                                      (
                                        animalId,
                                        mutationId,
                                        name,
                                        isProtected,
                                      ) => _handleUpgrade(
                                        context,
                                        animalId,
                                        mutationId,
                                        name,
                                        isProtected,
                                      ),
                                  onSellOne:
                                      (
                                        animalId,
                                        mutationId,
                                        name,
                                        _,
                                        isProtected,
                                      ) => _handleSellOne(
                                        context,
                                        animalId,
                                        mutationId,
                                        name,
                                        isProtected,
                                      ),
                                  onSellAll:
                                      (
                                        animalId,
                                        mutationId,
                                        name,
                                        qty,
                                        total,
                                        isProtected,
                                      ) => _handleSellAll(
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

class _CollectionModeSelector extends StatelessWidget {
  const _CollectionModeSelector({
    required this.theme,
    required this.selected,
    required this.animalCount,
    required this.fusionCount,
    required this.onSelected,
  });

  final BackgroundTheme theme;
  final _CollectionMode selected;
  final int animalCount;
  final int fusionCount;
  final ValueChanged<_CollectionMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_CollectionMode>(
      key: const ValueKey('collection-mode-selector'),
      segments: [
        ButtonSegment(
          value: _CollectionMode.animals,
          icon: const Icon(Icons.pets_rounded),
          label: Text('Animals ($animalCount)'),
        ),
        ButtonSegment(
          value: _CollectionMode.fusion,
          icon: const Icon(Icons.merge_rounded),
          label: Text(fusionCount == 0 ? 'Fusion' : 'Fusion ($fusionCount)'),
        ),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onSelected(selection.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : theme.cardTextPrimaryColor,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? theme.primaryColor
              : theme.cardColor.withValues(alpha: 0.86),
        ),
        side: WidgetStatePropertyAll(BorderSide(color: theme.primaryColor)),
      ),
    );
  }
}

class _CollectionControls extends StatelessWidget {
  const _CollectionControls({
    required this.theme,
    required this.mutationFilter,
    required this.sort,
    required this.onSearchChanged,
    required this.onMutationFilterChanged,
    required this.onSortChanged,
  });

  final BackgroundTheme theme;
  final _CollectionMutationFilter mutationFilter;
  final _CollectionSort sort;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_CollectionMutationFilter> onMutationFilterChanged;
  final ValueChanged<_CollectionSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('collection-controls'),
      padding: const EdgeInsets.all(10),
      decoration: GameTheme.cardDecoration(theme),
      child: Column(
        children: [
          TextField(
            key: const ValueKey('collection-search'),
            onChanged: onSearchChanged,
            style: TextStyle(color: theme.cardTextPrimaryColor, fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Find an animal',
              hintStyle: TextStyle(color: theme.cardTextSecondaryColor),
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<_CollectionMutationFilter>(
                  key: const ValueKey('collection-mutation-filter'),
                  initialValue: mutationFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Mutation',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: _CollectionMutationFilter.all,
                      child: Text('All'),
                    ),
                    DropdownMenuItem(
                      value: _CollectionMutationFilter.normal,
                      child: Text('Normal'),
                    ),
                    DropdownMenuItem(
                      value: _CollectionMutationFilter.mutated,
                      child: Text('Mutated'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) onMutationFilterChanged(value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<_CollectionSort>(
                  key: const ValueKey('collection-sort'),
                  initialValue: sort,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Sort',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: _CollectionSort.rarity,
                      child: Text('Rarity'),
                    ),
                    DropdownMenuItem(
                      value: _CollectionSort.name,
                      child: Text('Name'),
                    ),
                    DropdownMenuItem(
                      value: _CollectionSort.income,
                      child: Text('Income'),
                    ),
                    DropdownMenuItem(
                      value: _CollectionSort.level,
                      child: Text('Level'),
                    ),
                    DropdownMenuItem(
                      value: _CollectionSort.quantity,
                      child: Text('Quantity'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) onSortChanged(value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoCollectionMatches extends StatelessWidget {
  const _NoCollectionMatches({required this.theme});

  final BackgroundTheme theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No animals match these filters.',
        style: TextStyle(
          color: theme.cardTextSecondaryColor,
          fontWeight: FontWeight.w700,
        ),
      ),
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
