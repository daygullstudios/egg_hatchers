import 'dart:math';

import '../models/arena.dart';

enum ArenaBotStyle { balanced, aggressive, defensive, saver }

class ArenaCombatLogic {
  ArenaCombatLogic._();

  static const maxEnergy = 10;
  static const circleLifetime = Duration(milliseconds: 1000);
  static const minCircleDelay = Duration(milliseconds: 420);
  static const maxCircleDelay = Duration(milliseconds: 780);
  static const switchEnergyCost = 1;

  static Duration nextCircleDelay(Random random) {
    final spread =
        maxCircleDelay.inMilliseconds - minCircleDelay.inMilliseconds;
    return Duration(
      milliseconds: minCircleDelay.inMilliseconds + random.nextInt(spread + 1),
    );
  }

  static int attackDamage({
    required ArenaFighter attacker,
    required ArenaFighter defender,
    required ArenaAbility ability,
    required Random random,
  }) {
    final variance = 0.92 + random.nextDouble() * 0.16;
    final matchup = (attacker.power / max(1, defender.power)).clamp(0.7, 1.4);
    return max(
      1,
      (attacker.attack * ability.damageScale * sqrt(matchup) * variance)
          .round(),
    );
  }

  static int supportAmount(ArenaFighter fighter, ArenaAbility ability) =>
      max(1, (fighter.attack * ability.effectScale).round());

  static ArenaAbility? chooseBotAbility({
    required List<ArenaAbility> abilities,
    required int energy,
    required double healthFraction,
    required Random random,
    ArenaBotStyle style = ArenaBotStyle.balanced,
  }) {
    final affordable = abilities
        .where((ability) => ability.energyCost <= energy)
        .toList();
    if (affordable.isEmpty) return null;

    if (healthFraction < 0.4) {
      final recovery = affordable
          .where(
            (ability) =>
                ability.effect == ArenaAbilityEffect.heal ||
                ability.effect == ArenaAbilityEffect.shield,
          )
          .toList();
      final recoveryChance = style == ArenaBotStyle.defensive ? 0.9 : 0.72;
      if (recovery.isNotEmpty && random.nextDouble() < recoveryChance) {
        return recovery.last;
      }
    }

    final signatureChance = switch (style) {
      ArenaBotStyle.saver => 0.92,
      ArenaBotStyle.aggressive => 0.5,
      ArenaBotStyle.defensive => 0.66,
      ArenaBotStyle.balanced => 0.7,
    };
    if (affordable.length == abilities.length &&
        random.nextDouble() < signatureChance) {
      return affordable.last;
    }
    if (style == ArenaBotStyle.aggressive && random.nextDouble() < 0.55) {
      return affordable.first;
    }
    if (affordable.length >= 2 && random.nextDouble() < 0.58) {
      return affordable[affordable.length - 1];
    }
    return affordable[random.nextInt(affordable.length)];
  }

  static Duration botEnergyInterval(int rating) {
    final milliseconds = 1180 - ((rating - 700) * 0.22).round();
    return Duration(milliseconds: milliseconds.clamp(720, 1180));
  }

  static ArenaBotStyle botStyleForTitle(String title) => switch (title) {
    'Nest Defender' || 'Shell Strategist' => ArenaBotStyle.defensive,
    'Mutation Hunter' || 'Hatchery Hero' => ArenaBotStyle.aggressive,
    'Egg Tactician' => ArenaBotStyle.saver,
    _ => ArenaBotStyle.balanced,
  };

  static bool botShouldSpend({
    required int energy,
    required ArenaBotStyle style,
    required Random random,
  }) {
    if (energy < 2) return false;
    if (energy >= maxEnergy) return true;
    final saveChance = switch (style) {
      ArenaBotStyle.saver => energy < 7 ? 0.82 : 0.12,
      ArenaBotStyle.defensive => energy < 4 ? 0.68 : 0.26,
      ArenaBotStyle.aggressive => energy < 4 ? 0.22 : 0.08,
      ArenaBotStyle.balanced => energy < 4 ? 0.58 : 0.25,
    };
    return random.nextDouble() >= saveChance;
  }

  static String skillGrade({
    required bool won,
    required int hits,
    required int misses,
    required int bestCombo,
    required int remainingHealth,
    required int maxHealth,
  }) {
    final attempts = hits + misses;
    final accuracy = attempts == 0 ? 0.0 : hits / attempts;
    final healthFraction = maxHealth <= 0
        ? 0.0
        : (remainingHealth / maxHealth).clamp(0.0, 1.0);
    var score = accuracy * 50 + min(20, bestCombo * 2) + healthFraction * 20;
    if (won) score += 10;
    if (score >= 85) return 'S';
    if (score >= 70) return 'A';
    if (score >= 55) return 'B';
    if (score >= 40) return 'C';
    return 'D';
  }
}
