import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../models/online_lobby.dart';
import '../services/custom_sprite_service.dart';
import '../services/online_lobby_service.dart';
import 'game_sprite.dart';

class OnlinePlayerList extends StatelessWidget {
  const OnlinePlayerList({
    super.key,
    required this.players,
    required this.activity,
    required this.lobby,
    required this.customSprites,
  });

  final List<OnlinePlayerPresence> players;
  final OnlineInviteKind activity;
  final OnlineLobbyService lobby;
  final CustomSpriteService customSprites;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Players Online',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              '${players.length}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (players.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'No other players are online yet.',
              textAlign: TextAlign.center,
            ),
          )
        else
          for (final player in players)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _OnlinePlayerTile(
                player: player,
                activity: activity,
                lobby: lobby,
                customSprites: customSprites,
              ),
            ),
      ],
    );
  }
}

class _OnlinePlayerTile extends StatelessWidget {
  const _OnlinePlayerTile({
    required this.player,
    required this.activity,
    required this.lobby,
    required this.customSprites,
  });

  final OnlinePlayerPresence player;
  final OnlineInviteKind activity;
  final OnlineLobbyService lobby;
  final CustomSpriteService customSprites;

  @override
  Widget build(BuildContext context) {
    final eligible = activity == OnlineInviteKind.battle
        ? player.canBattle
        : player.canTrade;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: player.account.avatarColor,
                child: Text(
                  player.account.displayName.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.account.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '@${player.account.username} | ${player.rating} rating',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Send message',
                icon: const Icon(Icons.forum_outlined),
                onSelected: (tag) =>
                    lobby.sendPresetMessage(player.account.id, tag),
                itemBuilder: (_) => onlineMessageTags.entries
                    .map(
                      (entry) => PopupMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAnimals(context),
                  icon: const Icon(Icons.pets, size: 17),
                  label: const Text('VIEW ANIMALS'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  key: ValueKey(
                    '${activity.wireName}-invite-${player.account.id}',
                  ),
                  onPressed: eligible
                      ? () => lobby.invite(player.account.id, activity)
                      : null,
                  icon: Icon(
                    activity == OnlineInviteKind.battle
                        ? Icons.sports_martial_arts
                        : Icons.swap_horiz,
                    size: 17,
                  ),
                  label: Text(
                    activity == OnlineInviteKind.battle ? 'BATTLE' : 'TRADE',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAnimals(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${player.account.displayName}\'s Animals',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: player.animals.isEmpty
                    ? const Center(child: Text('No animals yet.'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                        itemCount: player.animals.length,
                        itemBuilder: (context, index) {
                          final owned = player.animals[index];
                          final animal = GameData.animalById(owned.animalId);
                          if (animal == null) return const SizedBox.shrink();
                          final mutation = GameData.mutationById(
                            owned.mutationId,
                          );
                          return ListTile(
                            leading: GameAnimalPortrait(
                              customSprite: customSprites.getDisplaySprite(
                                animal.id,
                              ),
                              animalId: animal.id,
                              spritePath: animal.spritePath,
                              fallbackEmoji: animal.emoji,
                              mutation: mutation,
                              size: 46,
                            ),
                            title: Text(
                              mutation?.fullName(animal) ?? animal.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text('Level ${owned.level}'),
                            trailing: Text('x${owned.quantity}'),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
