/// Device-owned presentation, accessibility, control, and audio preferences.
///
/// These values deliberately do not contain player identity or game progress.
class DeviceSettings {
  const DeviceSettings({
    this.backgroundThemeId,
    this.animalSpriteThemeId,
    this.showBattleBackgrounds = true,
    this.reducedBattleEffects = false,
    this.hapticsEnabled = true,
    this.showCustomSprites = true,
    this.musicEnabled = true,
    this.sfxEnabled = true,
    this.musicVolume = 0.6,
    this.sfxVolume = 0.8,
  });

  static const defaults = DeviceSettings();

  final String? backgroundThemeId;
  final String? animalSpriteThemeId;
  final bool showBattleBackgrounds;
  final bool reducedBattleEffects;
  final bool hapticsEnabled;
  final bool showCustomSprites;
  final bool musicEnabled;
  final bool sfxEnabled;
  final double musicVolume;
  final double sfxVolume;
}
