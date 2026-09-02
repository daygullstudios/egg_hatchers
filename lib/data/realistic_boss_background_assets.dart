import '../utils/boss_visual_config.dart';

/// Generated arena artwork used by the Realistic animal theme.
class RealisticBossBackgroundAssets {
  RealisticBossBackgroundAssets._();

  static const assetDirectory = 'assets/images/boss_backgrounds/realistic';

  static const _assetNames = {
    BossBattleBackgroundType.slimeSwamp: 'slime_swamp',
    BossBattleBackgroundType.eggCave: 'egg_cave',
    BossBattleBackgroundType.shadowRoost: 'shadow_roost',
    BossBattleBackgroundType.royalPalace: 'royal_palace',
    BossBattleBackgroundType.guardianNest: 'guardian_nest',
    BossBattleBackgroundType.phoenixLair: 'phoenix_lair',
    BossBattleBackgroundType.rottenNest: 'rotten_nest',
  };

  static String? assetPathForBossId(String bossId) {
    final type = BossVisualConfig.backgroundTypeForBossId(bossId);
    final assetName = _assetNames[type];
    if (assetName == null) return null;
    return '$assetDirectory/$assetName.jpg';
  }
}
