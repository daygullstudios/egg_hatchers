import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../models/background_theme.dart';
import '../services/custom_sprite_service.dart';
import '../services/game_service.dart';
import 'game_sprite.dart';

class HatcheryShowcase extends StatelessWidget {
  const HatcheryShowcase({
    super.key,
    required this.game,
    required this.theme,
    required this.customSprites,
    required this.onOpenCollection,
  });

  final GameService game;
  final BackgroundTheme theme;
  final CustomSpriteService customSprites;
  final VoidCallback onOpenCollection;

  Future<void> _edit(BuildContext context) async {
    final ownedIds = game.ownedAnimals
        .where((a) => a.quantity > 0)
        .map((a) => a.animalId)
        .toSet();
    final selected = game.state.showcaseAnimalIds
        .where(ownedIds.contains)
        .toSet();
    final completed = game.completedCollectionEggs;
    var decoration = completed.any((e) => e.id == game.state.showcaseDecoration)
        ? game.state.showcaseDecoration
        : 'plain';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .75,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Your Nest',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<String>(
                    initialValue: decoration,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Collection decoration',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'plain',
                        child: Text('Simple nest'),
                      ),
                      for (final egg in completed)
                        DropdownMenuItem(
                          value: egg.id,
                          child: Text(
                            '${egg.name} collector',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => decoration = value ?? 'plain'),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      for (final animal in GameData.animals.where(
                        (a) => ownedIds.contains(a.id),
                      ))
                        CheckboxListTile(
                          value: selected.contains(animal.id),
                          title: Text(animal.name),
                          subtitle: Text(
                            '${game.state.animalMasteryWins[animal.id] ?? 0} boss wins',
                          ),
                          secondary: GameSprite(
                            animalId: animal.id,
                            spritePath: animal.spritePath,
                            fallbackEmoji: animal.emoji,
                            size: 42,
                          ),
                          onChanged:
                              selected.contains(animal.id) ||
                                  selected.length < 3
                              ? (value) => setState(() {
                                  if (value == true) {
                                    selected.add(animal.id);
                                  } else {
                                    selected.remove(animal.id);
                                  }
                                })
                              : null,
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Save Nest'),
                    onPressed: () {
                      if (game.setHatcheryShowcase(
                        selected.toList(),
                        decoration,
                      )) {
                        Navigator.pop(sheetContext);
                      } else {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Could not save nest. Check your collection and save status.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ownedIds = game.ownedAnimals
        .where((a) => a.quantity > 0)
        .map((a) => a.animalId)
        .toSet();
    final selected = game.state.showcaseAnimalIds
        .where(ownedIds.contains)
        .take(3)
        .toList();
    if (selected.isEmpty) selected.addAll(ownedIds.take(3));
    final completed = game.completedCollectionEggs;
    final decoration = completed
        .where((e) => e.id == game.state.showcaseDecoration)
        .firstOrNull;
    final goals =
        game.visibleShopEggs
            .where(game.isEggUnlocked)
            .where((egg) => !completed.any((e) => e.id == egg.id))
            .where(
              (egg) =>
                  egg.possibleAnimalIds.any((id) => !ownedIds.contains(id)),
            )
            .toList()
          ..sort(
            (a, b) => a.possibleAnimalIds
                .where((id) => !ownedIds.contains(id))
                .length
                .compareTo(
                  b.possibleAnimalIds
                      .where((id) => !ownedIds.contains(id))
                      .length,
                ),
          );
    final next = goals.firstOrNull;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your Nest',
                  style: TextStyle(
                    color: theme.cardTextPrimaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Customize nest',
                onPressed: () => _edit(context),
                icon: Icon(
                  Icons.edit_outlined,
                  color: theme.cardTextPrimaryColor,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 156,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (decoration != null)
                  Positioned(
                    top: 0,
                    child: Opacity(
                      opacity: .3,
                      child: GameEggSprite(egg: decoration, size: 112),
                    ),
                  ),
                Positioned(
                  bottom: 8,
                  left: 12,
                  right: 12,
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: theme.cardColor,
                      border: Border.all(
                        color: decoration == null
                            ? theme.primaryColor
                            : Colors.amber,
                        width: 3,
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final id in selected)
                      if (GameData.animalById(id) case final animal?)
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GameSprite(
                                animalId: id,
                                spritePath: animal.spritePath,
                                fallbackEmoji: animal.emoji,
                                customSprite: customSprites.getDisplaySprite(
                                  id,
                                ),
                                size: 72,
                              ),
                              Text(
                                animal.name,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.cardTextPrimaryColor,
                                  fontSize: 11,
                                ),
                              ),
                              if ((game.state.animalMasteryWins[id] ?? 0) >= 1)
                                Text(
                                  (game.state.animalMasteryWins[id] ?? 0) >= 25
                                      ? 'Master'
                                      : (game.state.animalMasteryWins[id] ??
                                                0) >=
                                            10
                                      ? 'Veteran'
                                      : 'Challenger',
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    if (selected.isEmpty)
                      Icon(
                        Icons.egg_outlined,
                        size: 56,
                        color: theme.primaryColor,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (decoration != null)
            Text(
              '${decoration.name} Collector',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.cardTextPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (game.state.onlineArenaWins + game.state.onlineArenaLosses > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.handshake_outlined,
                    color: theme.primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Arena Adventurer',
                    style: TextStyle(color: theme.cardTextPrimaryColor),
                  ),
                ],
              ),
            ),
          if (completed.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  for (final egg in completed)
                    Tooltip(
                      message: '${egg.name} collection complete',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            size: 18,
                            color: theme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            egg.name,
                            style: TextStyle(color: theme.cardTextPrimaryColor),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (next != null)
            TextButton.icon(
              onPressed: onOpenCollection,
              icon: const Icon(Icons.collections_bookmark_outlined),
              label: Text(
                '${next.possibleAnimalIds.where((id) => !ownedIds.contains(id)).length} more to complete ${next.name}',
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
