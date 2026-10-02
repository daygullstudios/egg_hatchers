import '../models/boss_battle.dart';
import 'elite_boss_sprite_paths.dart';

/// Tunable boss battle definitions.
class BossData {
  BossData._();

  static const standardBosses = <BossBattleDefinition>[
    BossBattleDefinition(
      id: 'slime_boss',
      name: 'Slime Boss',
      description: 'A wobbly starter boss.',
      emoji: '🟢',
      spritePath: 'assets/images/bosses/slime_boss.png',
      maxHp: 1000,
      recommendedPower: 100,
      coinReward: 500,
      battleTokenReward: 1,
      unlockRequirementText: 'Hatch at least one animal',
      autoBattleSeconds: 10,
      projectileIntervalMs: 1200,
      projectileSpeed: 120,
      manualBossMoveSpeed: 45,
      manualAimAccuracy: 0.35,
      manualPredictionStrength: 6,
      manualAimErrorMax: 100,
      manualAimRecalcMs: 450,
    ),
    BossBattleDefinition(
      id: 'egg_golem',
      name: 'Egg Golem',
      description: 'A cracked guardian of rare eggs.',
      emoji: '🪨🥚',
      spritePath: 'assets/images/bosses/egg_golem.png',
      maxHp: 15000,
      recommendedPower: 1500,
      coinReward: 15000,
      battleTokenReward: 3,
      unlockRequirementText: 'Collect 10 unique base animals',
      autoBattleSeconds: 20,
      projectileIntervalMs: 950,
      projectileSpeed: 180,
      manualBossMoveSpeed: 70,
      manualAimAccuracy: 0.65,
      manualPredictionStrength: 10,
      manualAimErrorMax: 55,
      manualAimRecalcMs: 350,
    ),
    BossBattleDefinition(
      id: 'shadow_rooster',
      name: 'Shadow Rooster',
      description: 'A dark champion from the secret coop.',
      emoji: '🌑🐓',
      spritePath: 'assets/images/bosses/shadow_rooster.png',
      maxHp: 150000,
      recommendedPower: 15000,
      coinReward: 100000,
      battleTokenReward: 8,
      unlockRequirementText:
          'Reach Rebirth Level 1 or collect 25 unique base animals',
      autoBattleSeconds: 35,
      projectileIntervalMs: 750,
      projectileSpeed: 260,
      manualBossMoveSpeed: 95,
      manualAimAccuracy: 0.9,
      manualPredictionStrength: 14,
      manualAimErrorMax: 25,
      manualAimRecalcMs: 275,
    ),
  ];

  static const eliteBosses = <BossBattleDefinition>[
    BossBattleDefinition(
      id: 'slime_king',
      name: 'Slime King',
      description: 'A crowned slime lord from the deepest pit.',
      emoji: '👑🟢',
      spritePath: EliteBossSpritePaths.slimeKing,
      maxHp: 50000,
      recommendedPower: 5000,
      coinReward: 500000,
      battleTokenReward: 10,
      unlockRequirementText: 'Defeat Slime Boss in Nightmare Mode 3 times',
      autoBattleSeconds: 40,
      projectileIntervalMs: 700,
      projectileSpeed: 280,
      manualBossMoveSpeed: 88,
      manualAimAccuracy: 0.72,
      manualPredictionStrength: 11,
      manualAimErrorMax: 42,
      manualAimRecalcMs: 300,
      isEliteBoss: true,
      manualBattleOnly: true,
      unlockNightmareWinsBossId: 'slime_boss',
      unlockNightmareWinsRequired: 3,
      rewardAnimalId: 'slime_king',
      eliteShieldBaseMisses: 9,
    ),
    BossBattleDefinition(
      id: 'egg_guardian',
      name: 'Egg Guardian',
      description: 'An ancient armored sentinel of the egg vault.',
      emoji: '🛡️🥚',
      spritePath: EliteBossSpritePaths.eggGuardian,
      maxHp: 120000,
      recommendedPower: 12000,
      coinReward: 750000,
      battleTokenReward: 12,
      unlockRequirementText: 'Defeat Egg Golem in Nightmare Mode 3 times',
      autoBattleSeconds: 45,
      projectileIntervalMs: 620,
      projectileSpeed: 310,
      manualBossMoveSpeed: 102,
      manualAimAccuracy: 0.82,
      manualPredictionStrength: 13,
      manualAimErrorMax: 32,
      manualAimRecalcMs: 280,
      isEliteBoss: true,
      manualBattleOnly: true,
      unlockNightmareWinsBossId: 'egg_golem',
      unlockNightmareWinsRequired: 3,
      rewardAnimalId: 'egg_guardian',
      eliteShieldBaseMisses: 10,
    ),
    BossBattleDefinition(
      id: 'shadow_phoenix',
      name: 'Shadow Phoenix',
      description: 'A blazing dark phoenix risen from the coop ashes.',
      emoji: '🔥🐦‍🔥',
      spritePath: EliteBossSpritePaths.shadowPhoenix,
      maxHp: 250000,
      recommendedPower: 25000,
      coinReward: 1000000,
      battleTokenReward: 15,
      unlockRequirementText: 'Defeat Shadow Rooster in Nightmare Mode 3 times',
      autoBattleSeconds: 50,
      projectileIntervalMs: 550,
      projectileSpeed: 340,
      manualBossMoveSpeed: 115,
      manualAimAccuracy: 0.94,
      manualPredictionStrength: 16,
      manualAimErrorMax: 18,
      manualAimRecalcMs: 250,
      isEliteBoss: true,
      manualBattleOnly: true,
      unlockNightmareWinsBossId: 'shadow_rooster',
      unlockNightmareWinsRequired: 3,
      rewardAnimalId: 'shadow_phoenix',
      eliteShieldBaseMisses: 11,
    ),
  ];

  static const endgameBosses = <BossBattleDefinition>[
    BossBattleDefinition(
      id: 'rotten_shell',
      name: 'The Rotten Shell',
      description:
          'A corrupted final egg pulsing with toxic rot and jagged shell shards.',
      emoji: '🥚☠️',
      maxHp: 500000,
      recommendedPower: 50000,
      coinReward: 2000000,
      battleTokenReward: 20,
      unlockRequirementText:
          'Defeat every boss at least once · flawless Shadow Phoenix',
      autoBattleSeconds: 55,
      projectileIntervalMs: 480,
      projectileSpeed: 360,
      manualBossMoveSpeed: 122,
      manualAimAccuracy: 0.96,
      manualPredictionStrength: 17,
      manualAimErrorMax: 14,
      manualAimRecalcMs: 235,
      isEliteBoss: true,
      manualBattleOnly: true,
      isEndgameBoss: true,
      eggShardReward: 3,
      eliteShieldBaseMisses: 13,
    ),
  ];

  static List<BossBattleDefinition> get bosses => [
    ...standardBosses,
    ...eliteBosses,
    ...endgameBosses,
  ];

  static BossBattleDefinition? bossById(String id) {
    for (final boss in bosses) {
      if (boss.id == id) return boss;
    }
    return null;
  }

  static String unlockProgressLabel(BossBattleDefinition boss) {
    if (boss.unlockNightmareWinsBossId == null) return '';
    final prerequisite = bossById(boss.unlockNightmareWinsBossId!);
    final name = prerequisite?.name ?? boss.unlockNightmareWinsBossId!;
    return '$name Nightmare wins';
  }
}
