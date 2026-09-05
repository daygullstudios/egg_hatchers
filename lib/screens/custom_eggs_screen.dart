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

enum _CustomEggFilter { all, enabled, disabled, needsAttention }

enum _CustomEggSort { recent, name, price }

/// Lists saved custom eggs and lets the player create or manage them.
class CustomEggsScreen extends StatefulWidget {
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

  @override
  State<CustomEggsScreen> createState() => _CustomEggsScreenState();
}

class _CustomEggsScreenState extends State<CustomEggsScreen> {
  var _filter = _CustomEggFilter.all;
  var _sort = _CustomEggSort.recent;
  var _searchQuery = '';
  String? _expandedEggId;

  GameService get game => widget.game;
  PreferencesService get preferences => widget.preferences;
  CustomEggService get customEggs => widget.customEggs;
  CustomSpriteService get customSprites => widget.customSprites;

  List<CustomEgg> _visibleEggs() {
    final query = _searchQuery.trim().toLowerCase();
    final eggs = customEggs.allEggs.where((egg) {
      final matchesFilter = switch (_filter) {
        _CustomEggFilter.all => true,
        _CustomEggFilter.enabled => egg.isEnabled && egg.isValid,
        _CustomEggFilter.disabled => !egg.isEnabled && egg.isValid,
        _CustomEggFilter.needsAttention => !egg.isValid,
      };
      return matchesFilter &&
          (query.isEmpty || egg.name.toLowerCase().contains(query));
    }).toList();

    switch (_sort) {
      case _CustomEggSort.recent:
        return eggs.reversed.toList(growable: false);
      case _CustomEggSort.name:
        eggs.sort((a, b) => a.name.compareTo(b.name));
      case _CustomEggSort.price:
        eggs.sort((a, b) {
          final price = a.cost.compareTo(b.cost);
          return price != 0 ? price : a.name.compareTo(b.name);
        });
    }
    return eggs;
  }

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
          style: TextStyle(color: theme.cardTextSecondaryColor, fontSize: 14),
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
      listenable: Listenable.merge([
        game,
        preferences,
        customEggs,
        customSprites,
      ]),
      builder: (context, _) {
        final theme = preferences.selectedTheme;
        final allEggs = customEggs.allEggs;
        final eggs = _visibleEggs();

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PhoneWidthAppBar(
            title: '🥚 Custom Eggs',
            titleStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
            backgroundColor: theme.appBarColor,
            foregroundColor: Colors.white,
          ),
          body: GameBackground(
            theme: theme,
            child: PhoneWidthLayout(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  const SizedBox(height: 10),
                  Text(
                    'Saved only on this device · ${allEggs.length} custom '
                    'egg${allEggs.length == 1 ? '' : 's'}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.cardTextSecondaryColor,
                    ),
                  ),
                  if (allEggs.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _CustomEggControls(
                      theme: theme,
                      filter: _filter,
                      sort: _sort,
                      onSearchChanged: (value) =>
                          setState(() => _searchQuery = value),
                      onFilterChanged: (value) =>
                          setState(() => _filter = value),
                      onSortChanged: (value) => setState(() => _sort = value),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Expanded(
                    child: allEggs.isEmpty
                        ? _EmptyCustomEggs(theme: theme)
                        : eggs.isEmpty
                        ? Center(
                            child: Text(
                              'No custom eggs match these filters.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: theme.cardTextSecondaryColor,
                              ),
                            ),
                          )
                        : ListView.separated(
                            key: const PageStorageKey('custom-egg-results'),
                            padding: EdgeInsets.zero,
                            itemCount: eggs.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final egg = eggs[index];
                              return _CustomEggTile(
                                key: ValueKey('custom-egg-${egg.id}'),
                                egg: egg,
                                theme: theme,
                                customSprites: customSprites,
                                expanded: _expandedEggId == egg.id,
                                onToggle: () => setState(
                                  () => _expandedEggId =
                                      _expandedEggId == egg.id ? null : egg.id,
                                ),
                                onEdit: () => _openEditor(context, egg: egg),
                                onDelete: () =>
                                    _confirmDelete(context, theme, egg),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CustomEggControls extends StatelessWidget {
  const _CustomEggControls({
    required this.theme,
    required this.filter,
    required this.sort,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  final BackgroundTheme theme;
  final _CustomEggFilter filter;
  final _CustomEggSort sort;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_CustomEggFilter> onFilterChanged;
  final ValueChanged<_CustomEggSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('custom-egg-controls'),
      padding: const EdgeInsets.all(10),
      decoration: GameTheme.cardDecoration(theme),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            TextField(
              key: const ValueKey('custom-egg-search'),
              onChanged: onSearchChanged,
              style: TextStyle(color: theme.cardTextPrimaryColor, fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Find a custom egg',
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
                  child: DropdownButtonFormField<_CustomEggFilter>(
                    key: const ValueKey('custom-egg-filter'),
                    initialValue: filter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: _CustomEggFilter.all,
                        child: Text('All'),
                      ),
                      DropdownMenuItem(
                        value: _CustomEggFilter.enabled,
                        child: Text('Enabled'),
                      ),
                      DropdownMenuItem(
                        value: _CustomEggFilter.disabled,
                        child: Text('Disabled'),
                      ),
                      DropdownMenuItem(
                        value: _CustomEggFilter.needsAttention,
                        child: Text('Needs attention'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) onFilterChanged(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<_CustomEggSort>(
                    key: const ValueKey('custom-egg-sort'),
                    initialValue: sort,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Sort',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: _CustomEggSort.recent,
                        child: Text('Newest'),
                      ),
                      DropdownMenuItem(
                        value: _CustomEggSort.name,
                        child: Text('Name'),
                      ),
                      DropdownMenuItem(
                        value: _CustomEggSort.price,
                        child: Text('Price'),
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

class _EmptyCustomEggs extends StatelessWidget {
  const _EmptyCustomEggs({required this.theme});

  final BackgroundTheme theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
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
      ),
    );
  }
}

class _CustomEggTile extends StatelessWidget {
  const _CustomEggTile({
    super.key,
    required this.egg,
    required this.theme,
    required this.customSprites,
    required this.expanded,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final CustomEgg egg;
  final BackgroundTheme theme;
  final CustomSpriteService customSprites;
  final bool expanded;
  final VoidCallback onToggle;
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
      decoration: GameTheme.cardDecoration(theme, locked: !egg.isValid),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              key: ValueKey('custom-egg-toggle-${egg.id}'),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
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
                            '🪙 ${formatCoins(egg.cost)}  •  '
                            '$validCount animals',
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
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (previewAnimals.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final animal in previewAnimals)
                            Tooltip(
                              message: animal.name,
                              child: GameSprite(
                                customSprite: customSprites.getDisplaySprite(
                                  animal.id,
                                ),
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
                      const SizedBox(height: 12),
                    ],
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
              ),
            ],
          ],
        ),
      ),
    );
  }
}
