class ArenaFighter {
  const ArenaFighter({
    required this.animalId,
    required this.mutationId,
    required this.level,
    required this.power,
  });

  final String animalId;
  final String mutationId;
  final int level;
  final int power;

  int get maxHealth => 180 + (power + 1).bitLength * 24 + level.clamp(1, 200);
  int get attack => 24 + (power + 1).bitLength * 9 + (level ~/ 8).clamp(0, 35);
}

class ArenaOpponent {
  const ArenaOpponent({
    required this.name,
    required this.title,
    required this.rating,
    required this.team,
    required this.seed,
  });

  final String name;
  final String title;
  final int rating;
  final List<ArenaFighter> team;
  final int seed;

  int get totalPower => team.fold(0, (sum, fighter) => sum + fighter.power);
}

class ArenaBattleStep {
  const ArenaBattleStep({
    required this.playerAttacks,
    required this.attackerIndex,
    required this.targetIndex,
    required this.damage,
    required this.targetHealthAfter,
    required this.targetDefeated,
  });

  final bool playerAttacks;
  final int attackerIndex;
  final int targetIndex;
  final int damage;
  final int targetHealthAfter;
  final bool targetDefeated;
}

class ArenaBattleSimulation {
  const ArenaBattleSimulation({
    required this.playerTeam,
    required this.opponent,
    required this.steps,
    required this.playerWon,
  });

  final List<ArenaFighter> playerTeam;
  final ArenaOpponent opponent;
  final List<ArenaBattleStep> steps;
  final bool playerWon;
}

class ArenaReward {
  const ArenaReward({
    required this.ratingChange,
    required this.coins,
    required this.battleTokens,
  });

  final int ratingChange;
  final int coins;
  final int battleTokens;
}

enum ArenaAbilityEffect { damage, shield, heal, drain }

class ArenaAbility {
  const ArenaAbility({
    required this.name,
    required this.energyCost,
    required this.damageScale,
    this.effect = ArenaAbilityEffect.damage,
    this.effectScale = 0,
  });

  final String name;
  final int energyCost;
  final double damageScale;
  final ArenaAbilityEffect effect;
  final double effectScale;
}

class ArenaAbilityLoadout {
  const ArenaAbilityLoadout({
    required this.quickName,
    required this.techniqueName,
    required this.signatureName,
    this.techniqueEffect = ArenaAbilityEffect.damage,
    this.signatureEffect = ArenaAbilityEffect.damage,
  });

  final String quickName;
  final String techniqueName;
  final String signatureName;
  final ArenaAbilityEffect techniqueEffect;
  final ArenaAbilityEffect signatureEffect;
}
