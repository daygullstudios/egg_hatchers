import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/audio_assets.dart';

/// Central music/SFX controller with persisted settings and web-safe playback.
class AudioService extends ChangeNotifier {
  AudioService();

  static const _musicEnabledKey = 'audioMusicEnabled';
  static const _sfxEnabledKey = 'audioSfxEnabled';
  static const _musicVolumeKey = 'audioMusicVolume';
  static const _sfxVolumeKey = 'audioSfxVolume';

  static const rewardTriumphCooldownMs = 1000;
  static const rewardBigCooldownMs = 1500;
  static const assetPathCooldownMs = 180;
  static const rewardRecentGapMs = 2000;

  final AudioPlayer _musicPlayer = AudioPlayer(playerId: 'music');
  final List<AudioPlayer> _musicLayerPlayers = List.generate(
    AudioAssets.musicBossLayers.length,
    (i) => AudioPlayer(playerId: 'music_layer_$i'),
  );
  final List<AudioPlayer> _sfxPlayers = List.generate(
    4,
    (i) => AudioPlayer(playerId: 'sfx_$i'),
  );

  var _musicEnabled = true;
  var _sfxEnabled = true;
  var _musicVolume = 0.6;
  var _sfxVolume = 0.8;
  var _isInitialized = false;
  Future<void>? _initialization;
  var _userUnlocked = false;
  MusicTrack? _currentTrack;
  MusicTrack? _pendingTrack;
  List<double> _battleLayerMix = List.filled(
    AudioAssets.musicBossLayers.length,
    0,
  );
  List<double> _battleLayerVolumes = List.filled(
    AudioAssets.musicBossLayers.length,
    0,
  );
  var _battleLayerFadeGeneration = 0;
  var _sfxRoundRobin = 0;
  final Map<Sfx, DateTime> _lastSfxPlayed = {};
  final Map<String, DateTime> _lastAssetPathPlayed = {};
  DateTime? _lastRewardTriumphPlayed;
  DateTime? _lastRewardBigPlayed;

  bool get isInitialized => _isInitialized;
  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
  bool get userUnlocked => _userUnlocked;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _musicEnabled = prefs.getBool(_musicEnabledKey) ?? true;
      _sfxEnabled = prefs.getBool(_sfxEnabledKey) ?? true;
      _musicVolume = prefs.getDouble(_musicVolumeKey) ?? 0.6;
      _sfxVolume = prefs.getDouble(_sfxVolumeKey) ?? 0.8;
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (e) {
      debugPrint('AudioService initialize failed: $e');
    }
    _isInitialized = true;
    notifyListeners();
  }

  /// Call after the first user gesture (required on Flutter web).
  Future<void> unlockFromUserGesture() async {
    if (_userUnlocked) return;
    _userUnlocked = true;
    unawaited(initialize());
    final pending = _pendingTrack ?? MusicTrack.hatchery;
    _pendingTrack = null;
    await playMusic(pending);
  }

  Future<void> setMusicEnabled(bool value) async {
    if (_musicEnabled == value) return;
    _musicEnabled = value;
    notifyListeners();
    await _persistBool(_musicEnabledKey, value);
    if (!value) {
      await _stopMusic();
    } else if (_userUnlocked && _currentTrack != null) {
      await playMusic(_currentTrack!);
    } else if (_userUnlocked) {
      await playMusic(MusicTrack.hatchery);
    }
  }

  Future<void> setSfxEnabled(bool value) async {
    if (_sfxEnabled == value) return;
    _sfxEnabled = value;
    notifyListeners();
    await _persistBool(_sfxEnabledKey, value);
  }

  Future<void> setMusicVolume(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    if ((_musicVolume - clamped).abs() < 0.001) return;
    _musicVolume = clamped;
    notifyListeners();
    await _persistDouble(_musicVolumeKey, clamped);
    try {
      await _musicPlayer.setVolume(clamped);
      await _setBattleLayerVolumes(_targetBattleLayerVolumes());
    } catch (_) {}
  }

  Future<void> setSfxVolume(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    if ((_sfxVolume - clamped).abs() < 0.001) return;
    _sfxVolume = clamped;
    notifyListeners();
    await _persistDouble(_sfxVolumeKey, clamped);
  }

  Future<void> playMusic(MusicTrack track, {bool restart = false}) async {
    _pendingTrack = track;
    if (!_musicEnabled) {
      _debugLog('playMusic ${track.name} skipped (music disabled)');
      return;
    }
    if (!_userUnlocked) {
      _debugLog('playMusic ${track.name} queued (awaiting unlock)');
      return;
    }

    if (_currentTrack == track && !restart) {
      try {
        if (_musicPlayer.state == PlayerState.playing) {
          _debugLog('playMusic ${track.name} already playing');
          return;
        }
      } catch (_) {}
    }

    final previous = _currentTrack?.name ?? 'none';
    _debugLog('switch from $previous to ${track.name}');
    await _stopMusic();

    _pendingTrack = null;
    final played = await _tryPlayMusicAsset(track.assetPath);
    if (played) {
      _currentTrack = track;
      await _startBattleMusicLayers(track);
      return;
    }

    if (track == MusicTrack.finalBoss) {
      _debugLog('finalBoss failed, falling back to bossBattle');
      final fallbackPlayed = await _tryPlayMusicAsset(
        MusicTrack.bossBattle.assetPath,
      );
      if (fallbackPlayed) {
        _currentTrack = MusicTrack.bossBattle;
        await _startBattleMusicLayers(MusicTrack.bossBattle);
      } else {
        _currentTrack = null;
      }
      return;
    }

    _debugLog('playMusic ${track.name} failed');
    _currentTrack = null;
  }

  /// Fades in continuous background layers as a boss loses lives.
  Future<void> setBattleMusicStage(
    MusicTrack track, {
    required int completedStages,
    required int totalStages,
  }) async {
    if (!_musicEnabled || !_userUnlocked || totalStages <= 0) return;
    if (_currentTrack != track) await playMusic(track);
    if (_currentTrack != track) return;

    _battleLayerMix = battleLayerMix(
      completedStages: completedStages,
      totalStages: totalStages,
    );
    await _fadeBattleLayersTo(_targetBattleLayerVolumes());
    _debugLog('layer ${track.name} to stage $completedStages/$totalStages');
  }

  @visibleForTesting
  static List<double> battleLayerMix({
    required int completedStages,
    required int totalStages,
  }) {
    if (totalStages <= 0) return const [0, 0, 0];
    final progress = (completedStages / totalStages).clamp(0.0, 1.0);
    return [
      _layerProgress(progress, 0.05, 0.30),
      _layerProgress(progress, 0.20, 0.62),
      _layerProgress(progress, 0.46, 1.00),
    ];
  }

  static double _layerProgress(double progress, double start, double end) =>
      ((progress - start) / (end - start)).clamp(0.0, 1.0);

  void _debugLog(String message) {
    if (kDebugMode) debugPrint('[AUDIO] $message');
  }

  Future<void> stopMusic() => _stopMusic();

  /// True if a reward-tier SFX played within [withinMs].
  bool rewardPlayedRecently({int withinMs = rewardRecentGapMs}) {
    final now = DateTime.now();
    if (_lastRewardTriumphPlayed != null &&
        now.difference(_lastRewardTriumphPlayed!).inMilliseconds < withinMs) {
      return true;
    }
    if (_lastRewardBigPlayed != null &&
        now.difference(_lastRewardBigPlayed!).inMilliseconds < withinMs) {
      return true;
    }
    return false;
  }

  Future<void> playRewardTriumph() => playSfx(Sfx.coinReward);

  Future<void> playBigRewardTriumph() => playSfx(Sfx.eggShardReward);

  Future<void> playFinisherSlash() =>
      playSfx(Sfx.finisherSlash, volumeScale: 0.72);

  Future<void> playHatchReveal({required bool bigReward}) {
    if (bigReward) return playSfx(Sfx.rareChime);
    return playSfx(Sfx.hatchReveal);
  }

  Future<void> playSfx(Sfx sfx, {double volumeScale = 1.0}) async {
    if (!_sfxEnabled || !_userUnlocked) return;
    if (!_canPlaySfx(sfx)) return;
    if (!_canPlayAssetPath(sfx.assetPath)) return;
    if (!_canPlayRewardFamily(sfx.assetPath)) return;
    _recordSfxPlayed(sfx);

    final player = _sfxPlayers[_sfxRoundRobin++ % _sfxPlayers.length];
    try {
      await player.stop();
      await player.setVolume((_sfxVolume * volumeScale).clamp(0.0, 1.0));
      await player.play(AssetSource(sfx.assetPath));
      if (kDebugMode) {
        debugPrint('[SFX] ${sfx.name} → ${sfx.assetPath}');
      }
    } catch (e) {
      debugPrint('SFX play failed (${sfx.name}): $e');
    }
  }

  /// Short shell-crack SFX for hatches and boss shell breaks.
  Future<void> playEggCrack() => playSfx(Sfx.eggCrack, volumeScale: 0.78);

  bool _canPlaySfx(Sfx sfx) {
    if (sfx.cooldownMs <= 0) return true;
    final last = _lastSfxPlayed[sfx];
    if (last == null) return true;
    return DateTime.now().difference(last).inMilliseconds >= sfx.cooldownMs;
  }

  bool _canPlayAssetPath(String assetPath) {
    final last = _lastAssetPathPlayed[assetPath];
    if (last == null) return true;
    return DateTime.now().difference(last).inMilliseconds >=
        assetPathCooldownMs;
  }

  bool _canPlayRewardFamily(String assetPath) {
    if (_isRewardBigAsset(assetPath)) {
      final last = _lastRewardBigPlayed;
      if (last == null) return true;
      return DateTime.now().difference(last).inMilliseconds >=
          rewardBigCooldownMs;
    }
    if (_isRewardTriumphAsset(assetPath)) {
      final last = _lastRewardTriumphPlayed;
      if (last == null) return true;
      return DateTime.now().difference(last).inMilliseconds >=
          rewardTriumphCooldownMs;
    }
    return true;
  }

  bool _isRewardTriumphAsset(String path) {
    return path == AudioAssets.sfxCoinReward ||
        path == AudioAssets.sfxTokenReward ||
        path == AudioAssets.sfxHatchReveal ||
        path == AudioAssets.sfxFinisherBonus;
  }

  bool _isRewardBigAsset(String path) {
    return path == AudioAssets.sfxEggShardReward ||
        path == AudioAssets.sfxRareChime ||
        path == AudioAssets.sfxVictory;
  }

  void _recordSfxPlayed(Sfx sfx) {
    final now = DateTime.now();
    _lastSfxPlayed[sfx] = now;
    _lastAssetPathPlayed[sfx.assetPath] = now;
    if (_isRewardBigAsset(sfx.assetPath)) {
      _lastRewardBigPlayed = now;
    } else if (_isRewardTriumphAsset(sfx.assetPath)) {
      _lastRewardTriumphPlayed = now;
    }
  }

  Future<bool> _tryPlayMusicAsset(String assetPath) async {
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(_musicVolume);
      await _musicPlayer.play(AssetSource(assetPath));
      return true;
    } catch (e) {
      debugPrint('Music play failed ($assetPath): $e');
      return false;
    }
  }

  Future<void> _startBattleMusicLayers(MusicTrack track) async {
    if (track != MusicTrack.bossBattle && track != MusicTrack.finalBoss) return;
    for (var i = 0; i < _musicLayerPlayers.length; i++) {
      final player = _musicLayerPlayers[i];
      try {
        await player.setReleaseMode(ReleaseMode.loop);
        await player.setVolume(0);
        await player.play(AssetSource(AudioAssets.musicBossLayers[i]));
      } catch (e) {
        debugPrint('Battle music layer ${i + 1} failed: $e');
      }
    }
    await _setBattleLayerVolumes(_targetBattleLayerVolumes());
  }

  List<double> _targetBattleLayerVolumes() {
    const volumeCaps = [0.30, 0.24, 0.18];
    return List.generate(
      _musicLayerPlayers.length,
      (i) => _musicVolume * volumeCaps[i] * _battleLayerMix[i],
    );
  }

  Future<void> _fadeBattleLayersTo(List<double> target) async {
    final generation = ++_battleLayerFadeGeneration;
    final start = List<double>.from(_battleLayerVolumes);
    const steps = 8;
    for (var step = 1; step <= steps; step++) {
      await Future<void>.delayed(const Duration(milliseconds: 45));
      if (generation != _battleLayerFadeGeneration) return;
      final t = step / steps;
      await _setBattleLayerVolumes(
        List.generate(
          start.length,
          (i) => start[i] + (target[i] - start[i]) * t,
        ),
      );
    }
  }

  Future<void> _setBattleLayerVolumes(List<double> volumes) async {
    _battleLayerVolumes = List<double>.from(volumes);
    for (var i = 0; i < _musicLayerPlayers.length; i++) {
      try {
        await _musicLayerPlayers[i].setVolume(volumes[i].clamp(0.0, 1.0));
      } catch (_) {}
    }
  }

  Future<void> _stopMusic() async {
    _battleLayerFadeGeneration++;
    _battleLayerMix = List.filled(_musicLayerPlayers.length, 0);
    _battleLayerVolumes = List.filled(_musicLayerPlayers.length, 0);
    try {
      await _musicPlayer.stop();
    } catch (_) {}
    for (final player in _musicLayerPlayers) {
      try {
        await player.stop();
      } catch (_) {}
    }
  }

  Future<void> _persistBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
  }

  Future<void> _persistDouble(String key, double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(key, value);
    } catch (_) {}
  }

  @override
  void dispose() {
    _musicPlayer.dispose();
    for (final player in _musicLayerPlayers) {
      player.dispose();
    }
    for (final player in _sfxPlayers) {
      player.dispose();
    }
    super.dispose();
  }
}
