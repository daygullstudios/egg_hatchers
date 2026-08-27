import 'owned_animal.dart';
import 'player_account.dart';

class OnlineTraderSnapshot {
  const OnlineTraderSnapshot({required this.account, required this.inventory});

  final PlayerAccount account;
  final List<OwnedAnimal> inventory;

  Map<String, dynamic> toJson() => {
    'player': account.toJson(),
    'inventory': inventory.map((animal) => animal.toJson()).toList(),
  };
}

class OnlineTradeState {
  const OnlineTradeState({
    required this.opponent,
    required this.selfOffer,
    required this.opponentOffer,
    required this.selfConfirmed,
    required this.opponentConfirmed,
    required this.message,
    required this.opponentInventory,
  });

  final PlayerAccount opponent;
  final OwnedAnimal? selfOffer;
  final OwnedAnimal? opponentOffer;
  final bool selfConfirmed;
  final bool opponentConfirmed;
  final String message;
  final List<OwnedAnimal> opponentInventory;

  factory OnlineTradeState.fromJson(Map<String, dynamic> json) {
    OwnedAnimal? animalFrom(dynamic value) => value is Map
        ? OwnedAnimal.fromJson(Map<String, dynamic>.from(value))
        : null;
    return OnlineTradeState(
      opponent: PlayerAccount.fromJson(
        Map<String, dynamic>.from(json['opponent'] as Map),
      ),
      selfOffer: animalFrom(json['selfOffer']),
      opponentOffer: animalFrom(json['opponentOffer']),
      selfConfirmed: json['selfConfirmed'] as bool? ?? false,
      opponentConfirmed: json['opponentConfirmed'] as bool? ?? false,
      message: json['message'] as String? ?? 'Choose an animal to offer.',
      opponentInventory:
          (json['opponentInventory'] as List<dynamic>? ?? const [])
              .map(
                (item) => OwnedAnimal.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(growable: false),
    );
  }
}

enum TradeChatTag {
  yes('yes'),
  no('no'),
  isThisFair('is_this_fair'),
  requestAnimal('request_animal');

  const TradeChatTag(this.wireName);
  final String wireName;

  static TradeChatTag fromWire(String value) => values.firstWhere(
    (tag) => tag.wireName == value,
    orElse: () => TradeChatTag.no,
  );
}

class TradeChatMessage {
  const TradeChatMessage({
    required this.id,
    required this.tag,
    required this.fromSelf,
    this.animal,
  });

  final String id;
  final TradeChatTag tag;
  final bool fromSelf;
  final OwnedAnimal? animal;

  factory TradeChatMessage.fromJson(Map<String, dynamic> json) =>
      TradeChatMessage(
        id: json['chatId'] as String,
        tag: TradeChatTag.fromWire(json['tag'] as String),
        fromSelf: json['fromSelf'] as bool? ?? false,
        animal: json['animal'] is Map
            ? OwnedAnimal.fromJson(
                Map<String, dynamic>.from(json['animal'] as Map),
              )
            : null,
      );
}

class OnlineTradeCompletion {
  const OnlineTradeCompletion({required this.sent, required this.received});

  final OwnedAnimal sent;
  final OwnedAnimal received;

  factory OnlineTradeCompletion.fromJson(Map<String, dynamic> json) {
    return OnlineTradeCompletion(
      sent: OwnedAnimal.fromJson(
        Map<String, dynamic>.from(json['sent'] as Map),
      ),
      received: OwnedAnimal.fromJson(
        Map<String, dynamic>.from(json['received'] as Map),
      ),
    );
  }
}
