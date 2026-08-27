import 'package:egg_hatchers/models/arena.dart';
import 'package:egg_hatchers/models/multiplayer.dart';
import 'package:egg_hatchers/models/player_account.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('multiplayer player snapshot survives JSON serialization', () {
    final account = PlayerAccount(
      id: 'player_1',
      displayName: 'Egg Hero',
      username: 'egg_hero',
      avatarColorValue: 0xFF5271FF,
      createdAt: DateTime.utc(2026, 8, 27),
    );
    final snapshot = MultiplayerPlayerSnapshot.fromPlayer(
      account: account,
      rating: 1234,
      team: const [
        ArenaFighter(
          animalId: 'chicken',
          mutationId: 'golden',
          level: 12,
          power: 420,
        ),
      ],
    );

    final restored = MultiplayerPlayerSnapshot.fromJson(snapshot.toJson());

    expect(restored.playerId, 'player_1');
    expect(restored.username, 'egg_hero');
    expect(restored.rating, 1234);
    expect(restored.team, hasLength(1));
    expect(restored.team.single.animalId, 'chicken');
    expect(restored.team.single.power, 420);
  });
}
