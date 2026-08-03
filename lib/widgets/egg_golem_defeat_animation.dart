import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/audio_assets.dart';
import '../models/background_theme.dart';
import '../utils/cinematic_sound_guard.dart';
import 'audio_scope.dart';
import '../models/boss_battle.dart';
import 'boss_cinematic_ui.dart';
import 'boss_sprite.dart';
import 'egg_golem_cave_background.dart';

/// Cinematic Egg Golem defeat celebration for manual battle victories.
class EggGolemDefeatAnimation extends StatefulWidget {
  const EggGolemDefeatAnimation({
    super.key,
    required this.theme,
    required this.boss,
    required this.coinReward,
    required this.tokenReward,
    this.animalRewardName,
    required this.onComplete,
  });

  static const duration = Duration(milliseconds: 10500);

  final BackgroundTheme theme;
  final BossBattleDefinition boss;
  final int coinReward;
  final int tokenReward;
  final String? animalRewardName;
  final VoidCallback onComplete;

  @override
  State<EggGolemDefeatAnimation> createState() =>
      _EggGolemDefeatAnimationState();
}

class _EggGolemDefeatAnimationState extends State<EggGolemDefeatAnimation>
    with SingleTickerProviderStateMixin {
  static const _totalMs = 10500.0;
  static const _skipAfterMs = 1000.0;
  static const _armDetachStartMs = 6200.0;
  static const _collapseStartMs = 6500.0;
  static const _burstEndMs = 8500.0;
  static const _lightningStartMs = 6500.0;
  static const _lightningEndMs = 7700.0;
  static const _baseSpriteSize = 158.0;
  static const _sizeBoost = 1.32;

  late final AnimationController _controller;
  late final List<_RockChunk> _chunks;
  late final CinematicSoundGuard _soundGuard;
  var _completed = false;

  @override
  void initState() {
    super.initState();
    _chunks = _RockChunk.generate(30);
    _soundGuard = CinematicSoundGuard();
    _controller = AnimationController(
      vsync: this,
      duration: EggGolemDefeatAnimation.duration,
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
    _soundGuard.maybeAt(t, 'crackSpread', 1000, audio.playEggCrack);
    _soundGuard.maybeAt(t, 'crackDeep', 3500, audio.playEggCrack);
    _soundGuard.maybeAt(t, 'armDetach', _armDetachStartMs, audio.playEggCrack);
    _soundGuard.maybeAt(
      t,
      'collapseImpact',
      _collapseStartMs + 150,
      () => audio.playSfx(Sfx.golemCrack),
    );
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
        final darken = (0.28 + zoomPhase * 0.32).clamp(0.0, 0.65);

        final tremblePhase = _phase(1000, 3500);
        final crackSpread = Curves.easeIn.transform(_phase(1000, 6500));
        final collapsePhase = Curves.easeIn.transform(_phase(_collapseStartMs, _burstEndMs));

        final shakeAmp = 4 + tremblePhase * 10 + crackSpread * 14 + collapsePhase * 6;
        final shakeX = t >= 1000 && t < _burstEndMs
            ? math.sin(t / 45 * math.pi) * shakeAmp
            : 0.0;
        final shakeY = t >= 1000 && t < _burstEndMs
            ? math.cos(t / 52 * math.pi) * shakeAmp * 0.55
            : 0.0;

        final bossScale = zoomScale * _sizeBoost * (1 + crackSpread * 0.08);
        final showBoss = t < _collapseStartMs;
        final glowFlash = t >= 3500 && t < _collapseStartMs
            ? (0.35 + math.sin(t / 80 * math.pi) * 0.25) * crackSpread
            : 0.0;
        final collapseFlash = t >= _collapseStartMs
            ? (1 - _phase(_collapseStartMs, _collapseStartMs + 320)).clamp(0.0, 1.0)
            : 0.0;

        final leftArmProgress =
            Curves.easeIn.transform(_phase(_armDetachStartMs, 7800));
        final rightArmProgress = Curves.easeIn.transform(
          _phase(_armDetachStartMs + 120, 7900),
        );
        final armsDetached = t >= _armDetachStartMs;

        final lightningWindow = t >= _lightningStartMs && t < _lightningEndMs;
        final lightningPulse = lightningWindow
            ? (0.45 +
                    math.sin((t - _lightningStartMs) / 180 * math.pi) * 0.35 +
                    math.sin((t - _lightningStartMs) / 95 * math.pi) * 0.2)
                .clamp(0.0, 1.0)
            : 0.0;
        final electricFlash = lightningWindow
            ? (math.sin((t - _lightningStartMs) / 220 * math.pi).abs() * 0.22)
                .clamp(0.0, 0.22)
            : 0.0;

        final chipTravel = t >= 3500
            ? Curves.easeOutCubic.transform(_phase(3500, _burstEndMs))
            : 0.0;
        final dustExpand = t >= _collapseStartMs
            ? Curves.easeOut.transform(_phase(_collapseStartMs, _burstEndMs))
            : 0.0;
        final effectFade = (1 - _phase(8800, 10200)).clamp(0.0, 1.0);

        final titleProgress = Curves.elasticOut.transform(_phase(8800, 9400));
        final titleOpacity = Curves.easeOut.transform(_phase(8800, 9200));
        final rewardsOpacity = Curves.easeOut.transform(_phase(9200, 10200));
        final rewardsSlide = (1 - rewardsOpacity) * 28;

        return Material(
          color: Colors.black.withValues(alpha: 0.82),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: t >= _skipAfterMs && !_completed ? _trySkip : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const EggGolemCaveBackground(),
                ColoredBox(color: Colors.black.withValues(alpha: darken)),
                if (showBoss)
                  Transform.translate(
                    offset: Offset(shakeX, shakeY),
                    child: Transform.scale(
                      scale: bossScale,
                      child: SizedBox(
                        width: _baseSpriteSize,
                        height: _baseSpriteSize * 1.15,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                          if (glowFlash > 0)
                            Container(
                              width: _baseSpriteSize * 1.15,
                              height: _baseSpriteSize * 1.15,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFF8E1)
                                        .withValues(alpha: glowFlash * 0.55),
                                    blurRadius: 32,
                                    spreadRadius: 8,
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
                          if (armsDetached) ...[
                            Positioned(
                              left: 4,
                              top: _baseSpriteSize * 0.36,
                              child: _ArmCoverPatch(
                                width: 30,
                                height: 50,
                                opacity: leftArmProgress.clamp(0.0, 1.0),
                              ),
                            ),
                            Positioned(
                              right: 4,
                              top: _baseSpriteSize * 0.36,
                              child: _ArmCoverPatch(
                                width: 30,
                                height: 50,
                                opacity: rightArmProgress.clamp(0.0, 1.0),
                              ),
                            ),
                          ],
                          CustomPaint(
                            size: Size(_baseSpriteSize, _baseSpriteSize * 1.15),
                            painter: _GolemCrackOverlayPainter(
                              progress: crackSpread,
                              sparkIntensity: lightningPulse * 0.6,
                            ),
                          ),
                        ],
                        ),
                      ),
                    ),
                  ),
                if (armsDetached)
                  Transform.translate(
                    offset: Offset(shakeX, shakeY),
                    child: CustomPaint(
                      painter: _GolemFallingArmsPainter(
                        leftProgress: leftArmProgress,
                        rightProgress: rightArmProgress,
                        bossScale: bossScale,
                        fade: effectFade,
                      ),
                    ),
                  ),
                if (collapseFlash > 0)
                  ColoredBox(
                    color: const Color(0xFFFFF8E1).withValues(alpha: collapseFlash * 0.55),
                  ),
                if (electricFlash > 0)
                  ColoredBox(
                    color: const Color(0xFFB3E5FC).withValues(alpha: electricFlash),
                  ),
                Transform.translate(
                  offset: Offset(shakeX, shakeY),
                  child: CustomPaint(
                    painter: _GolemDebrisPainter(
                      chunks: _chunks,
                      travel: chipTravel,
                      dust: dustExpand,
                      fade: effectFade,
                      armDustLeft: leftArmProgress,
                      armDustRight: rightArmProgress,
                    ),
                  ),
                ),
                if (lightningPulse > 0)
                  Transform.translate(
                    offset: Offset(shakeX, shakeY),
                    child: CustomPaint(
                      painter: _GolemLightningPainter(
                        intensity: lightningPulse,
                        fade: effectFade,
                        timeMs: t - _lightningStartMs,
                      ),
                    ),
                  ),
                BossCinematicVictoryOverlay(
                  theme: widget.theme,
                  bossName: widget.boss.name,
                  defeatTitle: 'GOLEM CRUMBLED!',
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

class _GolemCrackOverlayPainter extends CustomPainter {
  _GolemCrackOverlayPainter({
    required this.progress,
    this.sparkIntensity = 0,
  });

  final double progress;
  final double sparkIntensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final glow = Paint()
      ..color = const Color(0xFFFFF59D).withValues(alpha: progress * 0.75)
      ..strokeWidth = 2.5 + progress * 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final crack = Paint()
      ..color = const Color(0xFFBCAAA4).withValues(alpha: 0.85 + progress * 0.15)
      ..strokeWidth = 2 + progress * 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height * 0.52;
    final lines = [
      [Offset(cx - 20, cy - 40), Offset(cx - 4, cy - 8), Offset(cx + 8, cy + 18)],
      [Offset(cx + 18, cy - 36), Offset(cx + 6, cy + 2), Offset(cx - 12, cy + 28)],
      [Offset(cx, cy - 44), Offset(cx + 14, cy - 10), Offset(cx + 22, cy + 24)],
      [Offset(cx - 14, cy + 6), Offset(cx + 2, cy + 22), Offset(cx + 18, cy + 38)],
    ];

    for (final pts in lines) {
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (var i = 1; i < pts.length; i++) {
        final p = Offset.lerp(pts[0], pts[i], progress)!;
        if (i == 1) {
          path.lineTo(p.dx, p.dy);
        } else {
          final prev = Offset.lerp(pts[0], pts[i - 1], progress)!;
          path.lineTo(prev.dx, prev.dy);
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, crack);
      canvas.drawPath(path, glow);
    }

    if (sparkIntensity > 0 && progress > 0.4) {
      final spark = Paint()
        ..color = const Color(0xFF81D4FA).withValues(alpha: sparkIntensity * 0.85)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(cx - 8, cy - 12),
        Offset(cx - 2, cy - 4),
        spark,
      );
      canvas.drawLine(
        Offset(cx + 10, cy + 4),
        Offset(cx + 16, cy + 14),
        spark,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GolemCrackOverlayPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.sparkIntensity != sparkIntensity;
}

class _ArmCoverPatch extends StatelessWidget {
  const _ArmCoverPatch({
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
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF8D6E63).withValues(alpha: 0.92),
              const Color(0xFF6D4C41).withValues(alpha: 0.95),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

class _GolemFallingArmsPainter extends CustomPainter {
  _GolemFallingArmsPainter({
    required this.leftProgress,
    required this.rightProgress,
    required this.bossScale,
    required this.fade,
  });

  final double leftProgress;
  final double rightProgress;
  final double bossScale;
  final double fade;

  static const _armOffsetX = 54.0;
  static const _armOffsetY = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.5;
    final scale = bossScale;
    _drawArm(
      canvas,
      attach: Offset(cx - _armOffsetX * scale, cy + _armOffsetY * scale),
      progress: leftProgress,
      fallDir: -1,
      fade: fade,
    );
    _drawArm(
      canvas,
      attach: Offset(cx + _armOffsetX * scale, cy + _armOffsetY * scale),
      progress: rightProgress,
      fallDir: 1,
      fade: fade,
    );
  }

  void _drawArm(
    Canvas canvas, {
    required Offset attach,
    required double progress,
    required int fallDir,
    required double fade,
  }) {
    if (progress <= 0) return;
    final eased = Curves.easeIn.transform(progress);
    final fallX = attach.dx + fallDir * eased * 72;
    final fallY = attach.dy + eased * eased * 95;
    final rotation = fallDir * eased * 1.1;

    canvas.save();
    canvas.translate(fallX, fallY);
    canvas.rotate(rotation);

    final armW = 26.0;
    final armH = 48.0;
    final body = Paint()..color = const Color(0xFF8D6E63).withValues(alpha: fade * 0.95);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: armW, height: armH),
        const Radius.circular(8),
      ),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: armW, height: armH),
        const Radius.circular(8),
      ),
      Paint()
        ..color = const Color(0xFFBCAAA4).withValues(alpha: fade * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Hand / fist chunk
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, armH * 0.42),
          width: armW * 0.9,
          height: 14,
        ),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF6D4C41).withValues(alpha: fade * 0.9),
    );

    canvas.restore();

    // Rubble chips trailing the arm
    if (progress > 0.15) {
      for (var i = 0; i < 3; i++) {
        final chipT = (progress - i * 0.08).clamp(0.0, 1.0);
        if (chipT <= 0) continue;
        final chipX = attach.dx + fallDir * Curves.easeIn.transform(chipT) * 60;
        final chipY = attach.dy + Curves.easeIn.transform(chipT) * Curves.easeIn.transform(chipT) * 80;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(chipX, chipY), width: 8, height: 6),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFF795548).withValues(alpha: fade * 0.7),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GolemFallingArmsPainter oldDelegate) =>
      oldDelegate.leftProgress != leftProgress ||
      oldDelegate.rightProgress != rightProgress ||
      oldDelegate.bossScale != bossScale ||
      oldDelegate.fade != fade;
}

class _GolemLightningPainter extends CustomPainter {
  _GolemLightningPainter({
    required this.intensity,
    required this.fade,
    required this.timeMs,
  });

  final double intensity;
  final double fade;
  final double timeMs;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0) return;
    final center = Offset(size.width / 2, size.height * 0.5);
    final alpha = (intensity * fade).clamp(0.0, 0.85);

    final glow = Paint()
      ..color = const Color(0xFF81D4FA).withValues(alpha: alpha * 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(center, 48 + intensity * 40, glow);

    final bolts = [
      _boltPath(center, const Offset(-90, -70), const Offset(-30, 20), 5),
      _boltPath(center, const Offset(80, -60), const Offset(25, 30), 6),
      _boltPath(center, const Offset(-40, 80), const Offset(10, -10), 4),
      _boltPath(center, const Offset(50, 75), const Offset(-15, -5), 5),
      _boltPath(center, const Offset(0, -95), const Offset(5, 15), 4),
    ];

    final outer = Paint()
      ..color = const Color(0xFF0288D1).withValues(alpha: alpha * 0.9)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final core = Paint()
      ..color = const Color(0xFFE1F5FE).withValues(alpha: alpha)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pulse = (math.sin(timeMs / 180 * math.pi) * 0.5 + 0.5);
    for (var i = 0; i < bolts.length; i++) {
      if (pulse < 0.25 && i.isEven) continue;
      canvas.drawPath(bolts[i], outer);
      canvas.drawPath(bolts[i], core);
    }

    // Sparks around center
    final random = math.Random(7);
    for (var i = 0; i < 8; i++) {
      final angle = random.nextDouble() * math.pi * 2 + timeMs * 0.02;
      final dist = 30 + random.nextDouble() * 55 * intensity;
      final sparkPos = center + Offset(math.cos(angle) * dist, math.sin(angle) * dist);
      canvas.drawCircle(
        sparkPos,
        1.5 + random.nextDouble() * 2,
        Paint()..color = const Color(0xFFB3E5FC).withValues(alpha: alpha * 0.8),
      );
    }
  }

  Path _boltPath(Offset start, Offset mid, Offset end, int segments) {
    final path = Path()..moveTo(start.dx, start.dy);
    var current = start;
    final points = [mid, end];
    for (final target in points) {
      for (var i = 1; i <= segments; i++) {
        final t = i / segments;
        final base = Offset.lerp(current, target, t)!;
        final jag = (i.isOdd ? 1 : -1) * (6 + (i * 3) % 8);
        path.lineTo(base.dx + jag, base.dy + jag * 0.6);
      }
      current = target;
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _GolemLightningPainter oldDelegate) =>
      oldDelegate.intensity != intensity ||
      oldDelegate.fade != fade ||
      oldDelegate.timeMs != timeMs;
}

class _RockChunk {
  _RockChunk({
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

  static List<_RockChunk> generate(int count) {
    final random = math.Random(31);
    return List.generate(count, (i) {
      return _RockChunk(
        angle: random.nextDouble() * math.pi * 2,
        distance: 0.18 + random.nextDouble() * 0.42,
        size: 6 + random.nextDouble() * 14,
        rotation: random.nextDouble() * math.pi,
        delay: random.nextDouble() * 0.25,
      );
    });
  }
}

class _GolemDebrisPainter extends CustomPainter {
  _GolemDebrisPainter({
    required this.chunks,
    required this.travel,
    required this.dust,
    required this.fade,
    this.armDustLeft = 0,
    this.armDustRight = 0,
  });

  final List<_RockChunk> chunks;
  final double travel;
  final double dust;
  final double fade;
  final double armDustLeft;
  final double armDustRight;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.5);
    final maxDim = math.max(size.width, size.height);

    if (dust > 0) {
      final dustAlpha = (dust * fade * 0.45).clamp(0.0, 1.0);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + size.height * 0.08),
          width: 80 + dust * maxDim * 0.55,
          height: 40 + dust * maxDim * 0.22,
        ),
        Paint()..color = const Color(0xFFBCAAA4).withValues(alpha: dustAlpha),
      );
    }

    _drawArmDustPuff(canvas, size, center, -0.22, armDustLeft, fade);
    _drawArmDustPuff(canvas, size, center, 0.22, armDustRight, fade);

    for (final c in chunks) {
      final localT = ((travel - c.delay) / (1 - c.delay)).clamp(0.0, 1.0);
      if (localT <= 0) continue;
      final eased = Curves.easeOutCubic.transform(localT);
      final dist = c.distance * maxDim * eased;
      final gravity = eased * eased * maxDim * 0.14;
      final pos = center +
          Offset(
            math.cos(c.angle) * dist,
            math.sin(c.angle) * dist * 0.55 + gravity,
          );
      final alpha = (fade * (1 - localT * 0.15)).clamp(0.0, 1.0);
      if (alpha <= 0) continue;

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(c.rotation + eased * math.pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: c.size, height: c.size * 0.85),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF8D6E63).withValues(alpha: alpha * 0.92),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: c.size, height: c.size * 0.85),
          const Radius.circular(3),
        ),
        Paint()
          ..color = const Color(0xFFBCAAA4).withValues(alpha: alpha * 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      canvas.restore();
    }
  }

  void _drawArmDustPuff(
    Canvas canvas,
    Size size,
    Offset center,
    double xBias,
    double armProgress,
    double fade,
  ) {
    if (armProgress < 0.75) return;
    final landT = ((armProgress - 0.75) / 0.25).clamp(0.0, 1.0);
    final alpha = (fade * landT * 0.5 * (1 - landT * 0.6)).clamp(0.0, 1.0);
    if (alpha <= 0) return;
    final puffCenter = Offset(
      center.dx + size.width * xBias,
      center.dy + size.height * 0.14,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: puffCenter,
        width: 36 + landT * 28,
        height: 16 + landT * 12,
      ),
      Paint()..color = const Color(0xFFBCAAA4).withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(covariant _GolemDebrisPainter oldDelegate) =>
      oldDelegate.travel != travel ||
      oldDelegate.dust != dust ||
      oldDelegate.fade != fade ||
      oldDelegate.armDustLeft != armDustLeft ||
      oldDelegate.armDustRight != armDustRight;
}
