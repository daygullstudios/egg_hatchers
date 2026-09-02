import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';

import '../data/audio_assets.dart';
import '../data/game_data.dart';
import '../models/boss_reward_grant.dart';
import '../models/background_theme.dart';
import '../models/boss_battle.dart';
import '../models/custom_sprite_data.dart';
import '../models/finisher_reward.dart';
import '../models/mutation.dart';
import '../models/owned_animal.dart';
import '../services/audio_service.dart';
import '../services/custom_sprite_service.dart';
import '../services/game_service.dart';
import '../services/preferences_service.dart';
import '../theme/game_theme.dart';
import '../utils/battle_power_logic.dart';
import '../utils/battle_upgrade_logic.dart';
import '../utils/boss_battle_logic.dart';
import '../utils/egg_shard_logic.dart';
import '../utils/format_utils.dart';
import '../utils/rotten_shell_final_battle_logic.dart';
import '../widgets/audio_scope.dart';
import '../widgets/animal_motion.dart';
import '../widgets/battle_impact_overlay.dart';
import '../widgets/battle_resume_countdown.dart';
import '../widgets/boss_battle_background.dart';
import '../widgets/boss_defeat_animation.dart';
import '../widgets/boss_fight_intro_animation.dart';
import '../widgets/boss_finisher_slash_overlay.dart';
import '../widgets/boss_last_life_glow.dart';
import '../widgets/boss_projectile_widget.dart';
import '../widgets/boss_sprite.dart';
import '../widgets/daygull_unlock_cinematic.dart';
import '../widgets/daygull_discovery_sequence.dart';
import '../widgets/game_background.dart';
import '../widgets/game_sprite.dart';
import '../widgets/phone_width_layout.dart';
import '../widgets/rotten_shell_final_battle.dart';

/// Top-view dodge boss fight: move side-to-side, break shield, shoot eggs.
enum _ManualBattlePhase { intro, playing }

class ManualBossBattleScreen extends StatefulWidget {
  const ManualBossBattleScreen({
    super.key,
    required this.game,
    required this.preferences,
    required this.customSprites,
    required this.boss,
    required this.fighter,
    this.mode = ManualBattleMode.normal,
  });

  final GameService game;
  final PreferencesService preferences;
  final CustomSpriteService customSprites;
  final BossBattleDefinition boss;
  final OwnedAnimal fighter;
  final ManualBattleMode mode;

  @override
  State<ManualBossBattleScreen> createState() => _ManualBossBattleScreenState();
}

class _ManualBossBattleScreenState extends State<ManualBossBattleScreen>
    with SingleTickerProviderStateMixin {
  static const _playerSpeed = BossBattleLogic.manualPlayerMoveSpeed;
  static const _playerSize = 48.0;
  static const _bossSize = 80.0;
  static const _bossTop = 8.0;
  static const _projectileRadius = 10.0;
  static const _playerHitRadius = 22.0;
  static const _bossHitHalfWidth = 36.0;

  late final Ticker _ticker;
  late final Random _random;
  late int _battlePower;
  late String _fighterName;
  late String? _fighterSpritePath;
  late String _fighterAnimalId;
  late String _fighterEmoji;
  late CustomSpriteData? _fighterCustomSprite;
  late Mutation _fighterMutation;

  var _lives = BattleUpgradeLogic.baseManualBattleLives;
  var _bossLives = 0;
  var _bossMaxLives = 0;
  var _playerX = 0.0;
  var _previousPlayerX = 0.0;
  var _playerVelocityX = 0.0;
  var _bossX = 0.0;
  var _bossAimTargetX = 0.0;
  var _aimRecalcAccumulator = 0.0;
  var _arenaWidth = 320.0;
  var _arenaHeight = 280.0;
  var _shieldActive = true;
  var _missCount = 0;
  var _totalDodges = 0;
  var _successfulEggHits = 0;
  var _elapsedSeconds = 0.0;
  var _bossHitsLanded = 0;
  var _pointerActive = false;
  double? _targetX;
  var _moveLeft = false;
  var _moveRight = false;
  var _eggCooldownRemaining = 0.0;
  var _playerAttackMotionRemaining = 0.0;
  var _spawnAccumulator = 0.0;
  var _shieldFlash = 0.0;
  var _impactRemaining = 0.0;
  var _impactDuration = 0.28;
  var _impactIntensity = 0.0;
  var _impactPosition = Offset.zero;
  var _impactColor = Colors.white;
  var _bossSpeedBannerRemaining = 0.0;
  var _bossSpeedBannerIsRage = false;
  var _rageModeActive = false;
  var _gameOver = false;
  var _won = false;
  var _isPaused = false;
  var _resumeCountdownActive = false;
  var _rewardsApplied = false;
  var _resultDialogShown = false;
  var _showVictoryAnimation = false;
  var _showFinisherSlash = false;
  var _showFinalBattle = false;
  var _finisherRewardsApplied = false;
  var _phase = _ManualBattlePhase.intro;
  var _finisherBonusCoins = 0;
  var _finisherBonusTokens = 0;
  var _victoryCoinReward = 0;
  var _victoryTokenReward = 0;
  var _victoryEggShardReward = 0;
  var _livesLostThisBattle = 0;
  var _dayGullUnlockPending = false;
  String? _earnedRewardAnimalName;
  BossRewardGrant? _earnedRewardGrant;

  Duration? _lastTickElapsed;

  AudioService? _audioService;

  final List<_FallingProjectile> _bossProjectiles = [];
  _EggProjectile? _activeEgg;
  final List<_FloatingDamage> _floatingDamages = [];

  BackgroundTheme get theme => widget.preferences.selectedTheme;
  BossBattleDefinition get boss => widget.boss;
  ManualBattleMode get _mode => widget.mode;
  bool get _mobileAssistEnabled => BossBattleLogic.isMobileAssistEnabled();

  double get _eggSpeed =>
      BattleUpgradeLogic.manualEggSpeed(widget.game.battleShotSpeedLevel);

  double get _eggHomingLerp =>
      BattleUpgradeLogic.manualEggHomingLerp(widget.game.battleHomingLevel);

  double get _eggMaxHomingSpeed =>
      BattleUpgradeLogic.manualEggMaxHomingSpeed(widget.game.battleHomingLevel);

  int get _maxPlayerLives => BattleUpgradeLogic.manualBattleStartingLives(
    widget.game.battleExtraLifeLevel,
  );

  int get _requiredMisses => BossBattleLogic.manualRequiredMisses(
    _successfulEggHits,
    mode: _mode,
    boss: boss,
  );

  double get _projectileSpeedMultiplier =>
      BossBattleLogic.manualProjectileSpeedMultiplier(
        elapsedSeconds: _elapsedSeconds,
        bossHitCount: _successfulEggHits,
        mode: _mode,
        boss: boss,
      ) *
      _rageModeSpeedScale *
      BossBattleLogic.manualPlatformProjectileSpeedScale(
        mobileAssistEnabled: _mobileAssistEnabled,
      );

  int get _currentProjectileIntervalMs =>
      BossBattleLogic.manualProjectileIntervalMsWithRage(
        boss,
        _successfulEggHits,
        mode: _mode,
        rageModeActive: _rageModeActive,
        livesRemaining: _bossLives,
        maxLives: _bossMaxLives,
      );

  double get _currentBossMoveSpeed =>
      BossBattleLogic.manualBossMoveSpeed(
        boss,
        _successfulEggHits,
        mode: _mode,
      ) *
      _rageModeSpeedScale;

  double get _rageModeSpeedScale => BossBattleLogic.rageModeSpeedScale(
    boss: boss,
    livesRemaining: _bossLives,
    maxLives: _bossMaxLives,
    rageModeActive: _rageModeActive,
  );

  double get _bossCenterY => _bossTop + _bossSize / 2;

  double get _bossSpawnY => _bossTop + _bossSize - 4;

  double get _impactProgress => _impactRemaining <= 0
      ? 1
      : (1 - _impactRemaining / _impactDuration).clamp(0, 1);

  Offset get _arenaShakeOffset {
    if (_impactRemaining <= 0 || widget.preferences.reducedBattleEffects) {
      return Offset.zero;
    }
    final fade = 1 - _impactProgress;
    final amplitude = 5.5 * _impactIntensity * fade;
    final phase = _impactProgress * pi * 9;
    return Offset(sin(phase) * amplitude, cos(phase * 1.35) * amplitude * 0.55);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audioService ??= AudioScope.maybeOf(context);
  }

  @override
  void initState() {
    super.initState();
    _random = Random();
    _initFighterInfo();
    _ticker = createTicker(_onTick);
    _resetBattleState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _playBattleMusic();
    });
  }

  AudioService get _audio => _audioService ?? AudioScope.of(context);

  MusicTrack get _battleMusicTrack => boss.id == EggShardLogic.rottenShellBossId
      ? MusicTrack.finalBoss
      : MusicTrack.bossBattle;

  void _playBattleMusic() {
    _audio.playMusic(_battleMusicTrack);
  }

  void _restoreHatcheryMusic() {
    _audioService?.playMusic(MusicTrack.hatchery);
  }

  void _initFighterInfo() {
    final animal = GameData.animalById(widget.fighter.animalId)!;
    _fighterMutation =
        GameData.mutationById(widget.fighter.mutationId) ??
        GameData.mutations.first;
    _fighterName = _fighterMutation.fullName(animal);
    _fighterAnimalId = animal.id;
    _fighterSpritePath = animal.spritePath;
    _fighterEmoji = _fighterMutation.displayEmoji(animal);
    _fighterCustomSprite = widget.customSprites.getDisplaySprite(animal.id);
    _battlePower = BattlePowerLogic.battlePowerForOwnedAnimal(widget.fighter);
  }

  void _resetBattleState() {
    _lives = _maxPlayerLives;
    _bossMaxLives = BossBattleLogic.manualBossLives(boss);
    _bossLives = _bossMaxLives;
    _shieldActive = true;
    _missCount = 0;
    _totalDodges = 0;
    _successfulEggHits = 0;
    _elapsedSeconds = 0;
    _bossHitsLanded = 0;
    _pointerActive = false;
    _targetX = null;
    _moveLeft = false;
    _moveRight = false;
    _eggCooldownRemaining = 0;
    _playerAttackMotionRemaining = 0;
    _spawnAccumulator = 0;
    _shieldFlash = 0;
    _impactRemaining = 0;
    _impactIntensity = 0;
    _impactPosition = Offset.zero;
    _impactColor = Colors.white;
    _bossSpeedBannerRemaining = 0;
    _bossSpeedBannerIsRage = false;
    _rageModeActive = false;
    _gameOver = false;
    _won = false;
    _isPaused = false;
    _resumeCountdownActive = false;
    _rewardsApplied = false;
    _resultDialogShown = false;
    _showVictoryAnimation = false;
    _showFinisherSlash = false;
    _showFinalBattle = false;
    _finisherRewardsApplied = false;
    _finisherBonusCoins = 0;
    _finisherBonusTokens = 0;
    _victoryCoinReward = 0;
    _victoryTokenReward = 0;
    _victoryEggShardReward = 0;
    _livesLostThisBattle = 0;
    _dayGullUnlockPending = false;
    _earnedRewardAnimalName = null;
    _earnedRewardGrant = null;
    _lastTickElapsed = null;
    _phase = _ManualBattlePhase.intro;
    _ticker.stop();
    _bossProjectiles.clear();
    _activeEgg = null;
    _floatingDamages.clear();
    _playerX = _arenaWidth / 2;
    _previousPlayerX = _playerX;
    _playerVelocityX = 0;
    _bossX = _arenaWidth / 2;
    _bossAimTargetX = _bossX;
    _aimRecalcAccumulator = 0;
  }

  double _bossMinX() => _bossSize / 2 + 8;

  double _bossMaxX() => max(_bossMinX(), _arenaWidth - _bossSize / 2 - 8);

  void _recalculateBossAimTarget() {
    final minBx = _bossMinX();
    final maxBx = _bossMaxX();
    final aimError =
        (_random.nextDouble() * 2 - 1) *
        BossBattleLogic.manualAimErrorMax(boss, mode: _mode);
    final newTarget = BossBattleLogic.manualBossAimTarget(
      boss: boss,
      playerX: _playerX,
      playerVelocityX: _playerVelocityX,
      minX: minBx,
      maxX: maxBx,
      aimError: aimError,
      mode: _mode,
    );
    _bossAimTargetX = (_bossAimTargetX * 0.35 + newTarget * 0.65).clamp(
      minBx,
      maxBx,
    );
  }

  void _onIntroComplete() {
    if (!mounted || _phase != _ManualBattlePhase.intro) return;
    setState(() {
      _phase = _ManualBattlePhase.playing;
      _lastTickElapsed = null;
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _restoreHatcheryMusic();
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!mounted || _gameOver || _phase != _ManualBattlePhase.playing) return;

    if (_isPaused) {
      _lastTickElapsed = elapsed;
      return;
    }

    final last = _lastTickElapsed ?? elapsed;
    var dt = (elapsed - last).inMicroseconds / 1000000.0;
    _lastTickElapsed = elapsed;
    if (dt <= 0) return;
    if (dt > 0.05) dt = 0.05;

    _updateGame(dt);
    setState(() {});
  }

  void _pauseBattle() {
    if (_gameOver || _isPaused || _phase != _ManualBattlePhase.playing) return;
    setState(() {
      _isPaused = true;
      _moveLeft = false;
      _moveRight = false;
      _pointerActive = false;
      _targetX = null;
    });
  }

  void _resumeBattle() {
    if (_gameOver || !_isPaused || _resumeCountdownActive) return;
    setState(() => _resumeCountdownActive = true);
  }

  void _finishResumeCountdown() {
    if (!mounted || _gameOver || !_isPaused || !_resumeCountdownActive) return;
    setState(() {
      _resumeCountdownActive = false;
      _isPaused = false;
      _lastTickElapsed = null;
    });
  }

  Future<void> _confirmQuitBattle() async {
    if (_gameOver) return;

    final quit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quit this battle?'),
        content: const Text('You will not receive rewards.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Fighting'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Quit'),
          ),
        ],
      ),
    );

    if (quit == true && mounted) {
      setState(() => _isPaused = false);
      _endBattle(won: false);
    }
  }

  void _updateGame(double dt) {
    if (_arenaWidth <= 0) return;

    _elapsedSeconds += dt;

    final minX = _playerSize / 2 + 8;
    final maxX = _arenaWidth - _playerSize / 2 - 8;

    if (_pointerActive && _targetX != null) {
      final target = _targetX!.clamp(minX, maxX);
      final diff = target - _playerX;
      final step =
          BossBattleLogic.manualTouchMoveSpeed(
            _playerSpeed,
            mobileAssistEnabled: _mobileAssistEnabled,
          ) *
          dt;
      if (diff.abs() <= step) {
        _playerX = target;
      } else {
        _playerX += step * diff.sign;
      }
    } else {
      var dx = 0.0;
      if (_moveLeft) dx -= _playerSpeed * dt;
      if (_moveRight) dx += _playerSpeed * dt;
      if (dx != 0) {
        _playerX = (_playerX + dx).clamp(minX, maxX);
      }
    }

    _playerVelocityX = _playerX - _previousPlayerX;
    _previousPlayerX = _playerX;

    if (_eggCooldownRemaining > 0) {
      _eggCooldownRemaining = max(0, _eggCooldownRemaining - dt);
    }
    if (_playerAttackMotionRemaining > 0) {
      _playerAttackMotionRemaining = max(0, _playerAttackMotionRemaining - dt);
    }

    if (_shieldFlash > 0) {
      _shieldFlash = max(0, _shieldFlash - dt);
    }
    if (_impactRemaining > 0) {
      _impactRemaining = max(0, _impactRemaining - dt);
    }

    if (_bossSpeedBannerRemaining > 0) {
      _bossSpeedBannerRemaining = max(0, _bossSpeedBannerRemaining - dt);
    }

    _updateBossMovement(dt);

    _spawnAccumulator += dt * 1000;
    final interval = _currentProjectileIntervalMs;
    while (_spawnAccumulator >= interval &&
        _bossProjectiles.length < BossBattleLogic.manualMaxBossProjectiles) {
      _spawnAccumulator -= interval;
      _spawnBossProjectile();
    }

    _updateBossProjectiles(dt);
    _updateEgg(dt);
    if (_mobileAssistEnabled) {
      _shootEgg();
    }

    for (var i = _floatingDamages.length - 1; i >= 0; i--) {
      _floatingDamages[i].age += dt;
      if (_floatingDamages[i].age > 0.9) {
        _floatingDamages.removeAt(i);
      }
    }
  }

  void _updateBossMovement(double dt) {
    final minBx = _bossMinX();
    final maxBx = _bossMaxX();

    _aimRecalcAccumulator += dt * 1000;
    if (_aimRecalcAccumulator >= boss.manualAimRecalcMs) {
      _aimRecalcAccumulator -= boss.manualAimRecalcMs;
      _recalculateBossAimTarget();
    }

    final diff = _bossAimTargetX - _bossX;
    final step = _currentBossMoveSpeed * dt;
    if (diff.abs() <= step) {
      _bossX = _bossAimTargetX;
    } else {
      _bossX += step * diff.sign;
    }
    _bossX = _bossX.clamp(minBx, maxBx);
  }

  void _spawnBossProjectile() {
    final spread = 24.0 * (_random.nextDouble() * 2 - 1);
    final x = (_bossX + spread).clamp(16.0, _arenaWidth - 16.0).toDouble();
    _bossProjectiles.add(_FallingProjectile(x: x, y: _bossSpawnY));
  }

  void _updateBossProjectiles(double dt) {
    final playerY = _arenaHeight - _playerSize - 12;
    final missY = _arenaHeight + 4;

    for (var i = _bossProjectiles.length - 1; i >= 0; i--) {
      final p = _bossProjectiles[i];
      p.y += boss.projectileSpeed * _projectileSpeedMultiplier * dt;

      final hitPlayer =
          (p.x - _playerX).abs() < _playerHitRadius + _projectileRadius &&
          (p.y - playerY).abs() < _playerHitRadius + _projectileRadius;

      if (hitPlayer) {
        _bossProjectiles.removeAt(i);
        _loseLife();
        continue;
      }

      if (p.y >= missY) {
        _bossProjectiles.removeAt(i);
        _registerMiss();
      }
    }
  }

  void _updateEgg(double dt) {
    final egg = _activeEgg;
    if (egg == null) return;

    egg.y -= _eggSpeed * dt;

    final dx = _bossX - egg.x;
    if (dx.abs() > 0.5) {
      final maxStep = _eggMaxHomingSpeed * dt;
      final homingStep = (dx * _eggHomingLerp).clamp(-maxStep, maxStep);
      egg.x += homingStep;
    }

    final hitBoss =
        egg.y <= _bossCenterY + _bossSize / 2 &&
        (egg.x - _bossX).abs() < _bossHitHalfWidth + _projectileRadius;

    if (hitBoss) {
      _activeEgg = null;
      if (!_shieldActive) {
        _hitBoss();
      }
      return;
    }

    if (egg.y < -20) {
      _activeEgg = null;
    }
  }

  void _registerMiss() {
    _totalDodges++;
    if (!_shieldActive) return;
    _missCount++;
    if (_missCount >= _requiredMisses) {
      _shieldActive = false;
      _shieldFlash = 0.35;
      _triggerImpact(
        position: Offset(_bossX, _bossCenterY),
        color: const Color(0xFF80D8FF),
        intensity: 0.72,
      );
      _audio.playSfx(Sfx.shieldBreak);
    }
  }

  void _regenerateShieldAfterHit() {
    _successfulEggHits++;
    _shieldActive = true;
    _missCount = 0;
    _shieldFlash = 0.35;
  }

  void _loseLife() {
    if (_gameOver) return;
    _triggerImpact(
      position: Offset(_playerX, _arenaHeight - _playerSize / 2 - 12),
      color: const Color(0xFFFF5252),
      intensity: 0.9,
    );
    _livesLostThisBattle++;
    _lives = max(0, _lives - 1);
    _floatingDamages.add(
      _FloatingDamage(
        x: _playerX,
        y: _arenaHeight - _playerSize - 28,
        label: '-1 life',
      ),
    );
    if (_lives <= 0) {
      _endBattle(won: false);
    } else {
      _audio.playSfx(Sfx.playerHit);
    }
  }

  void _hitBoss() {
    if (_gameOver) return;
    _triggerImpact(
      position: Offset(_bossX, _bossCenterY),
      color: const Color(0xFFFFD54F),
      intensity: 1,
    );
    _bossLives = max(0, _bossLives - 1);
    _bossHitsLanded++;
    _audio.playSfx(Sfx.bossHit);
    _floatingDamages.add(
      _FloatingDamage(x: _bossX, y: _bossTop + 8, label: 'CRACK!'),
    );
    if (_bossLives <= 0) {
      _endBattle(won: true);
      return;
    }
    if (RottenShellFinalBattleLogic.shouldEnter(
      bossId: boss.id,
      livesRemaining: _bossLives,
      maxLives: _bossMaxLives,
    )) {
      _enterFinalBattle();
      return;
    }

    _regenerateShieldAfterHit();

    final enteringRage =
        !_rageModeActive &&
        BossBattleLogic.showManualLastLifeGlow(
          boss,
          livesRemaining: _bossLives,
          maxLives: _bossMaxLives,
        );
    if (enteringRage) {
      _rageModeActive = true;
      _bossSpeedBannerIsRage = true;
      _bossSpeedBannerRemaining = 2.0;
      _shieldFlash = 0.45;
      Future<void>.delayed(const Duration(milliseconds: 460), () {
        if (mounted && _rageModeActive && !_gameOver) {
          _audio.playSfx(Sfx.rageMode);
        }
      });
    } else {
      _bossSpeedBannerIsRage = false;
      _bossSpeedBannerRemaining = 1.8;
    }
  }

  void _triggerImpact({
    required Offset position,
    required Color color,
    required double intensity,
  }) {
    _impactDuration = widget.preferences.reducedBattleEffects ? 0.18 : 0.3;
    _impactRemaining = _impactDuration;
    _impactPosition = position;
    _impactColor = color;
    _impactIntensity = intensity.clamp(0, 1);
  }

  void _enterFinalBattle() {
    _ticker.stop();
    _bossProjectiles.clear();
    _activeEgg = null;
    _floatingDamages.clear();
    _pointerActive = false;
    _moveLeft = false;
    _moveRight = false;
    setState(() {
      _rageModeActive = false;
      _bossSpeedBannerRemaining = 0;
      _showFinalBattle = true;
    });
  }

  void _onFinalBattleVictory() {
    if (!mounted || !_showFinalBattle || _gameOver) return;
    setState(() {
      _showFinalBattle = false;
      _bossLives = 0;
    });
    _endBattle(won: true, skipFinisher: true);
  }

  void _onFinalBattleDefeat() {
    if (!mounted || !_showFinalBattle || _gameOver) return;
    setState(() {
      _showFinalBattle = false;
      _lives = 0;
    });
    _endBattle(won: false);
  }

  void _shootEgg() {
    if (_phase != _ManualBattlePhase.playing ||
        _gameOver ||
        _isPaused ||
        _shieldActive ||
        _activeEgg != null) {
      return;
    }
    if (_eggCooldownRemaining > 0) return;

    _activeEgg = _EggProjectile(
      x: _playerX,
      y: _arenaHeight - _playerSize - 20,
    );
    _playerAttackMotionRemaining = 0.24;
    _eggCooldownRemaining =
        BossBattleLogic.manualEggCooldown.inMilliseconds / 1000;
    _audio.playSfx(Sfx.playerShoot);
  }

  void _endBattle({required bool won, bool skipFinisher = false}) {
    if (_gameOver) return;
    _gameOver = true;
    _won = won;
    _ticker.stop();
    _bossProjectiles.clear();
    _activeEgg = null;
    _floatingDamages.clear();
    _applyRewardsOnce();
    if (!won) {
      _audio.playSfx(Sfx.defeat);
    }

    if (won && skipFinisher) {
      setState(() => _showVictoryAnimation = true);
      return;
    }

    if (won) {
      setState(() => _showFinisherSlash = true);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showResultDialog();
    });
  }

  void _onFinisherSlashComplete(FinisherRewardTotals totals) {
    if (!mounted || !_showFinisherSlash) return;
    _applyFinisherRewardsOnce(totals);
    setState(() {
      _showFinisherSlash = false;
      _finisherBonusCoins = totals.bonusCoins;
      _finisherBonusTokens = totals.bonusTokens;
      _showVictoryAnimation = true;
    });
  }

  void _applyFinisherRewardsOnce(FinisherRewardTotals totals) {
    if (_finisherRewardsApplied) return;
    _finisherRewardsApplied = true;
    if (totals.bonusCoins > 0 || totals.bonusTokens > 0) {
      widget.game.applyManualFinisherBonus(
        coins: totals.bonusCoins,
        tokens: totals.bonusTokens,
      );
    }
  }

  void _onVictoryAnimationComplete() {
    unawaited(_handleVictoryAnimationComplete());
  }

  Future<void> _handleVictoryAnimationComplete() async {
    if (!mounted || !_showVictoryAnimation) return;
    setState(() => _showVictoryAnimation = false);
    if (_dayGullUnlockPending) {
      _dayGullUnlockPending = false;
      await DayGullUnlockCinematic.show(context);
      if (!mounted) return;
      await DayGullDiscoverySequence.show(
        context,
        game: widget.game,
        theme: theme,
      );
      if (!mounted) return;
    }
    _showResultDialog();
  }

  void _applyRewardsOnce() {
    if (_rewardsApplied) return;
    _rewardsApplied = true;

    final rewardMultiplier = _won
        ? BossBattleLogic.manualRewardMultiplier(_mode)
        : 1;
    final coinReward = _won ? boss.coinReward * rewardMultiplier : 0;
    final tokenReward = _won ? boss.battleTokenReward * rewardMultiplier : 0;

    _victoryCoinReward = coinReward;
    _victoryTokenReward = tokenReward;
    _victoryEggShardReward = _won && boss.eggShardReward > 0
        ? boss.eggShardReward
        : 0;

    final result = BossBattleResult(
      won: _won,
      rounds: 0,
      initialPlayerHp: _maxPlayerLives,
      initialBossHp: _bossMaxLives,
      finalPlayerHp: _won ? _lives : 0,
      finalBossHp: _bossLives,
      damageLog: const [],
      roundSnapshots: const [],
      battlePower: _battlePower,
      coinReward: coinReward,
      battleTokenReward: tokenReward,
    );
    final dayGullUnlocksNow =
        _won &&
        boss.id == EggShardLogic.rottenShellBossId &&
        !widget.game.isDayGullEggUnlocked;
    final grant = widget.game.applyBossBattleRewards(
      boss.id,
      result,
      mode: _won ? _mode : ManualBattleMode.normal,
      rewardAnimalId: _won ? boss.rewardAnimalId : null,
      livesLostThisBattle: _livesLostThisBattle,
    );
    _dayGullUnlockPending = dayGullUnlocksNow;
    _earnedRewardAnimalName = grant?.displayName;
    _earnedRewardGrant = grant;
  }

  Future<void> _showResultDialog() async {
    if (_resultDialogShown || !mounted) return;
    _resultDialogShown = true;

    final rewardMultiplier = _won
        ? BossBattleLogic.manualRewardMultiplier(_mode)
        : 1;

    if (_won) {
      final coins = boss.coinReward * rewardMultiplier + _finisherBonusCoins;
      final tokens =
          boss.battleTokenReward * rewardMultiplier + _finisherBonusTokens;
      if (!_audio.rewardPlayedRecently()) {
        if (_victoryEggShardReward > 0 || _earnedRewardGrant != null) {
          _audio.playBigRewardTriumph();
        } else if (coins > 0 || tokens > 0) {
          _audio.playRewardTriumph();
        }
      }
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: theme.scaffoldColor.withValues(alpha: 0.92),
      builder: (dialogContext) => _ManualBattleResultDialog(
        theme: theme,
        boss: boss,
        fighterName: _fighterName,
        won: _won,
        mode: _mode,
        livesRemaining: _lives,
        bossLivesRemaining: _bossLives,
        missCount: _totalDodges,
        bossHitsLanded: _bossHitsLanded,
        coinReward: _won ? boss.coinReward * rewardMultiplier : 0,
        tokenReward: _won ? boss.battleTokenReward * rewardMultiplier : 0,
        finisherBonusCoins: _finisherBonusCoins,
        finisherBonusTokens: _finisherBonusTokens,
        eggShardReward: _victoryEggShardReward,
        rewardAnimalName: _earnedRewardAnimalName,
        rewardGrant: _earnedRewardGrant,
        customSprites: widget.customSprites,
        onBackToBattles: () {
          _restoreHatcheryMusic();
          Navigator.pop(dialogContext);
          if (mounted) Navigator.pop(context);
        },
        onBattleAgain: () {
          Navigator.pop(dialogContext);
          if (!mounted) return;
          widget.game.recordBossBattleStarted();
          setState(() {
            _resetBattleState();
            _resultDialogShown = false;
          });
          _playBattleMusic();
        },
      ),
    );
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (_phase != _ManualBattlePhase.playing ||
        _gameOver ||
        _isPaused ||
        _showVictoryAnimation ||
        _showFinisherSlash) {
      return KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      if (event is KeyUpEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
            event.logicalKey == LogicalKeyboardKey.keyA) {
          _moveLeft = false;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
            event.logicalKey == LogicalKeyboardKey.keyD) {
          _moveRight = false;
        }
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.keyA) {
      _moveLeft = true;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.keyD) {
      _moveRight = true;
    } else if (event.logicalKey == LogicalKeyboardKey.space) {
      _shootEgg();
    }
    return KeyEventResult.handled;
  }

  void _onArenaPointerDown(double localX) {
    if (_phase != _ManualBattlePhase.playing || _gameOver || _isPaused) return;
    _pointerActive = true;
    _updateTargetX(localX);
  }

  void _onArenaPointerMove(double localX) {
    if (_phase != _ManualBattlePhase.playing ||
        _gameOver ||
        _isPaused ||
        !_pointerActive) {
      return;
    }
    _updateTargetX(localX);
  }

  void _onArenaPointerRelease() {
    _pointerActive = false;
    _targetX = null;
  }

  void _updateTargetX(double localX) {
    final minX = _playerSize / 2 + 8;
    final maxX = _arenaWidth - _playerSize / 2 - 8;
    _targetX = localX.clamp(minX, maxX);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.preferences,
      builder: (context, _) {
        final currentTheme = widget.preferences.selectedTheme;

        return Focus(
          autofocus: true,
          onKeyEvent: _handleKey,
          child: PopScope(
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) _restoreHatcheryMusic();
            },
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: PhoneWidthAppBar(
                title: boss.name,
                titleStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                backgroundColor: currentTheme.appBarColor,
                foregroundColor: Colors.white,
              ),
              body: GameBackground(
                theme: currentTheme,
                child: PhoneWidthLayout(
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_mode != ManualBattleMode.normal)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _ModeBadge(
                                  theme: currentTheme,
                                  mode: _mode,
                                ),
                              ),
                            _BattleHeader(
                              theme: currentTheme,
                              boss: boss,
                              bossLives: _bossLives,
                              bossMaxLives: _bossMaxLives,
                              lives: _lives,
                              maxPlayerLives: _maxPlayerLives,
                              shieldActive: _shieldActive,
                              shieldFlash: _shieldFlash,
                              missCount: _missCount,
                              requiredMisses: _requiredMisses,
                              showPauseButton:
                                  _phase == _ManualBattlePhase.playing &&
                                  !_gameOver &&
                                  !_isPaused &&
                                  !_showFinalBattle &&
                                  !_showVictoryAnimation &&
                                  !_showFinisherSlash,
                              onPause: _pauseBattle,
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  _arenaWidth = constraints.maxWidth;
                                  _arenaHeight = constraints.maxHeight;
                                  if (_playerX == 0 || _playerX > _arenaWidth) {
                                    _playerX = _arenaWidth / 2;
                                  }
                                  if (_bossX == 0 || _bossX > _arenaWidth) {
                                    _bossX = _arenaWidth / 2;
                                  }
                                  return Transform.translate(
                                    offset: _arenaShakeOffset,
                                    child: _Arena(
                                      theme: currentTheme,
                                      boss: boss,
                                      showBattleBackgrounds: widget
                                          .preferences
                                          .showBattleBackgrounds,
                                      arenaWidth: _arenaWidth,
                                      arenaHeight: _arenaHeight,
                                      playerX: _playerX,
                                      bossX: _bossX,
                                      bossTop: _bossTop,
                                      bossLives: _bossLives,
                                      bossMaxLives: _bossMaxLives,
                                      bossSpeedBannerRemaining:
                                          _bossSpeedBannerRemaining,
                                      bossSpeedBannerIsRage:
                                          _bossSpeedBannerIsRage,
                                      playerSize: _playerSize,
                                      bossSize: _bossSize,
                                      fighterCustomSprite: _fighterCustomSprite,
                                      fighterAnimalId: _fighterAnimalId,
                                      fighterSpritePath: _fighterSpritePath,
                                      fighterEmoji: _fighterEmoji,
                                      fighterMutation: _fighterMutation,
                                      fighterName: _fighterName,
                                      fighterMotion:
                                          _impactRemaining > 0 &&
                                              _impactColor ==
                                                  const Color(0xFFFF5252)
                                          ? AnimalMotionState.hurt
                                          : _playerAttackMotionRemaining > 0
                                          ? AnimalMotionState.attack
                                          : AnimalMotionState.idle,
                                      bossProjectiles: _bossProjectiles,
                                      activeEgg: _activeEgg,
                                      floatingDamages: _floatingDamages,
                                      shieldActive: _shieldActive,
                                      shieldFlash: _shieldFlash,
                                      impactRemaining: _impactRemaining,
                                      impactProgress: _impactProgress,
                                      impactPosition: _impactPosition,
                                      impactColor: _impactColor,
                                      impactIntensity: _impactIntensity,
                                      reducedEffects: widget
                                          .preferences
                                          .reducedBattleEffects,
                                      onPointerDown: _onArenaPointerDown,
                                      onPointerMove: _onArenaPointerMove,
                                      onPointerRelease: _onArenaPointerRelease,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hold and drag to dodge.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: currentTheme.cardTextSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Harder bosses aim better.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: currentTheme.cardTextSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _ShootRow(
                              theme: currentTheme,
                              shieldActive: _shieldActive,
                              canShoot:
                                  _phase == _ManualBattlePhase.playing &&
                                  !_gameOver &&
                                  !_isPaused &&
                                  !_showVictoryAnimation &&
                                  !_showFinisherSlash &&
                                  !_shieldActive &&
                                  _activeEgg == null &&
                                  _eggCooldownRemaining <= 0,
                              eggOnCooldown: _eggCooldownRemaining > 0,
                              onShootEgg: _shootEgg,
                            ),
                          ],
                        ),
                      ),
                      if (_phase == _ManualBattlePhase.intro)
                        Positioned.fill(
                          child: BossFightIntroAnimation(
                            fighterName: _fighterName,
                            fighterAnimalId: _fighterAnimalId,
                            fighterSpritePath: _fighterSpritePath,
                            fighterEmoji: _fighterEmoji,
                            fighterCustomSprite: _fighterCustomSprite,
                            boss: boss,
                            mode: _mode,
                            audio: _audioService,
                            onComplete: _onIntroComplete,
                          ),
                        ),
                      if (_isPaused)
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: _resumeCountdownActive
                                ? BattleResumeCountdown(
                                    theme: currentTheme,
                                    reducedEffects:
                                        widget.preferences.reducedBattleEffects,
                                    onComplete: _finishResumeCountdown,
                                  )
                                : _PauseOverlay(
                                    theme: currentTheme,
                                    onResume: _resumeBattle,
                                    onQuit: _confirmQuitBattle,
                                    showBattleBackgrounds: widget
                                        .preferences
                                        .showBattleBackgrounds,
                                    onToggleBattleBackgrounds: widget
                                        .preferences
                                        .setShowBattleBackgrounds,
                                  ),
                          ),
                        ),
                      if (_showFinalBattle)
                        Positioned.fill(
                          child: RottenShellFinalBattle(
                            fighter: widget.fighter,
                            fighterCustomSprite: _fighterCustomSprite,
                            boss: boss,
                            reducedEffects:
                                widget.preferences.reducedBattleEffects,
                            hapticsEnabled: widget.preferences.hapticsEnabled,
                            onVictory: _onFinalBattleVictory,
                            onDefeat: _onFinalBattleDefeat,
                          ),
                        ),
                      if (_showFinisherSlash)
                        Positioned.fill(
                          child: BossFinisherSlashOverlay(
                            boss: boss,
                            theme: currentTheme,
                            showBattleBackgrounds:
                                widget.preferences.showBattleBackgrounds,
                            onComplete: _onFinisherSlashComplete,
                          ),
                        ),
                      if (_showVictoryAnimation)
                        Positioned.fill(
                          child: BossDefeatAnimation(
                            theme: currentTheme,
                            boss: boss,
                            mode: _mode,
                            coinReward: _victoryCoinReward,
                            tokenReward: _victoryTokenReward,
                            animalRewardName: _earnedRewardAnimalName,
                            showBattleBackgrounds:
                                widget.preferences.showBattleBackgrounds,
                            onComplete: _onVictoryAnimationComplete,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.theme, required this.mode});

  final BackgroundTheme theme;
  final ManualBattleMode mode;

  @override
  Widget build(BuildContext context) {
    final (label, color, rewardLabel) = switch (mode) {
      ManualBattleMode.hard => (
        'Hard Phase',
        Colors.deepOrange.shade700,
        '2× rewards',
      ),
      ManualBattleMode.nightmare => (
        'Nightmare Mode',
        Colors.purple.shade800,
        '3× rewards',
      ),
      ManualBattleMode.normal => ('', Colors.grey, ''),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.85)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.amber.shade700.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              rewardLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade200,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BattleHeader extends StatelessWidget {
  const _BattleHeader({
    required this.theme,
    required this.boss,
    required this.bossLives,
    required this.bossMaxLives,
    required this.lives,
    required this.maxPlayerLives,
    required this.shieldActive,
    required this.shieldFlash,
    required this.missCount,
    required this.requiredMisses,
    required this.showPauseButton,
    required this.onPause,
  });

  final BackgroundTheme theme;
  final BossBattleDefinition boss;
  final int bossLives;
  final int bossMaxLives;
  final int lives;
  final int maxPlayerLives;
  final bool shieldActive;
  final double shieldFlash;
  final int missCount;
  final int requiredMisses;
  final bool showPauseButton;
  final VoidCallback onPause;

  String _bossLivesDisplay(int remaining, int maxLives) {
    final eggs = List.generate(maxLives, (index) {
      return index < remaining ? '🥚' : '💀';
    }).join();
    return 'Boss Lives: $eggs';
  }

  String _playerLivesDisplay(int remaining, int maxLives) {
    if (maxLives <= 4) {
      final hearts = List.generate(maxLives, (index) {
        return index < remaining ? '❤️' : '🖤';
      }).join();
      return 'Your Lives: $hearts';
    }
    return 'Your Lives: ❤️ ×$remaining';
  }

  @override
  Widget build(BuildContext context) {
    final shieldLabel = shieldActive ? 'Shielded' : 'Shield down!';
    final shieldColor = shieldActive
        ? theme.secondaryColor
        : Colors.orange.shade400;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: GameTheme.cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  boss.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.cardTextPrimaryColor,
                  ),
                ),
              ),
              if (showPauseButton) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onPause,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primaryColor,
                    side: BorderSide(color: theme.primaryColor),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.pause, size: 18),
                  label: const Text(
                    'Pause',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _bossLivesDisplay(bossLives, bossMaxLives),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.cardTextPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _playerLivesDisplay(lives, maxPlayerLives),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.cardTextPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: shieldColor.withValues(
                alpha: shieldFlash > 0 ? 0.45 : 0.18,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: shieldColor),
            ),
            child: Text(
              shieldLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.cardTextPrimaryColor,
              ),
            ),
          ),
          if (shieldActive) ...[
            const SizedBox(height: 6),
            Text(
              'Break shield: $missCount / $requiredMisses',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.cardTextSecondaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({
    required this.theme,
    required this.onResume,
    required this.onQuit,
    required this.showBattleBackgrounds,
    required this.onToggleBattleBackgrounds,
  });

  final BackgroundTheme theme;
  final VoidCallback onResume;
  final VoidCallback onQuit;
  final bool showBattleBackgrounds;
  final ValueChanged<bool> onToggleBattleBackgrounds;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: theme.scaffoldColor.withValues(alpha: 0.82),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(20),
          decoration: GameTheme.cardDecoration(theme),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Paused',
                textAlign: TextAlign.center,
                style: GameTheme.sectionTitle(theme, size: 22),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Battle Backgrounds',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.cardTextPrimaryColor,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: showBattleBackgrounds,
                    activeTrackColor: theme.primaryColor.withValues(
                      alpha: 0.45,
                    ),
                    activeThumbColor: theme.primaryColor,
                    onChanged: onToggleBattleBackgrounds,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onResume,
                style: GameTheme.filledButton(theme),
                child: const Text('Resume'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onQuit,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  foregroundColor: theme.cardTextSecondaryColor,
                  side: BorderSide(color: theme.cardTextSecondaryColor),
                ),
                child: const Text(
                  'Quit Battle',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Arena extends StatelessWidget {
  const _Arena({
    required this.theme,
    required this.boss,
    required this.showBattleBackgrounds,
    required this.arenaWidth,
    required this.arenaHeight,
    required this.playerX,
    required this.bossX,
    required this.bossTop,
    required this.bossLives,
    required this.bossMaxLives,
    required this.bossSpeedBannerRemaining,
    required this.bossSpeedBannerIsRage,
    required this.playerSize,
    required this.bossSize,
    required this.fighterCustomSprite,
    required this.fighterAnimalId,
    required this.fighterSpritePath,
    required this.fighterEmoji,
    required this.fighterMutation,
    required this.fighterName,
    required this.fighterMotion,
    required this.bossProjectiles,
    required this.activeEgg,
    required this.floatingDamages,
    required this.shieldActive,
    required this.shieldFlash,
    required this.impactRemaining,
    required this.impactProgress,
    required this.impactPosition,
    required this.impactColor,
    required this.impactIntensity,
    required this.reducedEffects,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerRelease,
  });

  final BackgroundTheme theme;
  final BossBattleDefinition boss;
  final bool showBattleBackgrounds;
  final double arenaWidth;
  final double arenaHeight;
  final double playerX;
  final double bossX;
  final double bossTop;
  final int bossLives;
  final int bossMaxLives;
  final double bossSpeedBannerRemaining;
  final bool bossSpeedBannerIsRage;
  final double playerSize;
  final double bossSize;
  final CustomSpriteData? fighterCustomSprite;
  final String fighterAnimalId;
  final String? fighterSpritePath;
  final String fighterEmoji;
  final Mutation fighterMutation;
  final String fighterName;
  final AnimalMotionState fighterMotion;
  final List<_FallingProjectile> bossProjectiles;
  final _EggProjectile? activeEgg;
  final List<_FloatingDamage> floatingDamages;
  final bool shieldActive;
  final double shieldFlash;
  final double impactRemaining;
  final double impactProgress;
  final Offset impactPosition;
  final Color impactColor;
  final double impactIntensity;
  final bool reducedEffects;
  final ValueChanged<double> onPointerDown;
  final ValueChanged<double> onPointerMove;
  final VoidCallback onPointerRelease;

  @override
  Widget build(BuildContext context) {
    final playerY = arenaHeight - playerSize - 12;
    final bossLeft = bossX - bossSize / 2;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanDown: (details) => onPointerDown(details.localPosition.dx),
      onPanUpdate: (details) => onPointerMove(details.localPosition.dx),
      onPanEnd: (_) => onPointerRelease(),
      onPanCancel: () => onPointerRelease(),
      child: Container(
        decoration: BoxDecoration(
          color: showBattleBackgrounds
              ? Colors.transparent
              : theme.panelColor.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.cardBorderColor),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            if (showBattleBackgrounds)
              Positioned.fill(child: BossBattleBackground(bossId: boss.id)),
            if (showBattleBackgrounds)
              Positioned.fill(
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.08)),
              ),
            if (shieldActive && shieldFlash <= 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.secondaryColor.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            if (shieldFlash > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.white.withValues(
                      alpha: 0.12 * shieldFlash / 0.35,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: bossLeft,
              top: bossTop,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  BossLastLifeGlow(
                    boss: boss,
                    bossLivesRemaining: bossLives,
                    bossMaxLives: bossMaxLives,
                    size: bossSize,
                    child: BossSprite(
                      spritePath: boss.spritePath,
                      fallbackEmoji: boss.emoji,
                      bossId: boss.id,
                      size: bossSize,
                      semanticLabel: boss.name,
                    ),
                  ),
                  if (shieldActive)
                    Container(
                      width: bossSize + 12,
                      height: bossSize + 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.secondaryColor.withValues(alpha: 0.7),
                          width: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (bossSpeedBannerRemaining > 0)
              Positioned(
                left: 0,
                right: 0,
                top: bossTop + bossSize + 4,
                child: IgnorePointer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        bossSpeedBannerIsRage
                            ? 'Rage Mode!'
                            : 'Boss speed increased!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: bossSpeedBannerIsRage
                              ? Colors.red.shade400
                              : Colors.orange.shade300,
                          fontSize: bossSpeedBannerIsRage ? 14 : 12,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                      ),
                      if (bossSpeedBannerIsRage)
                        Text(
                          'The boss is faster!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red.shade200,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 3),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            for (final p in bossProjectiles)
              Positioned(
                left: p.x - 11,
                top: p.y - 12,
                child: BossProjectileWidget(bossId: boss.id, size: 22),
              ),
            if (activeEgg != null)
              Positioned(
                left: activeEgg!.x - 12,
                top: activeEgg!.y - 12,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade200,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.brown.shade400, width: 2),
                  ),
                  child: const Center(
                    child: Text('🥚', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ),
            Positioned(
              left: playerX - playerSize / 2,
              top: playerY,
              child: GameAnimalPortrait(
                customSprite: fighterCustomSprite,
                animalId: fighterAnimalId,
                spritePath: fighterSpritePath,
                fallbackEmoji: fighterEmoji,
                size: playerSize,
                mutation: fighterMutation,
                semanticLabel: fighterName,
                motion: fighterMotion,
                attackDirection: const Offset(0, -1),
              ),
            ),
            for (final d in floatingDamages)
              Positioned(
                left: d.x - 24,
                top: d.y - d.age * 28,
                child: Opacity(
                  opacity: (1 - d.age / 0.9).clamp(0.0, 1.0),
                  child: Text(
                    d.displayText,
                    style: TextStyle(
                      color: Colors.red.shade300,
                      fontSize: d.label != null ? 13 : 14,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ),
            if (impactRemaining > 0)
              Positioned.fill(
                child: BattleImpactOverlay(
                  position: impactPosition,
                  progress: impactProgress,
                  color: impactColor,
                  intensity: impactIntensity,
                  reducedEffects: reducedEffects,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShootRow extends StatelessWidget {
  const _ShootRow({
    required this.theme,
    required this.shieldActive,
    required this.canShoot,
    required this.eggOnCooldown,
    required this.onShootEgg,
  });

  final BackgroundTheme theme;
  final bool shieldActive;
  final bool canShoot;
  final bool eggOnCooldown;
  final VoidCallback onShootEgg;

  @override
  Widget build(BuildContext context) {
    if (shieldActive) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: canShoot ? onShootEgg : null,
        style: GameTheme.filledButton(
          theme,
          color: canShoot ? theme.secondaryColor : theme.disabledColor,
          height: 48,
        ),
        child: Text(
          eggOnCooldown ? 'Egg...' : 'Shoot Egg 🥚',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ManualBattleResultDialog extends StatelessWidget {
  const _ManualBattleResultDialog({
    required this.theme,
    required this.boss,
    required this.fighterName,
    required this.won,
    required this.mode,
    required this.livesRemaining,
    required this.bossLivesRemaining,
    required this.missCount,
    required this.bossHitsLanded,
    required this.coinReward,
    required this.tokenReward,
    this.finisherBonusCoins = 0,
    this.finisherBonusTokens = 0,
    this.eggShardReward = 0,
    this.rewardAnimalName,
    this.rewardGrant,
    this.customSprites,
    required this.onBackToBattles,
    required this.onBattleAgain,
  });

  final BackgroundTheme theme;
  final BossBattleDefinition boss;
  final String fighterName;
  final bool won;
  final ManualBattleMode mode;
  final int livesRemaining;
  final int bossLivesRemaining;
  final int missCount;
  final int bossHitsLanded;
  final int coinReward;
  final int tokenReward;
  final int finisherBonusCoins;
  final int finisherBonusTokens;
  final int eggShardReward;
  final String? rewardAnimalName;
  final BossRewardGrant? rewardGrant;
  final CustomSpriteService? customSprites;
  final VoidCallback onBackToBattles;
  final VoidCallback onBattleAgain;

  String get _title {
    if (won) {
      return switch (mode) {
        ManualBattleMode.hard => '🏆 Hard Phase Victory!',
        ManualBattleMode.nightmare => '🏆 Nightmare Victory!',
        ManualBattleMode.normal => '🏆 Victory!',
      };
    }
    return switch (mode) {
      ManualBattleMode.hard => '💀 Hard Phase Defeat',
      ManualBattleMode.nightmare => '💀 Nightmare Defeat',
      ManualBattleMode.normal => '💀 Defeat',
    };
  }

  String? get _rewardBadge {
    if (!won) return null;
    return switch (mode) {
      ManualBattleMode.hard => '2× Rewards',
      ManualBattleMode.nightmare => '3× Rewards',
      ManualBattleMode.normal => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.cardBorderColor),
      ),
      title: Text(
        _title,
        style: TextStyle(
          color: theme.cardTextPrimaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_rewardBadge != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _rewardBadge!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade600,
                  ),
                ),
              ),
            if (!won)
              Text(
                mode == ManualBattleMode.normal
                    ? 'You ran out of lives!'
                    : 'Try again after upgrading or choosing a stronger animal.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade400,
                ),
              ),
            if (!won) const SizedBox(height: 8),
            Text(
              boss.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.cardTextPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Fighter: $fighterName',
              style: TextStyle(color: theme.cardTextSecondaryColor),
            ),
            const SizedBox(height: 10),
            Text(
              'Dodges: $missCount · Egg hits: $bossHitsLanded',
              style: TextStyle(
                fontSize: 13,
                color: theme.cardTextSecondaryColor,
              ),
            ),
            if (won) ...[
              const SizedBox(height: 6),
              Text(
                'Your lives left: $livesRemaining',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Boss lives left: $bossLivesRemaining',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryColor,
                ),
              ),
            ],
            if (won) ...[
              const SizedBox(height: 12),
              Text(
                'Rewards:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.secondaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  '🪙 ${formatCoins(coinReward)}',
                  '⚔️ +$tokenReward',
                  if (eggShardReward > 0) '🥚 +$eggShardReward Shards',
                ].join(' · '),
                style: TextStyle(color: theme.cardTextPrimaryColor),
              ),
              const SizedBox(height: 10),
              Text(
                'Finisher Bonus:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.cardTextSecondaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                finisherBonusCoins > 0 || finisherBonusTokens > 0
                    ? '🪙 +${formatCoins(finisherBonusCoins)} · ⚔️ +$finisherBonusTokens'
                    : 'No finisher bonus this time.',
                style: TextStyle(
                  color: finisherBonusCoins > 0 || finisherBonusTokens > 0
                      ? Colors.amber.shade300
                      : theme.cardTextSecondaryColor,
                  fontSize: 13,
                ),
              ),
              if (rewardAnimalName != null) ...[
                const SizedBox(height: 8),
                if (rewardGrant != null) ...[
                  Center(
                    child: GameAnimalPortrait(
                      customSprite: customSprites?.getDisplaySprite(
                        rewardGrant!.animal.id,
                      ),
                      animalId: rewardGrant!.animal.id,
                      spritePath: rewardGrant!.animal.spritePath,
                      fallbackEmoji: rewardGrant!.animal.emoji,
                      size: 72,
                      mutation: rewardGrant!.mutation,
                      semanticLabel: rewardGrant!.displayName,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.amber.shade700),
                      ),
                      child: const Text(
                        'Elite',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  'You earned $rewardAnimalName!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.secondaryColor,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onBackToBattles,
          child: const Text('Back to Battles'),
        ),
        FilledButton(
          onPressed: onBattleAgain,
          style: GameTheme.filledButton(theme),
          child: const Text('Battle Again'),
        ),
      ],
    );
  }
}

class _FallingProjectile {
  _FallingProjectile({required this.x, required this.y});

  double x;
  double y;
}

class _EggProjectile {
  _EggProjectile({required this.x, required this.y});

  double x;
  double y;
}

class _FloatingDamage {
  _FloatingDamage({required this.x, required this.y, this.amount, this.label})
    : assert(amount != null || label != null);

  final double x;
  final double y;
  final int? amount;
  final String? label;
  double age = 0;

  String get displayText => label ?? '-${formatCoins(amount!)}';
}
