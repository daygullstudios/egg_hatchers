/// Central registry of audio asset paths (relative to assets/).
class AudioAssets {
  AudioAssets._();

  static const musicHatchery = 'sounds/music/hatchery_chill_loop.mp3';
  static const musicBossBattle = 'sounds/music/boss_music.mp3';
  static const musicFinalBoss = 'sounds/music/final_boss_music.mp3';

  static const sfxEggCrack = 'sounds/sfx/egg_shell_crack_dry.wav';
  static const sfxHatchReveal = 'sounds/sfx/hatch_reveal.wav';
  static const sfxRareChime = 'sounds/sfx/rare_chime.wav';
  static const sfxCoinReward = 'sounds/sfx/coin_reward.wav';
  static const sfxTokenReward = 'sounds/sfx/token_reward.wav';
  static const sfxEggShardReward = 'sounds/sfx/egg_shard_reward.wav';
  static const sfxPurchase = 'sounds/sfx/purchase.wav';
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
  static const sfxFinisherSlash = 'sounds/sfx/finisher_slash.wav';
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
  eggCrack(AudioAssets.sfxEggCrack, cooldownMs: 80),
  hatchReveal(AudioAssets.sfxHatchReveal, cooldownMs: 700),
  rareChime(AudioAssets.sfxRareChime, cooldownMs: 1200),
  coinReward(AudioAssets.sfxCoinReward, cooldownMs: 700),
  tokenReward(AudioAssets.sfxTokenReward, cooldownMs: 700),
  eggShardReward(AudioAssets.sfxEggShardReward, cooldownMs: 1200),
  uiTap(AudioAssets.sfxUiTap, cooldownMs: 45),
  confirm(AudioAssets.sfxConfirm, cooldownMs: 100),
  purchase(AudioAssets.sfxPurchase, cooldownMs: 300),
  errorLocked(AudioAssets.sfxErrorLocked, cooldownMs: 250),
  playerShoot(AudioAssets.sfxPlayerShoot, cooldownMs: 120),
  playerHit(AudioAssets.sfxPlayerHit, cooldownMs: 0),
  bossHit(AudioAssets.sfxBossHit, cooldownMs: 120),
  shieldBreak(AudioAssets.sfxShieldBreak, cooldownMs: 0),
  rageMode(AudioAssets.sfxRageMode, cooldownMs: 0),
  victory(AudioAssets.sfxVictory, cooldownMs: 1200),
  defeat(AudioAssets.sfxDefeat, cooldownMs: 250),
  finisherSlash(AudioAssets.sfxFinisherSlash, cooldownMs: 180),
  finisherBonus(AudioAssets.sfxFinisherBonus, cooldownMs: 700),
  slimePop(AudioAssets.sfxSlimePop, cooldownMs: 0),
  golemCrack(AudioAssets.sfxGolemCrack, cooldownMs: 0),
  featherBurst(AudioAssets.sfxFeatherBurst, cooldownMs: 0),
  royalPop(AudioAssets.sfxRoyalPop, cooldownMs: 0),
  guardianShatter(AudioAssets.sfxGuardianShatter, cooldownMs: 0),
  phoenixFlap(AudioAssets.sfxPhoenixFlap, cooldownMs: 300),
  phoenixImpact(AudioAssets.sfxPhoenixImpact, cooldownMs: 0),
  phoenixLaugh(AudioAssets.sfxPhoenixLaugh, cooldownMs: 0),
  rottenPulse(AudioAssets.sfxRottenPulse, cooldownMs: 0),
  rottenCollapse(AudioAssets.sfxRottenCollapse, cooldownMs: 0),
  rottenExplosion(AudioAssets.sfxRottenExplosion, cooldownMs: 0),
  rottenShardHarvest(AudioAssets.sfxRottenShardHarvest, cooldownMs: 0);

  const Sfx(this.assetPath, {required this.cooldownMs});
  final String assetPath;
  final int cooldownMs;
}
