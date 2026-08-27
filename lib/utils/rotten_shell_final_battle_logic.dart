import 'dart:math';

import '../models/arena.dart';

class RottenShellFinalBattleLogic {
  RottenShellFinalBattleLogic._();

  static const rottenShellBossId = 'rotten_shell';

  static bool shouldEnter({
    required String bossId,
    required int livesRemaining,
    required int maxLives,
  }) => bossId == rottenShellBossId && maxLives > 1 && livesRemaining == 1;

  static int playerMaxHealth(ArenaFighter fighter) =>
      max(300, fighter.maxHealth);

  static int bossMaxHealth(ArenaFighter fighter) =>
      max(320, fighter.attack * 7);

  static int abilityDamage(ArenaFighter fighter, ArenaAbility ability) =>
      max(1, (fighter.attack * ability.damageScale * 1.12).round());

  static int bossAttackDamage(ArenaFighter fighter) =>
      max(18, (playerMaxHealth(fighter) * 0.085).round());

  static bool isFinalAttack({
    required ArenaFighter fighter,
    required ArenaAbility ability,
    required int bossHealth,
  }) => abilityDamage(fighter, ability) >= bossHealth;

  static int beamColorValue(String animalId, String mutationId) {
    switch (mutationId) {
      case 'golden':
        return 0xFFFFC928;
      case 'shadow':
        return 0xFF7C4DFF;
      case 'boss':
        return 0xFFFF3D71;
    }
    var hash = 0;
    for (final unit in animalId.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    const colors = <int>[
      0xFF36D9FF,
      0xFF8C6CFF,
      0xFFFF5FA2,
      0xFF45E59A,
      0xFFFFB84D,
      0xFF6F8CFF,
    ];
    return colors[hash % colors.length];
  }
}
