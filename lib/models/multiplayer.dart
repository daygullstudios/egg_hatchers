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
    required this.rating,
    required this.team,
  });

  final String playerId;
  final String displayName;
  final String username;
  final int avatarColorValue;
  final int rating;
  final List<MultiplayerFighterSnapshot> team;

  factory MultiplayerPlayerSnapshot.fromPlayer({
    required PlayerAccount account,
    required List<ArenaFighter> team,
    required int rating,
  }) {
    return MultiplayerPlayerSnapshot(
      playerId: account.id,
      displayName: account.displayName,
      username: account.username,
      avatarColorValue: account.avatarColorValue,
      rating: rating,
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
    'rating': rating,
    'team': team.map((fighter) => fighter.toJson()).toList(growable: false),
  };

  factory MultiplayerPlayerSnapshot.fromJson(Map<String, dynamic> json) {
    return MultiplayerPlayerSnapshot(
      playerId: json['playerId'] as String,
      displayName: json['displayName'] as String,
      username: json['username'] as String,
      avatarColorValue: json['avatarColorValue'] as int,
      rating: (json['rating'] as num?)?.toInt() ?? 1000,
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

class MultiplayerCombatantState {
  const MultiplayerCombatantState({
    required this.health,
    required this.activeIndex,
    required this.energy,
    required this.shield,
    required this.energyHits,
    required this.energyMisses,
  });

  final List<int> health;
  final int activeIndex;
  final int energy;
  final int shield;
  final int energyHits;
  final int energyMisses;

  factory MultiplayerCombatantState.fromJson(Map<String, dynamic> json) {
    return MultiplayerCombatantState(
      health: (json['health'] as List<dynamic>)
          .map((value) => (value as num).toInt())
          .toList(growable: false),
      activeIndex: (json['activeIndex'] as num).toInt(),
      energy: (json['energy'] as num).toInt(),
      shield: (json['shield'] as num).toInt(),
      energyHits: (json['energyHits'] as num?)?.toInt() ?? 0,
      energyMisses: (json['energyMisses'] as num?)?.toInt() ?? 0,
    );
  }
}

class MultiplayerBattleState {
  const MultiplayerBattleState({
    required this.self,
    required this.opponent,
    required this.message,
    required this.revision,
    this.lastActorId,
    this.winnerId,
  });

  final MultiplayerCombatantState self;
  final MultiplayerCombatantState opponent;
  final String message;
  final int revision;
  final String? lastActorId;
  final String? winnerId;

  bool get finished => winnerId != null;

  factory MultiplayerBattleState.fromJson(Map<String, dynamic> json) {
    return MultiplayerBattleState(
      self: MultiplayerCombatantState.fromJson(
        Map<String, dynamic>.from(json['self'] as Map),
      ),
      opponent: MultiplayerCombatantState.fromJson(
        Map<String, dynamic>.from(json['opponent'] as Map),
      ),
      message: json['message'] as String? ?? 'Battle ready',
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      lastActorId: json['lastActorId'] as String?,
      winnerId: json['winnerId'] as String?,
    );
  }
}

class MultiplayerEnergySpawn {
  const MultiplayerEnergySpawn({
    required this.id,
    required this.x,
    required this.y,
    required this.golden,
  });

  final int id;
  final double x;
  final double y;
  final bool golden;

  factory MultiplayerEnergySpawn.fromJson(Map<String, dynamic> json) {
    return MultiplayerEnergySpawn(
      id: (json['id'] as num).toInt(),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      golden: json['golden'] as bool? ?? false,
    );
  }
}
