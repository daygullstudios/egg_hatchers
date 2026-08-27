import 'multiplayer.dart';
import 'owned_animal.dart';
import 'player_account.dart';

enum OnlineInviteKind {
  battle,
  trade;

  String get wireName => name;

  static OnlineInviteKind fromWire(String value) =>
      value == 'trade' ? OnlineInviteKind.trade : OnlineInviteKind.battle;
}

class OnlinePresenceSnapshot {
  const OnlinePresenceSnapshot({
    required this.account,
    required this.rating,
    required this.team,
    required this.animals,
  });

  final PlayerAccount account;
  final int rating;
  final List<MultiplayerFighterSnapshot> team;
  final List<OwnedAnimal> animals;

  Map<String, dynamic> toJson() => {
    'account': account.toJson(),
    'rating': rating,
    'team': team.map((item) => item.toJson()).toList(growable: false),
    'animals': animals.map((item) => item.toJson()).toList(growable: false),
  };
}

class OnlinePlayerPresence {
  const OnlinePlayerPresence({
    required this.account,
    required this.rating,
    required this.team,
    required this.animals,
  });

  final PlayerAccount account;
  final int rating;
  final List<MultiplayerFighterSnapshot> team;
  final List<OwnedAnimal> animals;

  bool get canBattle => team.length == 3;
  bool get canTrade => animals.any(
    (animal) =>
        animal.quantity > 0 &&
        !animal.isProtected &&
        !animal.isSecretReward &&
        !animal.isEliteReward,
  );

  factory OnlinePlayerPresence.fromJson(Map<String, dynamic> json) {
    return OnlinePlayerPresence(
      account: PlayerAccount.fromJson(
        Map<String, dynamic>.from(json['account'] as Map),
      ),
      rating: (json['rating'] as num?)?.toInt() ?? 1000,
      team: (json['team'] as List<dynamic>? ?? const [])
          .map(
            (item) => MultiplayerFighterSnapshot.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
      animals: (json['animals'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                OwnedAnimal.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false),
    );
  }
}

class OnlineInvite {
  const OnlineInvite({
    required this.id,
    required this.kind,
    required this.from,
  });

  final String id;
  final OnlineInviteKind kind;
  final PlayerAccount from;

  factory OnlineInvite.fromJson(Map<String, dynamic> json) => OnlineInvite(
    id: json['inviteId'] as String,
    kind: OnlineInviteKind.fromWire(json['kind'] as String? ?? 'battle'),
    from: PlayerAccount.fromJson(
      Map<String, dynamic>.from(json['from'] as Map),
    ),
  );
}

class OnlineSessionLaunch {
  const OnlineSessionLaunch({
    required this.roomId,
    required this.kind,
    required this.opponent,
  });

  final String roomId;
  final OnlineInviteKind kind;
  final PlayerAccount opponent;

  factory OnlineSessionLaunch.fromJson(Map<String, dynamic> json) =>
      OnlineSessionLaunch(
        roomId: json['roomId'] as String,
        kind: OnlineInviteKind.fromWire(json['kind'] as String? ?? 'battle'),
        opponent: PlayerAccount.fromJson(
          Map<String, dynamic>.from(json['opponent'] as Map),
        ),
      );
}

class OnlinePresetMessage {
  const OnlinePresetMessage({required this.from, required this.tag});

  final PlayerAccount from;
  final String tag;

  factory OnlinePresetMessage.fromJson(Map<String, dynamic> json) =>
      OnlinePresetMessage(
        from: PlayerAccount.fromJson(
          Map<String, dynamic>.from(json['from'] as Map),
        ),
        tag: json['tag'] as String,
      );
}

const Map<String, String> onlineMessageTags = {
  'hello': 'Hello!',
  'good_luck': 'Good luck!',
  'nice_team': 'Nice team!',
  'good_game': 'Good game!',
};
