/// Central registry of audio asset paths (relative to assets/).
class AudioAssets {
  AudioAssets._();

  static const musicHatchery = 'sounds/music/hatchery_chill_loop.mp3';
  static const musicBossBattle = 'sounds/music/boss_music.wav';
  static const musicFinalBoss = 'sounds/music/final_boss_music.mp3';

  static const sfxEggCrack = 'sounds/sfx/egg_crack_reference.mp3';
  static const sfxHatchReveal = 'sounds/sfx/hatch_reveal.wav';
  static const sfxRareChime = 'sounds/sfx/rare_chime.wav';
  static const sfxCoinReward = 'sounds/sfx/coin_reward.wav';
  static const sfxTokenReward = 'sounds/sfx/token_reward.wav';
  static const sfxEggShardReward = 'sounds/sfx/egg_shard_reward.wav';
  static const sfxPurchase = 'sounds/sfx/purchase_real.mp3';
  static const sfxUiTap = 'sounds/sfx/ui_tap.wav';
  static const sfxConfirm = 'sounds/sfx/confirm.wav';
  static const sfxErrorLocked = 'sounds/sfx/error_locked.wav';
  static const sfxPlayerShoot = 'sounds/sfx/player_shoot.wav';
  static const sfxPlayerHit = 'sounds/sfx/player_hit.wav';
  static const sfxBossHit = 'sounds/sfx/boss_hit.wav';
  static const sfxShieldBreak = 'sounds/sfx/shield_break.wav';
  static const sfxRageMode = 'sounds/sfx/rage_mode.wav';
  static const sfxVictory = 'sounds/sfx/victory.wav';
  static const sfxDefeat = 'sounds/sfx/defeat.wav';
  static const sfxFinisherSlash = 'sounds/sfx/finisher_slash_real.mp3';
  static const sfxFinisherBonus = 'sounds/sfx/finisher_bonus.wav';
  static const sfxSlimePop = 'sounds/sfx/slime_pop.wav';
  static const sfxGolemCrack = 'sounds/sfx/golem_crack.wav';
  static const sfxFeatherBurst = 'sounds/sfx/feather_burst.wav';
  static const sfxRoyalPop = 'sounds/sfx/royal_pop.wav';
  static const sfxGuardianShatter = 'sounds/sfx/guardian_shatter.wav';
  static const sfxPhoenixFlap = 'sounds/sfx/phoenix_flap.wav';
  static const sfxPhoenixImpact = 'sounds/sfx/phoenix_impact.wav';
  static const sfxPhoenixLaugh = 'sounds/sfx/phoenix_laugh.wav';
  static const sfxRottenPulse = 'sounds/sfx/rotten_pulse.wav';
  static const sfxRottenCollapse = 'sounds/sfx/rotten_collapse.wav';
  static const sfxRottenExplosion = 'sounds/sfx/rotten_explosion.wav';
  static const sfxRottenShardHarvest = 'sounds/sfx/rotten_shard_harvest.wav';
}

enum MusicTrack {
  hatchery(AudioAssets.musicHatchery),
  bossBattle(AudioAssets.musicBossBattle),
  finalBoss(AudioAssets.musicFinalBoss);

  const MusicTrack(this.assetPath);
  final String assetPath;
}

enum Sfx {
  eggCrack(AudioAssets.sfxEggCrack, cooldownMs: 1000, releaseVolumeScale: 0.9),
  hatchReveal(
    AudioAssets.sfxHatchReveal,
    cooldownMs: 1150,
    releaseVolumeScale: 0.9,
  ),
  rareChime(
    AudioAssets.sfxRareChime,
    cooldownMs: 1400,
    releaseVolumeScale: 0.86,
  ),
  coinReward(
    AudioAssets.sfxCoinReward,
    cooldownMs: 850,
    releaseVolumeScale: 0.88,
  ),
  tokenReward(
    AudioAssets.sfxTokenReward,
    cooldownMs: 900,
    releaseVolumeScale: 0.88,
  ),
  eggShardReward(
    AudioAssets.sfxEggShardReward,
    cooldownMs: 1500,
    releaseVolumeScale: 0.86,
  ),
  uiTap(AudioAssets.sfxUiTap, cooldownMs: 110, releaseVolumeScale: 0.7),
  confirm(AudioAssets.sfxConfirm, cooldownMs: 350, releaseVolumeScale: 0.8),
  purchase(AudioAssets.sfxPurchase, cooldownMs: 2800, releaseVolumeScale: 0.84),
  errorLocked(
    AudioAssets.sfxErrorLocked,
    cooldownMs: 450,
    releaseVolumeScale: 0.78,
  ),
  playerShoot(
    AudioAssets.sfxPlayerShoot,
    cooldownMs: 340,
    releaseVolumeScale: 0.78,
  ),
  playerHit(
    AudioAssets.sfxPlayerHit,
    cooldownMs: 380,
    releaseVolumeScale: 0.76,
  ),
  bossHit(AudioAssets.sfxBossHit, cooldownMs: 440, releaseVolumeScale: 0.76),
  shieldBreak(
    AudioAssets.sfxShieldBreak,
    cooldownMs: 500,
    releaseVolumeScale: 0.8,
  ),
  rageMode(AudioAssets.sfxRageMode, cooldownMs: 950, releaseVolumeScale: 0.78),
  victory(AudioAssets.sfxVictory, cooldownMs: 1500, releaseVolumeScale: 0.84),
  defeat(AudioAssets.sfxDefeat, cooldownMs: 1150, releaseVolumeScale: 0.84),
  finisherSlash(
    AudioAssets.sfxFinisherSlash,
    cooldownMs: 220,
    releaseVolumeScale: 0.82,
  ),
  finisherBonus(
    AudioAssets.sfxFinisherBonus,
    cooldownMs: 950,
    releaseVolumeScale: 0.86,
  ),
  slimePop(AudioAssets.sfxSlimePop, cooldownMs: 650, releaseVolumeScale: 0.82),
  golemCrack(
    AudioAssets.sfxGolemCrack,
    cooldownMs: 700,
    releaseVolumeScale: 0.8,
  ),
  featherBurst(
    AudioAssets.sfxFeatherBurst,
    cooldownMs: 600,
    releaseVolumeScale: 0.8,
  ),
  royalPop(AudioAssets.sfxRoyalPop, cooldownMs: 650, releaseVolumeScale: 0.82),
  guardianShatter(
    AudioAssets.sfxGuardianShatter,
    cooldownMs: 700,
    releaseVolumeScale: 0.78,
  ),
  phoenixFlap(
    AudioAssets.sfxPhoenixFlap,
    cooldownMs: 550,
    releaseVolumeScale: 0.72,
  ),
  phoenixImpact(
    AudioAssets.sfxPhoenixImpact,
    cooldownMs: 650,
    releaseVolumeScale: 0.8,
  ),
  phoenixLaugh(
    AudioAssets.sfxPhoenixLaugh,
    cooldownMs: 950,
    releaseVolumeScale: 0.76,
  ),
  rottenPulse(
    AudioAssets.sfxRottenPulse,
    cooldownMs: 750,
    releaseVolumeScale: 0.72,
  ),
  rottenCollapse(
    AudioAssets.sfxRottenCollapse,
    cooldownMs: 1200,
    releaseVolumeScale: 0.8,
  ),
  rottenExplosion(
    AudioAssets.sfxRottenExplosion,
    cooldownMs: 1300,
    releaseVolumeScale: 0.76,
  ),
  rottenShardHarvest(
    AudioAssets.sfxRottenShardHarvest,
    cooldownMs: 1450,
    releaseVolumeScale: 0.82,
  );

  const Sfx(
    this.assetPath, {
    required this.cooldownMs,
    required this.releaseVolumeScale,
  });
  final String assetPath;
  final int cooldownMs;
  final double releaseVolumeScale;
}
