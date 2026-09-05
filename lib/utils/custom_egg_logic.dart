import 'dart:math';

import '../data/game_data.dart';
import '../models/custom_egg.dart';
import '../models/egg.dart';

/// Pricing, weighting, and hatch helpers for player-created custom eggs.
class CustomEggLogic {
  CustomEggLogic._();

  static const double flexibilityMultiplier = 1.25;
  static const int minWeight = 1;
  static const int maxWeight = 100;
  static const int maxSelectedAnimals = 6;

  /// Cheapest built-in egg that can hatch [animalId].
  static Egg? findSourceEggForAnimal(String animalId) {
    Egg? cheapest;
    for (final egg in GameData.eggs) {
      if (!egg.possibleAnimalIds.contains(animalId)) continue;
      if (cheapest == null || egg.cost < cheapest.cost) {
        cheapest = egg;
      }
    }
    return cheapest;
  }

  /// Alias for clarity in unlock helpers.
  static Egg? sourceEggForAnimal(String animalId) =>
      findSourceEggForAnimal(animalId);

  /// Animal income required to use [animalId] in a custom egg.
  static int lifetimeRequiredForAnimal(String animalId) {
    final source = findSourceEggForAnimal(animalId);
    return source?.unlockLifetimeCoins ?? 0;
  }

  static bool isAnimalUnlockedForCustomEgg(
    String animalId,
    int lifetimeCoinsEarned, {
    int rebirthLevel = 0,
  }) {
    if (GameData.animalById(animalId) == null) return false;
    final source = findSourceEggForAnimal(animalId);
    if (source == null) return false;
    if (source.id == GameData.dayGullEggId) return false;
    return source.isUnlocked(
      lifetimeCoinsEarned: lifetimeCoinsEarned,
      rebirthLevel: rebirthLevel,
    );
  }

  static bool canAddAnimalToCustomEgg(
    String animalId,
    int lifetimeCoinsEarned, {
    required int selectedCount,
    int rebirthLevel = 0,
  }) {
    if (!isAnimalUnlockedForCustomEgg(
      animalId,
      lifetimeCoinsEarned,
      rebirthLevel: rebirthLevel,
    )) {
      return false;
    }
    return selectedCount < maxSelectedAnimals;
  }

  static String unlockMessageForAnimal(
    String animalId, {
    int rebirthLevel = 0,
  }) {
    final source = findSourceEggForAnimal(animalId);
    if (source == null) return 'This animal is unavailable.';
    if (source.id == GameData.dayGullEggId) {
      return 'Unlocks from the DayGull Egg after beating The Rotten Shell.';
    }
    if (source.unlockRebirthLevel > 0 &&
        rebirthLevel < source.unlockRebirthLevel) {
      return 'Requires Rebirth Level ${source.unlockRebirthLevel}';
    }
    if (source.unlockLifetimeCoins <= 0) return 'Always available.';
    return 'Unlock ${source.name} by earning '
        '${source.unlockLifetimeCoins} animal income.';
  }

  /// Valid animals that are also unlocked for the player's progression.
  static List<String> hatchableAnimalIds(
    CustomEgg egg,
    int lifetimeCoinsEarned, {
    int rebirthLevel = 0,
  }) {
    return egg.validAnimalIds
        .where(
          (id) => isAnimalUnlockedForCustomEgg(
            id,
            lifetimeCoinsEarned,
            rebirthLevel: rebirthLevel,
          ),
        )
        .toList();
  }

  /// Normalized weights for active animals (1–100, default 1).
  static Map<String, int> effectiveWeights(
    CustomEgg egg, {
    int lifetimeCoinsEarned = 0,
    int rebirthLevel = 0,
  }) {
    final ids = hatchableAnimalIds(
      egg,
      lifetimeCoinsEarned,
      rebirthLevel: rebirthLevel,
    );
    final weights = <String, int>{};
    for (final id in ids) {
      final raw = egg.animalWeights[id] ?? 1;
      weights[id] = raw.clamp(minWeight, maxWeight);
    }
    return weights;
  }

  static int totalWeight(
    CustomEgg egg, {
    int lifetimeCoinsEarned = 0,
    int rebirthLevel = 0,
  }) {
    return effectiveWeights(
      egg,
      lifetimeCoinsEarned: lifetimeCoinsEarned,
      rebirthLevel: rebirthLevel,
    ).values.fold(0, (sum, w) => sum + w);
  }

  /// Hatch chance as 0–100 percent.
  static double chancePercentForAnimal(
    CustomEgg egg,
    String animalId, {
    int lifetimeCoinsEarned = 0,
    int rebirthLevel = 0,
  }) {
    final weights = effectiveWeights(
      egg,
      lifetimeCoinsEarned: lifetimeCoinsEarned,
      rebirthLevel: rebirthLevel,
    );
    if (!weights.containsKey(animalId)) return 0;
    final total = totalWeight(
      egg,
      lifetimeCoinsEarned: lifetimeCoinsEarned,
      rebirthLevel: rebirthLevel,
    );
    if (total <= 0) return 0;
    return weights[animalId]! / total * 100;
  }

  static int minimumCostForCustomEgg(
    CustomEgg egg, {
    int lifetimeCoinsEarned = 0,
    int rebirthLevel = 0,
  }) {
    final ids = hatchableAnimalIds(
      egg,
      lifetimeCoinsEarned,
      rebirthLevel: rebirthLevel,
    );
    if (ids.isEmpty) return 1;

    var sum = 0.0;
    final weights = effectiveWeights(
      egg,
      lifetimeCoinsEarned: lifetimeCoinsEarned,
      rebirthLevel: rebirthLevel,
    );
    final total = totalWeight(
      egg,
      lifetimeCoinsEarned: lifetimeCoinsEarned,
      rebirthLevel: rebirthLevel,
    );
    if (total <= 0) return 1;

    for (final animalId in ids) {
      final sourceEgg = findSourceEggForAnimal(animalId);
      if (sourceEgg == null) continue;

      final baseContribution =
          sourceEgg.cost / sourceEgg.possibleAnimalIds.length;
      final chance = weights[animalId]! / total;
      sum += baseContribution * chance;
    }

    return roundCleanCost(sum * flexibilityMultiplier);
  }

  /// Rounds up to a clean coin value by tier.
  static int roundCleanCost(double value) {
    final v = value.ceil();
    if (v < 1000) return ((v + 9) ~/ 10) * 10;
    if (v < 100000) return ((v + 99) ~/ 100) * 100;
    return ((v + 999) ~/ 1000) * 1000;
  }

  /// Picks an animal id using weighted random selection.
  static String weightedRandomAnimal(
    CustomEgg egg,
    Random random, {
    int lifetimeCoinsEarned = 0,
    int rebirthLevel = 0,
  }) {
    final weights = effectiveWeights(
      egg,
      lifetimeCoinsEarned: lifetimeCoinsEarned,
      rebirthLevel: rebirthLevel,
    );
    final ids = weights.keys.toList();
    if (ids.isEmpty) {
      throw StateError('Custom egg has no hatchable animals');
    }
    if (ids.length == 1) return ids.first;

    final total = weights.values.fold(0, (sum, w) => sum + w);
    var roll = random.nextInt(total);
    for (final id in ids) {
      roll -= weights[id]!;
      if (roll < 0) return id;
    }
    return ids.last;
  }

  /// Short summary for shop cards, e.g. "Chicken 60% · Rabbit 30%".
  static String formatChanceSummary(
    CustomEgg egg, {
    int maxEntries = 3,
    int lifetimeCoinsEarned = 0,
    int rebirthLevel = 0,
  }) {
    var ids = List<String>.from(
      hatchableAnimalIds(egg, lifetimeCoinsEarned, rebirthLevel: rebirthLevel),
    );
    if (ids.isEmpty) {
      ids = List<String>.from(egg.validAnimalIds);
    }
    ids.sort(
      (a, b) =>
          chancePercentForAnimal(
            egg,
            b,
            lifetimeCoinsEarned: lifetimeCoinsEarned,
            rebirthLevel: rebirthLevel,
          ).compareTo(
            chancePercentForAnimal(
              egg,
              a,
              lifetimeCoinsEarned: lifetimeCoinsEarned,
              rebirthLevel: rebirthLevel,
            ),
          ),
    );

    final parts = <String>[];
    for (final id in ids.take(maxEntries)) {
      final animal = GameData.animalById(id);
      if (animal == null) continue;
      final pct = chancePercentForAnimal(
        egg,
        id,
        lifetimeCoinsEarned: lifetimeCoinsEarned,
        rebirthLevel: rebirthLevel,
      ).round();
      parts.add('${animal.name} $pct%');
    }

    if (ids.length > maxEntries) {
      parts.add('…');
    }
    return parts.join(' · ');
  }

  static bool isCustomEggId(String id) => id.startsWith(CustomEgg.idPrefix);
}
