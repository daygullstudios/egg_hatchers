import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../models/background_theme.dart';
import '../models/owned_animal.dart';
import '../services/game_service.dart';
import '../utils/halloween_fusion_logic.dart';
import 'game_sprite.dart';

class HalloweenFusionPanel extends StatefulWidget {
  const HalloweenFusionPanel({
    super.key,
    required this.game,
    required this.theme,
  });
  final GameService game;
  final BackgroundTheme theme;

  @override
  State<HalloweenFusionPanel> createState() => _HalloweenFusionPanelState();
}

class _HalloweenFusionPanelState extends State<HalloweenFusionPanel> {
  final _selected = <OwnedAnimal>[];
  bool _busy = false;

  bool _same(OwnedAnimal a, OwnedAnimal b) =>
      a.animalId == b.animalId &&
      a.mutationId == b.mutationId &&
      a.isProtected == b.isProtected;

  Future<void> _fuse() async {
    if (_busy) return;
    final game = widget.game;
    final accountId = game.activeAccountId;
    final selections = List<OwnedAnimal>.of(_selected);
    final power = game.randomFusionPower(selections);
    if (power == null) return;
    setState(() => _busy = true);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Halloween fusion?'),
        content: const Text(
          'Consumes all 4 selected pets permanently and gives 1 random Halloween pet. The result may earn less than the pets you spend.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Fuse 4 pets'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed != true) {
      setState(() => _busy = false);
      return;
    }
    // Revalidate inventory and event availability after the confirmation.
    final result =
        game.activeAccountId == accountId &&
            game.randomFusionPower(selections) == power
        ? game.randomFuseAnimals(selections)
        : null;
    setState(() {
      _busy = false;
      _selected.clear();
    });
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fusion unavailable. Check your pets and event dates.'),
        ),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Halloween fusion complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: .2, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: GameSprite(
                animalId: result.id,
                spritePath: result.spritePath,
                fallbackEmoji: result.emoji,
                size: 140,
              ),
            ),
            Text(result.name, textAlign: TextAlign.center),
            Text('${result.coinsPerSecond} coins/sec base income'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep pet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    if (!game.halloweenFusionActive) return const SizedBox.shrink();
    final candidates = game.ownedAnimals
        .where(game.canUseInRandomFusion)
        .toList();
    final power = game.randomFusionPower(_selected);
    final odds = power == null
        ? null
        : HalloweenFusionLogic.probabilities(power);
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: widget.theme.cardTextPrimaryColor,
          displayColor: widget.theme.cardTextPrimaryColor,
        ),
        listTileTheme: ListTileThemeData(
          textColor: widget.theme.cardTextPrimaryColor,
        ),
        iconTheme: IconThemeData(color: widget.theme.cardTextPrimaryColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 20, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Halloween Random Fusion',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: widget.theme.cardTextPrimaryColor,
              ),
            ),
            Text(
              'Oct 24 - Nov 2, 2026 (UTC)',
              style: TextStyle(color: widget.theme.cardTextSecondaryColor),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                4,
                (i) => Expanded(
                  child: SizedBox(
                    height: 86,
                    child: i >= _selected.length
                        ? const Icon(
                            Icons.add_circle_outline,
                            color: Colors.deepOrange,
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              GameSprite(
                                animalId: _selected[i].animalId,
                                spritePath: GameData.animalById(
                                  _selected[i].animalId,
                                )?.spritePath,
                                fallbackEmoji: '',
                                size: 60,
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  tooltip: 'Remove pet',
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: _busy
                                      ? null
                                      : () => setState(
                                          () => _selected.removeAt(i),
                                        ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            Text(
              '${_selected.length}/4 pets  |  ${power ?? 0} fusion income',
              style: TextStyle(color: widget.theme.cardTextPrimaryColor),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < HalloweenFusionLogic.animalIds.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: GameSprite(
                  animalId: HalloweenFusionLogic.animalIds[i],
                  spritePath: GameData.animalById(
                    HalloweenFusionLogic.animalIds[i],
                  )!.spritePath,
                  fallbackEmoji: '',
                  size: 48,
                ),
                title: Text(
                  GameData.animalById(HalloweenFusionLogic.animalIds[i])!.name,
                ),
                subtitle: Text(
                  '${GameData.animalById(HalloweenFusionLogic.animalIds[i])!.coinsPerSecond} coins/sec',
                ),
                trailing: Text(
                  odds == null
                      ? '--'
                      : '${(odds[i] * 100).toStringAsFixed(1)}%',
                ),
              ),
            FilledButton.icon(
              onPressed: power == null || _busy ? null : _fuse,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.deepOrange.shade800,
              ),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Fuse 4 pets'),
            ),
            const SizedBox(height: 12),
            if (candidates.isEmpty) const Text('No available pets'),
            for (final stack in candidates)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: GameSprite(
                  animalId: stack.animalId,
                  spritePath: GameData.animalById(stack.animalId)?.spritePath,
                  fallbackEmoji: '',
                  size: 40,
                ),
                title: Text(
                  '${GameData.mutationById(stack.mutationId)?.prefix ?? ''} ${GameData.animalById(stack.animalId)?.name ?? stack.animalId}'
                      .trim(),
                ),
                subtitle: Text(
                  'Level ${stack.level} | ${stack.quantity - _selected.where((s) => _same(s, stack)).length} available',
                ),
                trailing: IconButton(
                  tooltip: 'Add pet',
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed:
                      _busy ||
                          _selected.length >= 4 ||
                          _selected.where((s) => _same(s, stack)).length >=
                              stack.quantity
                      ? null
                      : () => setState(() => _selected.add(stack)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
