import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../data/audio_assets.dart';
import 'device_settings_store.dart';

/// Central music/SFX controller with persisted settings and web-safe playback.
class AudioService extends ChangeNotifier {
  AudioService({DeviceSettingsStore? settingsStore})
    : _settingsStore = settingsStore ?? DeviceSettingsStore() {
    _musicPositionSubscription = _musicPlayer.onPositionChanged.listen(
      _handleMusicPosition,
    );
    _musicCompleteSubscription = _musicPlayer.onPlayerComplete.listen(
      (_) => _handleMusicComplete(),
    );
  }

  final DeviceSettingsStore _settingsStore;

  static const rewardTriumphCooldownMs = 1000;
  static const rewardBigCooldownMs = 1500;
  static const assetPathCooldownMs = 180;
  static const rewardRecentGapMs = 2000;

  /// BandLab bar ranges at 144 BPM. Each section plays from [start], then
  /// repeats only [loopStart] through [loopEnd] until the next boss-life hit.
  @visibleForTesting
  static const battleMusicSections = <BattleMusicSection>[
    BattleMusicSection(
      start: Duration.zero,
      loopStart: Duration(microseconds: 1666667),
      loopEnd: Duration(microseconds: 13333333),
    ),
    BattleMusicSection(
      start: Duration(microseconds: 13333333),
      loopStart: Duration(microseconds: 16666667),
      loopEnd: Duration(microseconds: 26666667),
    ),
    BattleMusicSection(
      start: Duration(microseconds: 26666667),
      loopStart: Duration(microseconds: 30000000),
      loopEnd: Duration(microseconds: 40000000),
    ),
    BattleMusicSection(
      start: Duration(microseconds: 40000000),
      loopStart: Duration(microseconds: 40000000),
      loopEnd: Duration(microseconds: 66666667),
    ),
  ];

  final AudioPlayer _musicPlayer = AudioPlayer(playerId: 'music');
  late final StreamSubscription<Duration> _musicPositionSubscription;
  late final StreamSubscription<void> _musicCompleteSubscription;
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
  int? _pendingBattleMusicPhase;
  var _battleMusicPhase = -1;
  BattleMusicSection? _battleMusicSection;
  var _battleLoopSeekInProgress = false;
  var _battleMusicGeneration = 0;
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
      final settings = await _settingsStore.read(includePending: true);
      _musicEnabled = settings.musicEnabled;
      _sfxEnabled = settings.sfxEnabled;
      _musicVolume = settings.musicVolume;
      _sfxVolume = settings.sfxVolume;
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

  Future<bool> setMusicEnabled(bool value) async {
    _musicEnabled = value;
    notifyListeners();
    final saved = _settingsStore.writeMusicEnabled(value);
    if (!value) {
      await _stopMusic();
    } else if (_userUnlocked && _currentTrack != null) {
      await playMusic(_currentTrack!);
    } else if (_userUnlocked) {
      await playMusic(MusicTrack.hatchery);
    }
    return saved;
  }

  Future<bool> setSfxEnabled(bool value) async {
    _sfxEnabled = value;
    notifyListeners();
    return _settingsStore.writeSfxEnabled(value);
  }

  Future<bool> setMusicVolume(double value) async {
    final clamped = value.isFinite ? value.clamp(0.0, 1.0) : 0.6;
    _musicVolume = clamped;
    notifyListeners();
    final saved = _settingsStore.writeMusicVolume(clamped);
    try {
      await _musicPlayer.setVolume(clamped);
    } catch (_) {}
    return saved;
  }

  Future<bool> setSfxVolume(double value) async {
    final clamped = value.isFinite ? value.clamp(0.0, 1.0) : 0.8;
    _sfxVolume = clamped;
    notifyListeners();
    return _settingsStore.writeSfxVolume(clamped);
  }

  Future<void> playMusic(MusicTrack track, {bool restart = false}) async {
    _pendingTrack = track;
    if (track != MusicTrack.bossBattle) {
      _pendingBattleMusicPhase = null;
    }
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
    final pendingPhase = track == MusicTrack.bossBattle
        ? _pendingBattleMusicPhase
        : null;
    final played = await _tryPlayMusicAsset(
      track.assetPath,
      position: pendingPhase == null
          ? null
          : battleMusicSections[pendingPhase].start,
      releaseMode: pendingPhase == null ? ReleaseMode.loop : ReleaseMode.stop,
    );
    if (played) {
      _currentTrack = track;
      if (track == MusicTrack.bossBattle && pendingPhase != null) {
        await _activateBattleMusicPhase(
          pendingPhase,
          restart: true,
          seekToStart: false,
        );
      }
      return;
    }

    if (track == MusicTrack.finalBoss) {
      _debugLog('finalBoss failed, falling back to bossBattle');
      final fallbackPlayed = await _tryPlayMusicAsset(
        MusicTrack.bossBattle.assetPath,
      );
      if (fallbackPlayed) {
        _currentTrack = MusicTrack.bossBattle;
      } else {
        _currentTrack = null;
      }
      return;
    }

    _debugLog('playMusic ${track.name} failed');
    _currentTrack = null;
  }

  /// Moves normal boss music to the section matching the boss's lost lives.
  Future<void> setBattleMusicStage(
    MusicTrack track, {
    required int completedStages,
    required int totalStages,
    bool restart = false,
  }) async {
    if (track != MusicTrack.bossBattle || totalStages <= 0) {
      return;
    }
    final phase = battleMusicPhase(
      completedStages: completedStages,
      totalStages: totalStages,
    );
    _pendingTrack = track;
    _pendingBattleMusicPhase = phase;
    if (!_musicEnabled || !_userUnlocked) return;

    if (_currentTrack != track || restart) {
      await playMusic(track, restart: restart);
      return;
    }
    await _activateBattleMusicPhase(phase);
  }

  Future<void> _activateBattleMusicPhase(
    int phase, {
    bool restart = false,
    bool seekToStart = true,
  }) async {
    if (_currentTrack != MusicTrack.bossBattle) return;
    if (!restart && _battleMusicPhase == phase && _battleMusicSection != null) {
      return;
    }

    final generation = ++_battleMusicGeneration;
    final section = battleMusicSections[phase];
    _battleMusicPhase = phase;
    _battleMusicSection = section;
    _battleLoopSeekInProgress = true;
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.stop);
      if (seekToStart) {
        await _musicPlayer.seek(section.start);
      }
      if (generation != _battleMusicGeneration) return;
      if (_musicPlayer.state != PlayerState.playing) {
        await _musicPlayer.resume();
      }
      _debugLog('section ${phase + 1}/${battleMusicSections.length}');
    } catch (e) {
      debugPrint('Boss music section change failed: $e');
    } finally {
      if (generation == _battleMusicGeneration) {
        _battleLoopSeekInProgress = false;
      }
    }
  }

  @visibleForTesting
  static int battleMusicPhase({
    required int completedStages,
    required int totalStages,
  }) {
    if (totalStages <= 0) return 0;
    return completedStages.clamp(0, battleMusicSections.length - 1);
  }

  void _debugLog(String message) {
    if (kDebugMode) debugPrint('[AUDIO] $message');
  }

  Future<void> stopMusic() {
    _pendingBattleMusicPhase = null;
    return _stopMusic();
  }

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

  Future<bool> _tryPlayMusicAsset(
    String assetPath, {
    Duration? position,
    ReleaseMode releaseMode = ReleaseMode.loop,
  }) async {
    try {
      await _musicPlayer.setReleaseMode(releaseMode);
      await _musicPlayer.setVolume(_musicVolume);
      await _musicPlayer.play(AssetSource(assetPath), position: position);
      return true;
    } catch (e) {
      debugPrint('Music play failed ($assetPath): $e');
      return false;
    }
  }

  void _handleMusicPosition(Duration position) {
    final section = _battleMusicSection;
    if (_currentTrack != MusicTrack.bossBattle ||
        section == null ||
        _battleLoopSeekInProgress ||
        position < section.loopEnd) {
      return;
    }
    unawaited(_loopBattleMusic(section));
  }

  void _handleMusicComplete() {
    final section = _battleMusicSection;
    if (_currentTrack == MusicTrack.bossBattle &&
        section != null &&
        !_battleLoopSeekInProgress) {
      unawaited(_loopBattleMusic(section));
    }
  }

  Future<void> _loopBattleMusic(BattleMusicSection section) async {
    final generation = _battleMusicGeneration;
    _battleLoopSeekInProgress = true;
    try {
      await _musicPlayer.seek(section.loopStart);
      if (generation == _battleMusicGeneration &&
          _musicPlayer.state != PlayerState.playing) {
        await _musicPlayer.resume();
      }
    } catch (e) {
      debugPrint('Boss music loop seek failed: $e');
    } finally {
      if (generation == _battleMusicGeneration) {
        _battleLoopSeekInProgress = false;
      }
    }
  }

  Future<void> _stopMusic() async {
    _battleMusicGeneration++;
    _battleMusicPhase = -1;
    _battleMusicSection = null;
    _battleLoopSeekInProgress = false;
    try {
      await _musicPlayer.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    unawaited(_musicPositionSubscription.cancel());
    unawaited(_musicCompleteSubscription.cancel());
    _musicPlayer.dispose();
    for (final player in _sfxPlayers) {
      player.dispose();
    }
    super.dispose();
  }
}

@immutable
class BattleMusicSection {
  const BattleMusicSection({
    required this.start,
    required this.loopStart,
    required this.loopEnd,
  });

  final Duration start;
  final Duration loopStart;
  final Duration loopEnd;
}
