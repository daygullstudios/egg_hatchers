import 'dart:math';

/// Event dates are UTC; earned pets remain ordinary saved inventory afterward.
abstract final class HalloweenFusionLogic {
  static const inputCount = 4;
  static const animalIds = [
    'pumpkin_prowler',
    'lantern_wraith',
    'count_nocturne',
  ];
  static final startsAt = DateTime.utc(2026, 10, 24);
  static final endsAt = DateTime.utc(2026, 11, 3);

  static bool isActive(DateTime now) =>
      !now.toUtc().isBefore(startsAt) && now.toUtc().isBefore(endsAt);

  // Thresholds prevent cheap inputs from rolling late-game income rewards.
  // Rebirth and temporary global bonuses do not increase machine power.
  static List<double> probabilities(int income) {
    final mid = income < 4000
        ? 0.0
        : (0.05 + log(income / 4000) / log(100) * .85).clamp(.05, .90);
    final high = income < 400000
        ? 0.0
        : (0.05 + log(income / 400000) / log(100) * .70).clamp(.05, .75);
    return [(1 - high) * (1 - mid), (1 - high) * mid, high];
  }

  static String roll(int income, Random random) {
    final weights = probabilities(income);
    var roll = random.nextDouble();
    for (var i = 0; i < weights.length - 1; i++) {
      if (roll < weights[i]) return animalIds[i];
      roll -= weights[i];
    }
    return animalIds.last;
  }
}
