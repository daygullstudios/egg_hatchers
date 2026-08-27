import 'arena.dart';
import 'player_account.dart';

class MultiplayerFighterSnapshot {
  const MultiplayerFighterSnapshot({
    required this.animalId,
    required this.mutationId,
    required this.level,
    required this.power,
  });

  final String animalId;
  final String mutationId;
  final int level;
  final int power;

  factory MultiplayerFighterSnapshot.fromArenaFighter(ArenaFighter fighter) {
    return MultiplayerFighterSnapshot(
      animalId: fighter.animalId,
      mutationId: fighter.mutationId,
      level: fighter.level,
      power: fighter.power,
    );
  }

  Map<String, dynamic> toJson() => {
    'animalId': animalId,
    'mutationId': mutationId,
    'level': level,
    'power': power,
  };

  factory MultiplayerFighterSnapshot.fromJson(Map<String, dynamic> json) {
    return MultiplayerFighterSnapshot(
      animalId: json['animalId'] as String,
      mutationId: json['mutationId'] as String,
      level: json['level'] as int,
      power: json['power'] as int,
    );
  }
}

class MultiplayerPlayerSnapshot {
  const MultiplayerPlayerSnapshot({
    required this.playerId,
    required this.displayName,
    required this.username,
    required this.avatarColorValue,
    required this.team,
  });

  final String playerId;
  final String displayName;
  final String username;
  final int avatarColorValue;
  final List<MultiplayerFighterSnapshot> team;

  factory MultiplayerPlayerSnapshot.fromPlayer({
    required PlayerAccount account,
    required List<ArenaFighter> team,
  }) {
    return MultiplayerPlayerSnapshot(
      playerId: account.id,
      displayName: account.displayName,
      username: account.username,
      avatarColorValue: account.avatarColorValue,
      team: team
          .map(MultiplayerFighterSnapshot.fromArenaFighter)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'displayName': displayName,
    'username': username,
    'avatarColorValue': avatarColorValue,
    'team': team.map((fighter) => fighter.toJson()).toList(growable: false),
  };

  factory MultiplayerPlayerSnapshot.fromJson(Map<String, dynamic> json) {
    return MultiplayerPlayerSnapshot(
      playerId: json['playerId'] as String,
      displayName: json['displayName'] as String,
      username: json['username'] as String,
      avatarColorValue: json['avatarColorValue'] as int,
      team: (json['team'] as List<dynamic>)
          .map(
            (item) => MultiplayerFighterSnapshot.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}
