import 'dart:math';

/// Rebirth unlock requirement and income multiplier helpers.
class RebirthLogic {
  RebirthLogic._();

  static const int baseRequirement = 1000000;
  static const double multiplierGrowth = 2;

  /// Lifetime coins required to rebirth from [rebirthLevel] to the next level.
  static int rebirthRequirementForLevel(int rebirthLevel) {
    final level = rebirthLevel < 0 ? 0 : rebirthLevel;
    final nextLevel = level + 1;
    return baseRequirement * nextLevel * nextLevel;
  }

  /// Alias for the next rebirth threshold at the current level.
  static int nextRebirthRequirement(int rebirthLevel) =>
      rebirthRequirementForLevel(rebirthLevel);

  static bool canRebirth({
    required int lifetimeCoinsEarned,
    required int rebirthLevel,
  }) => lifetimeCoinsEarned >= nextRebirthRequirement(rebirthLevel);

  /// Income doubles with every rebirth: 1x, 2x, 4x, 8x, and so on.
  static double incomeMultiplier(int rebirthLevel) {
    final level = rebirthLevel < 0 ? 0 : rebirthLevel;
    return pow(multiplierGrowth, level).toDouble();
  }

  static double nextIncomeMultiplier(int rebirthLevel) =>
      incomeMultiplier(rebirthLevel + 1);

  static String formatMultiplier(double multiplier) {
    final text = multiplier.toStringAsFixed(2);
    return '${text.replaceAll(RegExp(r'\.?0+$'), '')}x';
  }

  static int applyMultiplier(int baseIncome, int rebirthLevel) {
    if (baseIncome <= 0 || rebirthLevel <= 0) return baseIncome;
    return (baseIncome * incomeMultiplier(rebirthLevel)).round();
  }
}
