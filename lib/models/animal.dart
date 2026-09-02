/// Rarity tiers for animals, from most to least common.
enum Rarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic,
  unknown,
  boss;

  /// Stable id string (used for display keys).
  String get id {
    switch (this) {
      case Rarity.unknown:
        return '???';
      case Rarity.boss:
        return 'boss';
      default:
        return name;
    }
  }

  String get label {
    switch (this) {
      case Rarity.common:
        return 'Common';
      case Rarity.uncommon:
        return 'Uncommon';
      case Rarity.rare:
        return 'Rare';
      case Rarity.epic:
        return 'Epic';
      case Rarity.legendary:
        return 'Legendary';
      case Rarity.mythic:
        return 'Mythic';
      case Rarity.unknown:
        return '???';
      case Rarity.boss:
        return 'Boss';
    }
  }

  /// Higher sort values appear first in collection lists.
  int get sortOrder {
    switch (this) {
      case Rarity.boss:
        return 8;
      case Rarity.unknown:
        return 7;
      case Rarity.mythic:
        return 6;
      case Rarity.legendary:
        return 5;
      case Rarity.epic:
        return 4;
      case Rarity.rare:
        return 3;
      case Rarity.uncommon:
        return 2;
      case Rarity.common:
        return 1;
    }
  }
}

/// A hatchable creature that generates coins over time.
class Animal {
  const Animal({
    required this.id,
    required this.name,
    required this.rarity,
    required this.coinsPerSecond,
    required this.emoji,
    this.spritePath,
  });

  final String id;
  final String name;
  final Rarity rarity;
  final int coinsPerSecond;
  final String emoji;

  /// Optional sprite asset path. Emoji is used when null or if load fails.
  final String? spritePath;
}
