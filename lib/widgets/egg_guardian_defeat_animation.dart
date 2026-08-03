import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/audio_assets.dart';
import '../models/background_theme.dart';
import '../utils/cinematic_sound_guard.dart';
import 'audio_scope.dart';
import '../models/boss_battle.dart';
import 'boss_cinematic_ui.dart';
import 'boss_sprite.dart';
import 'egg_guardian_cinematic_background.dart';

/// Cinematic Egg Guardian defeat celebration for manual battle victories.
class EggGuardianDefeatAnimation extends StatefulWidget {
  const EggGuardianDefeatAnimation({
    super.key,
    required this.theme,
    required this.boss,
    required this.coinReward,
    required this.tokenReward,
    this.animalRewardName,
    required this.onComplete,
  });

  static const duration = Duration(milliseconds: 11500);

  final BackgroundTheme theme;
  final BossBattleDefinition boss;
  final int coinReward;
  final int tokenReward;
  final String? animalRewardName;
  final VoidCallback onComplete;

  @override
  State<EggGuardianDefeatAnimation> createState() =>
      _EggGuardianDefeatAnimationState();
}

class _EggGuardianDefeatAnimationState extends State<EggGuardianDefeatAnimation>
    with SingleTickerProviderStateMixin {
  static const _totalMs = 11500.0;
  static const _skipAfterMs = 1000.0;
  static const _leftArmStart = 3000.0;
  static const _leftArmEnd = 4200.0;
  static const _rightArmStart = 4200.0;
  static const _rightArmEnd = 5400.0;
  static const _leftLegStart = 5400.0;
  static const _leftLegEnd = 6500.0;
  static const _rightLegStart = 6500.0;
  static const _rightLegEnd = 7600.0;
  static const _torsoStartMs = 7600.0;
  static const _burstEndMs = 9200.0;
  static const _baseSpriteSize = 168.0;
  static const _sizeBoost = 1.4;

  late final AnimationController _controller;
  late final List<_ShellFragment> _fragments;
  late final CinematicSoundGuard _soundGuard;
  var _completed = false;

  @override
  void initState() {
    super.initState();
    _fragments = _ShellFragment.generate(32);
    _soundGuard = CinematicSoundGuard();
    _controller =
        AnimationController(
            vsync: this,
            duration: EggGuardianDefeatAnimation.duration,
          )
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) _finishOnce();
          })
          ..forward();
  }

  void _finishOnce() {
    if (_completed || !mounted) return;
    _completed = true;
    _controller.stop();
    widget.onComplete();
  }

  void _trySkip() {
    if (_controller.value * _totalMs < _skipAfterMs || _completed) return;
    _finishOnce();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _phase(double startMs, double endMs) {
    final t = _controller.value * _totalMs;
    if (t <= startMs) return 0;
    if (t >= endMs) return 1;
    return (t - startMs) / (endMs - startMs);
  }

  double _timeMs() => _controller.value * _totalMs;

  void _playPhaseSounds(double t) {
    final audio = AudioScope.maybeOf(context);
    if (audio == null) return;
    _soundGuard.maybeAt(t, 'firstCrack', 1000, audio.playEggCrack);
    _soundGuard.maybeAt(
      t,
      'leftArm',
      _leftArmStart,
      () => audio.playSfx(Sfx.guardianShatter),
    );
    _soundGuard.maybeAt(t, 'rightArm', _rightArmStart, audio.playEggCrack);
    _soundGuard.maybeAt(t, 'leftLeg', _leftLegStart, audio.playEggCrack);
    _soundGuard.maybeAt(t, 'rightLeg', _rightLegStart, audio.playEggCrack);
    _soundGuard.maybeAt(
      t,
      'torso',
      _torsoStartMs,
      () => audio.playSfx(Sfx.guardianShatter),
    );
    _soundGuard.maybeAt(t, 'burst', _burstEndMs, audio.playEggCrack);
  }

  double _stageProgress(double start, double end) =>
      Curves.easeIn.transform(_phase(start, end));

  double _preBreakShakeBoost(double t, double stageStart) {
    if (t < stageStart - 220 || t >= stageStart + 80) return 0;
    final ramp = _phase(stageStart - 220, stageStart);
    return ramp * 14;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _timeMs();
        _playPhaseSounds(t);
        final zoomPhase = Curves.easeOutCubic.transform(_phase(0, 1000));
        final zoomScale = 0.86 + zoomPhase * 0.52;
        final darken = (0.28 + zoomPhase * 0.32).clamp(0.0, 0.62);

        final buildUp = _phase(1000, 3000);
        final crackSpread = Curves.easeIn.transform(
          _phase(1000, _torsoStartMs),
        );

        final leftArmBreak = _stageProgress(_leftArmStart, _leftArmEnd);
        final rightArmBreak = _stageProgress(_rightArmStart, _rightArmEnd);
        final leftLegBreak = _stageProgress(_leftLegStart, _leftLegEnd);
        final rightLegBreak = _stageProgress(_rightLegStart, _rightLegEnd);
        final torsoBurst = Curves.easeIn.transform(
          _phase(_torsoStartMs, _burstEndMs),
        );

        final stageShake =
            _preBreakShakeBoost(t, _leftArmStart) +
            _preBreakShakeBoost(t, _rightArmStart) +
            _preBreakShakeBoost(t, _leftLegStart) +
            _preBreakShakeBoost(t, _rightLegStart) +
            _preBreakShakeBoost(t, _torsoStartMs) * 1.4;

        final baseShake = 3 + buildUp * 5 + crackSpread * 10;
        final shakeAmp = baseShake + stageShake + torsoBurst * 18;
        final shakeX = t >= 1000 && t < _burstEndMs
            ? math.sin(t / 48 * math.pi) * shakeAmp
            : 0.0;
        final shakeY = t >= 1000 && t < _burstEndMs
            ? math.cos(t / 56 * math.pi) * shakeAmp * 0.5
            : 0.0;

        final bossScale = zoomScale * _sizeBoost;
        final showBoss = t < _torsoStartMs + 350;
        final bossOpacity = t < _torsoStartMs
            ? 1.0
            : (1 - _phase(_torsoStartMs, _torsoStartMs + 350)).clamp(0.0, 1.0);

        final glowPulse = t >= 1000 && t < _burstEndMs
            ? (0.35 + math.sin(t / 75 * math.pi) * 0.3) * crackSpread
            : 0.0;

        final runeRing = t >= 1000
            ? (0.3 + math.sin(t / 90 * math.pi) * 0.25) * crackSpread
            : 0.0;
        final energyLeak = _phase(3000, _torsoStartMs);

        final torsoFragmentTravel = t >= _torsoStartMs
            ? Curves.easeOutCubic.transform(
                _phase(_torsoStartMs, _burstEndMs + 600),
              )
            : 0.0;
        final shockwave = t >= _torsoStartMs
            ? Curves.easeOut.transform(_phase(_torsoStartMs, _burstEndMs + 400))
            : 0.0;

        final burstFlash = t >= _torsoStartMs
            ? (1 - _phase(_torsoStartMs, _torsoStartMs + 450)).clamp(0.0, 1.0)
            : 0.0;
        final effectFade = (1 - _phase(9400, 11200)).clamp(0.0, 1.0);

        final pieceSparkIntensity = [
          if (leftArmBreak > 0 && leftArmBreak < 0.35) leftArmBreak * 2.8,
          if (rightArmBreak > 0 && rightArmBreak < 0.35) rightArmBreak * 2.8,
          if (leftLegBreak > 0 && leftLegBreak < 0.35) leftLegBreak * 2.5,
          if (rightLegBreak > 0 && rightLegBreak < 0.35) rightLegBreak * 2.5,
        ].fold(0.0, math.max);

        final energyIntensity = math.max(
          energyLeak * 0.55 + pieceSparkIntensity * 0.35,
          torsoBurst,
        );

        final titleProgress = Curves.elasticOut.transform(_phase(9400, 10000));
        final titleOpacity = Curves.easeOut.transform(_phase(9400, 9800));
        final rewardsOpacity = Curves.easeOut.transform(_phase(9800, 11000));
        final rewardsSlide = (1 - rewardsOpacity) * 28;

        return Material(
          color: Colors.black.withValues(alpha: 0.82),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: t >= _skipAfterMs && !_completed ? _trySkip : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const EggGuardianCinematicBackground(),
                ColoredBox(color: Colors.black.withValues(alpha: darken)),
                if (runeRing > 0)
                  CustomPaint(
                    painter: _GuardianRuneRingPainter(
                      intensity: runeRing,
                      shockwave: shockwave,
                      fade: effectFade,
                    ),
                  ),
                if (showBoss && bossOpacity > 0)
                  Transform.translate(
                    offset: Offset(shakeX, shakeY),
                    child: Transform.scale(
                      scale: bossScale,
                      child: Opacity(
                        opacity: bossOpacity,
                        child: SizedBox(
                          width: _baseSpriteSize,
                          height: _baseSpriteSize * 1.12,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              if (glowPulse > 0)
                                Container(
                                  width: _baseSpriteSize * 1.2,
                                  height: _baseSpriteSize * 1.2,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF42A5F5,
                                        ).withValues(alpha: glowPulse * 0.5),
                                        blurRadius: 36,
                                        spreadRadius: 8,
                                      ),
                                      BoxShadow(
                                        color: const Color(
                                          0xFFFFD54F,
                                        ).withValues(alpha: glowPulse * 0.25),
                                        blurRadius: 24,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              BossSprite(
                                spritePath: widget.boss.spritePath,
                                fallbackEmoji: widget.boss.emoji,
                                bossId: widget.boss.id,
                                size: _baseSpriteSize,
                                semanticLabel: widget.boss.name,
                              ),
                              CustomPaint(
                                size: Size(
                                  _baseSpriteSize,
                                  _baseSpriteSize * 1.12,
                                ),
                                painter: _GuardianCrackOverlayPainter(
                                  progress: crackSpread,
                                  energy: energyLeak,
                                ),
                              ),
                              if (leftArmBreak > 0.04)
                                Positioned(
                                  left: 2,
                                  top: _baseSpriteSize * 0.26,
                                  child: _BodyCoverPatch(
                                    width: 34,
                                    height: 50,
                                    opacity: (leftArmBreak * 2.5).clamp(
                                      0.0,
                                      1.0,
                                    ),
                                  ),
                                ),
                              if (rightArmBreak > 0.04)
                                Positioned(
                                  right: 2,
                                  top: _baseSpriteSize * 0.26,
                                  child: _BodyCoverPatch(
                                    width: 34,
                                    height: 50,
                                    opacity: (rightArmBreak * 2.5).clamp(
                                      0.0,
                                      1.0,
                                    ),
                                  ),
                                ),
                              if (leftLegBreak > 0.04)
                                Positioned(
                                  left: 24,
                                  bottom: 4,
                                  child: _BodyCoverPatch(
                                    width: 30,
                                    height: 38,
                                    opacity: (leftLegBreak * 2.5).clamp(
                                      0.0,
                                      1.0,
                                    ),
                                  ),
                                ),
                              if (rightLegBreak > 0.04)
                                Positioned(
                                  right: 24,
                                  bottom: 4,
                                  child: _BodyCoverPatch(
                                    width: 30,
                                    height: 38,
                                    opacity: (rightLegBreak * 2.5).clamp(
                                      0.0,
                                      1.0,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Transform.translate(
                  offset: Offset(shakeX, shakeY),
                  child: CustomPaint(
                    painter: _StagedBodyBreakPainter(
                      leftArm: leftArmBreak,
                      rightArm: rightArmBreak,
                      leftLeg: leftLegBreak,
                      rightLeg: rightLegBreak,
                      torsoBurst: torsoBurst,
                      fragments: _fragments,
                      torsoFragmentTravel: torsoFragmentTravel,
                      bossScale: bossScale,
                      fade: effectFade,
                    ),
                  ),
                ),
                if (pieceSparkIntensity > 0 || torsoBurst > 0)
                  Transform.translate(
                    offset: Offset(shakeX, shakeY),
                    child: CustomPaint(
                      painter: _FractureSparkPainter(
                        leftArm: leftArmBreak,
                        rightArm: rightArmBreak,
                        leftLeg: leftLegBreak,
                        rightLeg: rightLegBreak,
                        torsoBurst: torsoBurst,
                        bossScale: bossScale,
                        fade: effectFade,
                        timeMs: t,
                      ),
                    ),
                  ),
                if (burstFlash > 0)
                  ColoredBox(
                    color: const Color(
                      0xFF81D4FA,
                    ).withValues(alpha: burstFlash * 0.42),
                  ),
                if (burstFlash > 0)
                  ColoredBox(
                    color: const Color(
                      0xFFFFF8E1,
                    ).withValues(alpha: burstFlash * 0.18),
                  ),
                if (energyIntensity > 0)
                  Transform.translate(
                    offset: Offset(shakeX, shakeY),
                    child: CustomPaint(
                      painter: _GuardianEnergyBurstPainter(
                        intensity: energyIntensity,
                        shockwave: shockwave,
                        fade: effectFade,
                        timeMs: t,
                        isTorsoBurst: torsoBurst > 0.2,
                      ),
                    ),
                  ),
                BossCinematicVictoryOverlay(
                  theme: widget.theme,
                  bossName: widget.boss.name,
                  defeatTitle: 'GUARDIAN SHATTERED!',
                  coinReward: widget.coinReward,
                  tokenReward: widget.tokenReward,
                  animalRewardName: widget.animalRewardName,
                  titleProgress: titleProgress,
                  titleOpacity: titleOpacity,
                  rewardsOpacity: rewardsOpacity,
                  rewardsSlide: rewardsSlide,
                  canSkip: t >= _skipAfterMs && !_completed,
                  onSkip: _trySkip,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BodyCoverPatch extends StatelessWidget {
  const _BodyCoverPatch({
    required this.width,
    required this.height,
    required this.opacity,
  });

  final double width;
  final double height;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF78909C), Color(0xFF455A64)],
          ),
          border: Border.all(
            color: const Color(0xFF42A5F5).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _GuardianCrackOverlayPainter extends CustomPainter {
  _GuardianCrackOverlayPainter({required this.progress, required this.energy});

  final double progress;
  final double energy;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final cx = size.width / 2;
    final cy = size.height * 0.52;

    final glow = Paint()
      ..color = Color.lerp(
        const Color(0xFF42A5F5),
        const Color(0xFFFFD54F),
        energy * 0.5,
      )!.withValues(alpha: progress * 0.8)
      ..strokeWidth = 2.5 + progress * 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final crack = Paint()
      ..color = const Color(0xFFECEFF1).withValues(alpha: 0.9)
      ..strokeWidth = 2 + progress * 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 6; i++) {
      final angle = -math.pi / 2 + i * math.pi / 3;
      final len = 20 + progress * 38;
      final end = Offset(
        cx + math.cos(angle) * len,
        cy + math.sin(angle) * len,
      );
      final mid = Offset.lerp(Offset(cx, cy), end, progress * 0.6)!;
      canvas.drawLine(Offset(cx, cy), mid, crack);
      canvas.drawLine(mid, end, glow);
    }
  }

  @override
  bool shouldRepaint(covariant _GuardianCrackOverlayPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.energy != energy;
}

class _GuardianRuneRingPainter extends CustomPainter {
  _GuardianRuneRingPainter({
    required this.intensity,
    required this.shockwave,
    required this.fade,
  });

  final double intensity;
  final double shockwave;
  final double fade;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.72);
    final maxDim = math.max(size.width, size.height);

    final ringPaint = Paint()
      ..color = const Color(
        0xFF64B5F6,
      ).withValues(alpha: intensity * fade * 0.5)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: maxDim * 0.34 * (1 + shockwave * 0.35),
        height: maxDim * 0.06 * (1 + shockwave * 0.35),
      ),
      ringPaint,
    );

    if (shockwave > 0) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: maxDim * (0.2 + shockwave * 0.45),
          height: maxDim * (0.04 + shockwave * 0.08),
        ),
        Paint()
          ..color = const Color(
            0xFFFFD54F,
          ).withValues(alpha: fade * shockwave * 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GuardianRuneRingPainter oldDelegate) =>
      oldDelegate.intensity != intensity ||
      oldDelegate.shockwave != shockwave ||
      oldDelegate.fade != fade;
}

class _ShellFragment {
  _ShellFragment({
    required this.angle,
    required this.distance,
    required this.size,
    required this.rotation,
    required this.delay,
  });

  final double angle;
  final double distance;
  final double size;
  final double rotation;
  final double delay;

  static List<_ShellFragment> generate(int count) {
    final random = math.Random(66);
    return List.generate(count, (i) {
      return _ShellFragment(
        angle: random.nextDouble() * math.pi * 2,
        distance: 0.14 + random.nextDouble() * 0.48,
        size: 6 + random.nextDouble() * 14,
        rotation: random.nextDouble() * math.pi,
        delay: random.nextDouble() * 0.28,
      );
    });
  }
}

class _StagedBodyBreakPainter extends CustomPainter {
  _StagedBodyBreakPainter({
    required this.leftArm,
    required this.rightArm,
    required this.leftLeg,
    required this.rightLeg,
    required this.torsoBurst,
    required this.fragments,
    required this.torsoFragmentTravel,
    required this.bossScale,
    required this.fade,
  });

  final double leftArm;
  final double rightArm;
  final double leftLeg;
  final double rightLeg;
  final double torsoBurst;
  final List<_ShellFragment> fragments;
  final double torsoFragmentTravel;
  final double bossScale;
  final double fade;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.5);
    final maxDim = math.max(size.width, size.height);
    final s = bossScale;

    _drawLimb(
      canvas,
      attach: center + Offset(-54 * s, -6 * s),
      progress: leftArm,
      width: 32,
      height: 52,
      fallDir: -1,
      isArm: true,
    );
    _drawLimb(
      canvas,
      attach: center + Offset(54 * s, -6 * s),
      progress: rightArm,
      width: 32,
      height: 52,
      fallDir: 1,
      isArm: true,
    );
    _drawLimb(
      canvas,
      attach: center + Offset(-36 * s, 48 * s),
      progress: leftLeg,
      width: 28,
      height: 36,
      fallDir: -1,
      isArm: false,
    );
    _drawLimb(
      canvas,
      attach: center + Offset(36 * s, 48 * s),
      progress: rightLeg,
      width: 28,
      height: 36,
      fallDir: 1,
      isArm: false,
    );

    if (torsoBurst > 0) {
      _drawTorsoPlates(canvas, center, torsoBurst, s, fade);
    }

    for (final f in fragments) {
      if (torsoFragmentTravel <= 0) continue;
      final localT = ((torsoFragmentTravel - f.delay) / (1 - f.delay)).clamp(
        0.0,
        1.0,
      );
      if (localT <= 0) continue;
      final eased = Curves.easeOutCubic.transform(localT);
      final burstBoost = torsoBurst * 0.65;
      final dist = f.distance * maxDim * (eased + burstBoost);
      final gravity = eased * eased * maxDim * 0.12;
      final pos =
          center +
          Offset(
            math.cos(f.angle) * dist,
            math.sin(f.angle) * dist * 0.48 + gravity,
          );
      final alpha = (fade * (1 - localT * 0.15)).clamp(0.0, 1.0);
      if (alpha <= 0) continue;

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(f.rotation + eased * math.pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: f.size,
            height: f.size * 0.75,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFFECEFF1).withValues(alpha: alpha * 0.9),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: f.size,
            height: f.size * 0.75,
          ),
          const Radius.circular(3),
        ),
        Paint()
          ..color = const Color(0xFF42A5F5).withValues(alpha: alpha * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      canvas.restore();
    }

    if (torsoBurst > 0) {
      final dustAlpha = (fade * torsoBurst * 0.38).clamp(0.0, 1.0);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + size.height * 0.1),
          width: 90 + torsoBurst * maxDim * 0.42,
          height: 36 + torsoBurst * maxDim * 0.12,
        ),
        Paint()..color = const Color(0xFF90CAF9).withValues(alpha: dustAlpha),
      );
    }
  }

  void _drawLimb(
    Canvas canvas, {
    required Offset attach,
    required double progress,
    required double width,
    required double height,
    required int fallDir,
    required bool isArm,
  }) {
    if (progress <= 0) return;
    final eased = Curves.easeIn.transform(progress);
    final fallX = attach.dx + fallDir * eased * (isArm ? 78 : 52);
    final fallY = attach.dy + eased * eased * (isArm ? 105 : 88);
    final rotation = fallDir * eased * (isArm ? 1.15 : 0.85);
    final alpha = (fade * (1 - eased * 0.08)).clamp(0.0, 1.0);

    canvas.save();
    canvas.translate(fallX, fallY);
    canvas.rotate(rotation);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: width, height: height),
        Radius.circular(isArm ? 8 : 6),
      ),
      Paint()..color = const Color(0xFF607D8B).withValues(alpha: alpha * 0.94),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: width, height: height),
        Radius.circular(isArm ? 8 : 6),
      ),
      Paint()
        ..color = const Color(0xFF42A5F5).withValues(alpha: alpha * 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, isArm ? height * 0.15 : -height * 0.1),
          width: width * 0.85,
          height: 6,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFFFD54F).withValues(alpha: alpha * 0.5),
    );

    if (progress > 0.12) {
      for (var i = 0; i < 3; i++) {
        final chipT = (progress - i * 0.06).clamp(0.0, 1.0);
        if (chipT <= 0) continue;
        final cx = attach.dx + fallDir * Curves.easeIn.transform(chipT) * 45;
        final cy =
            attach.dy +
            Curves.easeIn.transform(chipT) *
                Curves.easeIn.transform(chipT) *
                70;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: 7, height: 5),
            const Radius.circular(2),
          ),
          Paint()
            ..color = const Color(0xFFECEFF1).withValues(alpha: fade * 0.65),
        );
      }
    }

    canvas.restore();

    if (progress > 0.78) {
      final landT = ((progress - 0.78) / 0.22).clamp(0.0, 1.0);
      final land = Offset(fallX, fallY + height * 0.45);
      canvas.drawOval(
        Rect.fromCenter(
          center: land,
          width: 28 + landT * 18,
          height: 12 + landT * 8,
        ),
        Paint()
          ..color = const Color(
            0xFFBCAAA4,
          ).withValues(alpha: fade * landT * 0.45),
      );
    }
  }

  void _drawTorsoPlates(
    Canvas canvas,
    Offset center,
    double burst,
    double s,
    double fade,
  ) {
    final plates = [
      (Offset(-22 * s, -18 * s), 38.0, 28.0, -0.8),
      (Offset(22 * s, -14 * s), 36.0, 26.0, 0.9),
      (Offset(0, 8 * s), 44.0, 34.0, 0.2),
      (Offset(-12 * s, 22 * s), 30.0, 22.0, -1.1),
      (Offset(14 * s, 20 * s), 28.0, 20.0, 1.0),
    ];
    for (final (offset, w, h, rotDir) in plates) {
      final eased = Curves.easeOut.transform(burst);
      final pos =
          center + offset + Offset(rotDir * eased * 55, eased * eased * 70);
      final alpha = (fade * (1 - eased * 0.12)).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(rotDir * eased * math.pi * 0.8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(5),
        ),
        Paint()
          ..color = const Color(0xFFECEFF1).withValues(alpha: alpha * 0.92),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(5),
        ),
        Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: alpha * 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _StagedBodyBreakPainter oldDelegate) =>
      oldDelegate.leftArm != leftArm ||
      oldDelegate.rightArm != rightArm ||
      oldDelegate.leftLeg != leftLeg ||
      oldDelegate.rightLeg != rightLeg ||
      oldDelegate.torsoBurst != torsoBurst ||
      oldDelegate.torsoFragmentTravel != torsoFragmentTravel ||
      oldDelegate.fade != fade;
}

class _FractureSparkPainter extends CustomPainter {
  _FractureSparkPainter({
    required this.leftArm,
    required this.rightArm,
    required this.leftLeg,
    required this.rightLeg,
    required this.torsoBurst,
    required this.bossScale,
    required this.fade,
    required this.timeMs,
  });

  final double leftArm;
  final double rightArm;
  final double leftLeg;
  final double rightLeg;
  final double torsoBurst;
  final double bossScale;
  final double fade;
  final double timeMs;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.5);
    final s = bossScale;

    _sparkAt(canvas, center + Offset(-54 * s, -6 * s), leftArm);
    _sparkAt(canvas, center + Offset(54 * s, -6 * s), rightArm);
    _sparkAt(canvas, center + Offset(-36 * s, 48 * s), leftLeg);
    _sparkAt(canvas, center + Offset(36 * s, 48 * s), rightLeg);

    if (torsoBurst > 0.05 && torsoBurst < 0.5) {
      final alpha = (fade * torsoBurst * 0.7).clamp(0.0, 0.65);
      canvas.drawCircle(
        center,
        20 + torsoBurst * 40,
        Paint()
          ..color = const Color(0xFF81D4FA).withValues(alpha: alpha * 0.35),
      );
    }
  }

  void _sparkAt(Canvas canvas, Offset point, double progress) {
    if (progress <= 0 || progress > 0.45) return;
    final flash = (1 - progress / 0.45).clamp(0.0, 1.0);
    final alpha = (fade * flash * 0.85).clamp(0.0, 1.0);

    canvas.drawCircle(
      point,
      10 + flash * 14,
      Paint()..color = const Color(0xFF42A5F5).withValues(alpha: alpha * 0.35),
    );
    canvas.drawCircle(
      point,
      4 + flash * 6,
      Paint()..color = const Color(0xFFFFEB3B).withValues(alpha: alpha),
    );

    final bolt = Paint()
      ..color = const Color(0xFFE1F5FE).withValues(alpha: alpha * 0.9)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(point, point + const Offset(-12, -18), bolt);
    canvas.drawLine(point, point + const Offset(10, -14), bolt);
  }

  @override
  bool shouldRepaint(covariant _FractureSparkPainter oldDelegate) =>
      oldDelegate.leftArm != leftArm ||
      oldDelegate.rightArm != rightArm ||
      oldDelegate.leftLeg != leftLeg ||
      oldDelegate.rightLeg != rightLeg ||
      oldDelegate.torsoBurst != torsoBurst ||
      oldDelegate.fade != fade;
}

class _GuardianEnergyBurstPainter extends CustomPainter {
  _GuardianEnergyBurstPainter({
    required this.intensity,
    required this.shockwave,
    required this.fade,
    required this.timeMs,
    this.isTorsoBurst = false,
  });

  final double intensity;
  final double shockwave;
  final double fade;
  final double timeMs;
  final bool isTorsoBurst;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0 && shockwave <= 0) return;
    final center = Offset(size.width / 2, size.height * 0.5);
    final cap = isTorsoBurst ? 0.75 : 0.45;
    final alpha = (intensity * fade).clamp(0.0, cap);

    if (isTorsoBurst) {
      final glow = Paint()
        ..color = const Color(0xFF42A5F5).withValues(alpha: alpha * 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawCircle(center, 40 + intensity * 55, glow);
    }

    final bolts = isTorsoBurst
        ? [
            _energyBolt(
              center,
              const Offset(-70, -50),
              const Offset(-20, 10),
              4,
            ),
            _energyBolt(center, const Offset(65, -45), const Offset(18, 15), 5),
            _energyBolt(center, const Offset(-30, 70), const Offset(5, 0), 4),
            _energyBolt(center, const Offset(40, 65), const Offset(-8, 5), 4),
          ]
        : <Path>[];

    final outer = Paint()
      ..color = const Color(0xFF0288D1).withValues(alpha: alpha * 0.85)
      ..strokeWidth = isTorsoBurst ? 3.0 : 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final core = Paint()
      ..color = const Color(0xFFFFF8E1).withValues(alpha: alpha)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (isTorsoBurst) {
      final pulse = math.sin(timeMs / 160 * math.pi);
      for (var i = 0; i < bolts.length; i++) {
        if (pulse < 0 && i.isEven) continue;
        canvas.drawPath(bolts[i], outer);
        canvas.drawPath(bolts[i], core);
      }

      for (var i = 0; i < 6; i++) {
        final angle = i * math.pi / 3 + timeMs * 0.015;
        final dist = 35 + intensity * 45;
        canvas.drawCircle(
          center + Offset(math.cos(angle) * dist, math.sin(angle) * dist),
          2 + intensity * 2,
          Paint()
            ..color = const Color(0xFFFFD54F).withValues(alpha: alpha * 0.8),
        );
      }
    }
  }

  Path _energyBolt(Offset start, Offset mid, Offset end, int segments) {
    final path = Path()..moveTo(start.dx, start.dy);
    var current = start;
    for (final target in [mid, end]) {
      for (var i = 1; i <= segments; i++) {
        final t = i / segments;
        final base = Offset.lerp(current, target, t)!;
        final jag = (i.isOdd ? 1 : -1) * (5 + i * 2);
        path.lineTo(base.dx + jag, base.dy + jag * 0.5);
      }
      current = target;
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _GuardianEnergyBurstPainter oldDelegate) =>
      oldDelegate.intensity != intensity ||
      oldDelegate.shockwave != shockwave ||
      oldDelegate.fade != fade ||
      oldDelegate.timeMs != timeMs ||
      oldDelegate.isTorsoBurst != isTorsoBurst;
}
