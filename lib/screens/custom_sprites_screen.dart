import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../models/animal.dart';
import '../models/background_theme.dart';
import '../models/custom_sprite_data.dart';
import '../navigation/app_page_route.dart';
import '../services/custom_sprite_service.dart';
import '../services/game_service.dart';
import '../services/preferences_service.dart';
import '../services/sprite_rating_service.dart';
import '../services/sprite_reference_overlay_service.dart';
import '../theme/game_theme.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/builtin_sprite_preview_sheet.dart';
import '../widgets/custom_sprite_preview.dart';
import '../widgets/game_background.dart';
import '../widgets/game_primary_navigation.dart';
import '../widgets/phone_width_layout.dart';
import 'sprite_editor_screen.dart';

enum _CustomAnimalFilter { all, customized, original }

enum _CustomAnimalSort { rarity, name, progression }

/// Lists all animals so the player can create or edit custom sprites.
class CustomSpritesScreen extends StatefulWidget {
  const CustomSpritesScreen({
    super.key,
    required this.preferences,
    required this.customSprites,
    required this.game,
    required this.spriteRating,
    required this.referenceOverlay,
    this.returnToHatcheryOnBack = false,
  });

  final PreferencesService preferences;
  final CustomSpriteService customSprites;
  final GameService game;
  final SpriteRatingService spriteRating;
  final SpriteReferenceOverlayService referenceOverlay;
  final bool returnToHatcheryOnBack;

  @override
  State<CustomSpritesScreen> createState() => _CustomSpritesScreenState();
}

class _CustomSpritesScreenState extends State<CustomSpritesScreen> {
  var _filter = _CustomAnimalFilter.all;
  var _sort = _CustomAnimalSort.rarity;
  var _searchQuery = '';
  var _toolsExpanded = false;

  PreferencesService get preferences => widget.preferences;
  CustomSpriteService get customSprites => widget.customSprites;
  GameService get game => widget.game;
  SpriteRatingService get spriteRating => widget.spriteRating;
  SpriteReferenceOverlayService get referenceOverlay => widget.referenceOverlay;
  bool get returnToHatcheryOnBack => widget.returnToHatcheryOnBack;

  List<Animal> _visibleAnimals() {
    final query = _searchQuery.trim().toLowerCase();
    final animals = GameData.animals.where((animal) {
      final hasCustom = customSprites.hasCustomSprite(animal.id);
      final matchesFilter = switch (_filter) {
        _CustomAnimalFilter.all => true,
        _CustomAnimalFilter.customized => hasCustom,
        _CustomAnimalFilter.original => !hasCustom,
      };
      return matchesFilter &&
          (query.isEmpty || animal.name.toLowerCase().contains(query));
    }).toList();

    switch (_sort) {
      case _CustomAnimalSort.rarity:
        animals.sort((a, b) {
          final rarity = b.rarity.sortOrder.compareTo(a.rarity.sortOrder);
          if (rarity != 0) return rarity;
          return a.name.compareTo(b.name);
        });
      case _CustomAnimalSort.name:
        animals.sort((a, b) => a.name.compareTo(b.name));
      case _CustomAnimalSort.progression:
        animals.sort(
          (a, b) => GameData.progressionIndexForAnimal(
            a.id,
          ).compareTo(GameData.progressionIndexForAnimal(b.id)),
        );
    }
    return animals;
  }

  Future<void> _confirmResetAll(
    BuildContext context,
    BackgroundTheme theme,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GameTheme.cardRadius),
        ),
        title: Text(
          'Reset All Custom Animals?',
          style: TextStyle(
            color: theme.cardTextPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This will delete all custom animal sprites and restore the '
          'original sprites. This cannot be undone.',
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
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Reset All'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await customSprites.resetAllCustomSprites();
    await spriteRating.clearAllClaims();
    if (!context.mounted) return;

    showGameSnackBar(
      context,
      message: 'All custom animals reset.',
      backgroundColor: Colors.red.shade400,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([preferences, customSprites]),
      builder: (context, _) {
        final theme = preferences.selectedTheme;
        final shell = MainGameShellScope.maybeOf(context);
        final animals = _visibleAnimals();
        final customizedCount = GameData.animals
            .where((animal) => customSprites.hasCustomSprite(animal.id))
            .length;

        final scaffold = Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PhoneWidthAppBar(
            title: '🎨 Custom Animals',
            titleStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
            backgroundColor: theme.appBarColor,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: shell == null && !returnToHatcheryOnBack,
            leading: shell == null && returnToHatcheryOnBack
                ? ReturnToHatcheryBackButton(theme: theme, color: Colors.white)
                : null,
            bottom: shell == null
                ? null
                : GamePrimaryNavigation(
                    theme: theme,
                    hostDestination: MainGameDestination.customAnimals,
                  ),
          ),
          body: GameBackground(
            theme: theme,
            child: PhoneWidthLayout(
              child: Column(
                children: [
                  _CustomAnimalTools(
                    theme: theme,
                    expanded: _toolsExpanded,
                    customizedCount: customizedCount,
                    totalCount: GameData.animals.length,
                    showCustomSprites: customSprites.showCustomSprites,
                    onToggle: () =>
                        setState(() => _toolsExpanded = !_toolsExpanded),
                    onVisibilityChanged: customSprites.setShowCustomSprites,
                    onResetAll: () => _confirmResetAll(context, theme),
                  ),
                  const SizedBox(height: 10),
                  _CustomAnimalControls(
                    theme: theme,
                    filter: _filter,
                    sort: _sort,
                    onSearchChanged: (value) =>
                        setState(() => _searchQuery = value),
                    onFilterChanged: (value) => setState(() => _filter = value),
                    onSortChanged: (value) => setState(() => _sort = value),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: animals.isEmpty
                        ? Center(
                            child: Text(
                              'No animals match these filters.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.cardTextSecondaryColor,
                                fontSize: 15,
                              ),
                            ),
                          )
                        : ListView.separated(
                            key: const PageStorageKey('custom-animal-results'),
                            padding: EdgeInsets.zero,
                            itemCount: animals.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final animal = animals[index];
                              return _AnimalSpriteTile(
                                animal: animal,
                                theme: theme,
                                preferences: preferences,
                                hasCustom: customSprites.hasCustomSprite(
                                  animal.id,
                                ),
                                customSprite: customSprites.getSprite(
                                  animal.id,
                                ),
                                onTap: () => openWithThemedTransition(
                                  context,
                                  theme: theme,
                                  icon: '✏️',
                                  label: 'Opening Editor',
                                  duration: kEditorThemedPreNavDuration,
                                  builder: (_) => SpriteEditorScreen(
                                    animal: animal,
                                    theme: theme,
                                    customSprites: customSprites,
                                    game: game,
                                    spriteRating: spriteRating,
                                    referenceOverlay: referenceOverlay,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );

        if (returnToHatcheryOnBack) {
          return ReturnToHatcheryPopScope(theme: theme, child: scaffold);
        }
        return scaffold;
      },
    );
  }
}

class _CustomAnimalTools extends StatelessWidget {
  const _CustomAnimalTools({
    required this.theme,
    required this.expanded,
    required this.customizedCount,
    required this.totalCount,
    required this.showCustomSprites,
    required this.onToggle,
    required this.onVisibilityChanged,
    required this.onResetAll,
  });

  final BackgroundTheme theme;
  final bool expanded;
  final int customizedCount;
  final int totalCount;
  final bool showCustomSprites;
  final VoidCallback onToggle;
  final ValueChanged<bool> onVisibilityChanged;
  final VoidCallback onResetAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: GameTheme.cardDecoration(theme),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              key: const ValueKey('custom-animal-tools-toggle'),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, color: theme.primaryColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Custom Animal Tools',
                            style: TextStyle(
                              color: theme.cardTextPrimaryColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '$customizedCount/$totalCount customized · '
                            '${showCustomSprites ? 'shown' : 'hidden'} in game',
                            style: TextStyle(
                              color: theme.cardTextSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: theme.cardTextSecondaryColor,
                    ),
                  ],
                ),
              ),
            ),
            if (expanded) ...[
              Divider(height: 1, color: theme.cardBorderColor),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Draw your own 16×16 sprites for any animal. Custom art '
                      'is saved only on this device and is not shared online.',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.cardTextSecondaryColor,
                        height: 1.35,
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Show Custom Animals',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.cardTextPrimaryColor,
                        ),
                      ),
                      subtitle: Text(
                        showCustomSprites
                            ? 'Custom art appears in the game'
                            : 'Custom art is hidden but remains saved',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.cardTextSecondaryColor,
                        ),
                      ),
                      value: showCustomSprites,
                      activeThumbColor: theme.primaryColor,
                      onChanged: onVisibilityChanged,
                    ),
                    OutlinedButton.icon(
                      onPressed: customizedCount == 0 ? null : onResetAll,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Reset All Custom Animals'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CustomAnimalControls extends StatelessWidget {
  const _CustomAnimalControls({
    required this.theme,
    required this.filter,
    required this.sort,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  final BackgroundTheme theme;
  final _CustomAnimalFilter filter;
  final _CustomAnimalSort sort;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_CustomAnimalFilter> onFilterChanged;
  final ValueChanged<_CustomAnimalSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('custom-animal-controls'),
      padding: const EdgeInsets.all(10),
      decoration: GameTheme.cardDecoration(theme),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            TextField(
              key: const ValueKey('custom-animal-search'),
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
                  child: DropdownButtonFormField<_CustomAnimalFilter>(
                    key: const ValueKey('custom-animal-filter'),
                    initialValue: filter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Show',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: _CustomAnimalFilter.all,
                        child: Text('All'),
                      ),
                      DropdownMenuItem(
                        value: _CustomAnimalFilter.customized,
                        child: Text('Customized'),
                      ),
                      DropdownMenuItem(
                        value: _CustomAnimalFilter.original,
                        child: Text('Original'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) onFilterChanged(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<_CustomAnimalSort>(
                    key: const ValueKey('custom-animal-sort'),
                    initialValue: sort,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Sort',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: _CustomAnimalSort.rarity,
                        child: Text('Rarity'),
                      ),
                      DropdownMenuItem(
                        value: _CustomAnimalSort.name,
                        child: Text('Name'),
                      ),
                      DropdownMenuItem(
                        value: _CustomAnimalSort.progression,
                        child: Text('Progression'),
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
      ),
    );
  }
}

class _AnimalSpriteTile extends StatelessWidget {
  const _AnimalSpriteTile({
    required this.animal,
    required this.theme,
    required this.preferences,
    required this.hasCustom,
    required this.customSprite,
    required this.onTap,
  });

  final Animal animal;
  final BackgroundTheme theme;
  final PreferencesService preferences;
  final bool hasCustom;
  final CustomSpriteData? customSprite;
  final VoidCallback onTap;

  void _openLargePreview(BuildContext context) {
    showBuiltinSpritePreviewSheet(
      context: context,
      animal: animal,
      preferences: preferences,
      customSprite: customSprite,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GameTheme.cardRadius),
        child: Container(
          decoration: GameTheme.cardDecoration(theme),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _openLargePreview(context),
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.cardBorderColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomSpritePreview(
                        customSprite: customSprite,
                        animalId: animal.id,
                        spritePath: animal.spritePath,
                        fallbackEmoji: animal.emoji,
                        size: 44,
                        emojiFontSize: 30,
                        semanticLabel: animal.name,
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Icon(
                          Icons.zoom_in_rounded,
                          size: 14,
                          color: theme.primaryColor.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animal.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: theme.cardTextPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasCustom ? '✏️ Custom sprite saved' : 'Tap to draw',
                      style: TextStyle(
                        fontSize: 13,
                        color: hasCustom
                            ? theme.primaryColor
                            : theme.cardTextSecondaryColor,
                        fontWeight: hasCustom
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.cardTextSecondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
