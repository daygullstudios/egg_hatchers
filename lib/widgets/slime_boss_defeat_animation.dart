import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/audio_assets.dart';
import '../models/background_theme.dart';
import '../utils/cinematic_sound_guard.dart';
import 'audio_scope.dart';
import '../models/boss_battle.dart';
import '../utils/format_utils.dart';
import 'boss_sprite.dart';
import 'slime_boss_forest_background.dart';

enum _SlimeExpression { none, dizzy, surprised }

enum _GooKind { blob, splat, smear, screenSplat }

/// Cinematic Slime Boss defeat celebration for manual battle victories.
class SlimeBossDefeatAnimation extends StatefulWidget {
  const SlimeBossDefeatAnimation({
    super.key,
    required this.theme,
    required this.boss,
    required this.coinReward,
    required this.tokenReward,
    this.animalRewardName,
    required this.showBattleBackgrounds,
    required this.onComplete,
  });

  static const duration = Duration(milliseconds: 10500);

  final BackgroundTheme theme;
  final BossBattleDefinition boss;
  final int coinReward;
  final int tokenReward;
  final String? animalRewardName;
  final bool showBattleBackgrounds;
  final VoidCallback onComplete;

  @override
  State<SlimeBossDefeatAnimation> createState() =>
      _SlimeBossDefeatAnimationState();
}

class _SlimeBossDefeatAnimationState extends State<SlimeBossDefeatAnimation>
    with SingleTickerProviderStateMixin {
  static const _totalMs = 10500.0;
  static const _skipAfterMs = 1000.0;
  static const _explosionStartMs = 7500.0;
  static const _burstTravelEndMs = 8600.0;
  static const _baseSpriteSize = 158.0;
  static const _sizeBoost = 1.38;

  late final AnimationController _controller;
  late final List<_GooParticle> _particles;
  late final CinematicSoundGuard _soundGuard;
  var _completed = false;

  @override
  void initState() {
    super.initState();
    _particles = _GooParticle.generate();
    _soundGuard = CinematicSoundGuard();
    _controller = AnimationController(
      vsync: this,
      duration: SlimeBossDefeatAnimation.duration,
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
    _soundGuard.maybeAt(t, 'pop', _explosionStartMs, () => audio.playSfx(Sfx.slimePop));
    if (widget.coinReward > 0) {
      _soundGuard.maybeAt(t, 'coins', 9000, () => audio.playRewardTriumph());
    }
  }

  _SlimeExpression _expression(double t) {
    if (t < 1000) return _SlimeExpression.none;
    if (t < 6800) return _SlimeExpression.dizzy;
    if (t < _explosionStartMs) return _SlimeExpression.surprised;
    return _SlimeExpression.none;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _timeMs();
        _playPhaseSounds(t);
        final expression = _expression(t);

        final zoomPhase = Curves.easeOutCubic.transform(_phase(0, 1000));
        final zoomScale = 0.88 + zoomPhase * 0.58;
        final darken = (0.32 + zoomPhase * 0.38).clamp(0.0, 0.72);

        final wobblePhase = _phase(1000, 5500);
        final pressurePhase = _phase(5500, _explosionStartMs);
        final panicPhase = _phase(6800, _explosionStartMs);
        final wobbleAmp = 6 + wobblePhase * 14 + pressurePhase * 34 + panicPhase * 12;
        final wobbleSpeed = 190 - pressurePhase * 130;
        final wobbleX = t >= 1000 && t < _explosionStartMs
            ? math.sin(t / wobbleSpeed * math.pi) * wobbleAmp
            : 0.0;
        final squashStrength =
            0.05 + wobblePhase * 0.07 + pressurePhase * 0.16 + panicPhase * 0.1;
        final squash =
            1 + math.sin(t / (220 - pressurePhase * 90) * math.pi) * squashStrength;

        final earlyInflate = Curves.easeInOut.transform(_phase(3000, 5500));
        final finalInflate = Curves.easeIn.transform(_phase(5500, 6800));
        final panicInflate = Curves.easeIn.transform(_phase(6800, _explosionStartMs));
        final inflateScale =
            1.0 + earlyInflate * 0.4 + finalInflate * 0.85 + panicInflate * 0.55;

        final prePopSnap = Curves.easeIn.transform(_phase(7350, _explosionStartMs));
        final snapScale = 1.0 + prePopSnap * 0.32;

        final bossScale = zoomScale * inflateScale * _sizeBoost * snapScale;
        final scaleX = bossScale * (1 + (1 - squash) * (0.14 + pressurePhase * 0.14));
        final scaleY = bossScale * squash;

        final surpriseShake = t >= 6800 && t < _explosionStartMs
            ? math.sin(t / 22 * math.pi) * (8 + panicPhase * 10)
            : 0.0;

        final showBoss = t < _explosionStartMs;

        final burstTravel = t >= _explosionStartMs
            ? Curves.easeOutCubic.transform(
                _phase(_explosionStartMs, _burstTravelEndMs),
              )
            : 0.0;

        final flashWhite = t >= _explosionStartMs
            ? (1 - _phase(_explosionStartMs, _explosionStartMs + 280)).clamp(0.0, 1.0)
            : 0.0;
        final flashGreen = t >= _explosionStartMs
            ? (1 - _phase(_explosionStartMs + 30, _explosionStartMs + 650))
                .clamp(0.0, 1.0)
            : 0.0;

        final shockwaveProgress = t >= _explosionStartMs
            ? Curves.easeOut.transform(_phase(_explosionStartMs, _explosionStartMs + 900))
            : 0.0;

        final splatReveal = t >= _burstTravelEndMs - 100
            ? Curves.easeOut.transform(_phase(_burstTravelEndMs - 100, 9200))
            : 0.0;
        final particleFade = (1 - _phase(9200, 10300)).clamp(0.0, 1.0);
        final shockwaveFade = t >= _explosionStartMs && t < 9200 ? 1.0 : particleFade;

        final shakeAmp = t >= _explosionStartMs && t < 8100
            ? 32 * (1 - _phase(_explosionStartMs, 8100))
            : 0.0;
        final shakeX = math.sin(t / 24 * math.pi) * shakeAmp;
        final shakeY = math.cos(t / 30 * math.pi) * shakeAmp * 0.7;

        final pressureGlow = pressurePhase * (showBoss ? 1.0 : 0.0);

        final titleProgress = Curves.elasticOut.transform(_phase(9300, 9900));
        final titleOpacity = Curves.easeOut.transform(_phase(9300, 9700));
        final rewardsOpacity = Curves.easeOut.transform(_phase(9600, 10300));
        final rewardsSlide = (1 - rewardsOpacity) * 28;

        final canSkip = t >= _skipAfterMs && !_completed;

        return Material(
          color: Colors.black.withValues(alpha: 0.82),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: canSkip ? _trySkip : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const SlimeBossForestBackground(),
                ColoredBox(color: Colors.black.withValues(alpha: darken)),
                if (showBoss)
                  Transform.translate(
                    offset: Offset(wobbleX + surpriseShake, 0),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.diagonal3Values(scaleX, scaleY, 1),
                      child: _SlimeBossStage(
                        boss: widget.boss,
                        spriteSize: _baseSpriteSize,
                        expression: expression,
                        timeMs: t,
                        wobblePhase: wobblePhase,
                        pressurePhase: pressurePhase,
                        pressureGlow: pressureGlow,
                        panicPhase: panicPhase,
                      ),
                    ),
                  ),
                if (flashWhite > 0)
                  ColoredBox(
                    color: Colors.white.withValues(alpha: flashWhite * 0.96),
                  ),
                if (flashGreen > 0)
                  ColoredBox(
                    color: const Color(0xFF76FF03).withValues(alpha: flashGreen * 0.62),
                  ),
                Transform.translate(
                  offset: Offset(shakeX, shakeY),
                  child: CustomPaint(
                    painter: _ExplosionEffectsPainter(
                      shockwaveProgress: shockwaveProgress,
                      burstCore: burstTravel.clamp(0.0, 0.55) / 0.55,
                      fade: shockwaveFade,
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(shakeX, shakeY),
                  child: CustomPaint(
                    painter: _GooParticlePainter(
                      particles: _particles,
                      burstTravel: burstTravel,
                      splatReveal: splatReveal,
                      fade: particleFade,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 88),
                    Opacity(
                      opacity: titleOpacity,
                      child: Transform.scale(
                        scale: 0.75 + titleProgress * 0.25,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'SLIME SPLAT!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: Color(0xFFFFEB3B),
                              shadows: [
                                Shadow(
                                  color: Colors.black87,
                                  blurRadius: 12,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Opacity(
                      opacity: titleOpacity * 0.9,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.boss.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: widget.theme.cardTextPrimaryColor.withValues(
                              alpha: 0.95,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Opacity(
                      opacity: rewardsOpacity,
                      child: Transform.translate(
                        offset: Offset(0, rewardsSlide),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              if (widget.coinReward > 0)
                                _RewardChip(
                                  label: '🪙 +${formatCoins(widget.coinReward)}',
                                  color: Colors.amber.shade700,
                                ),
                              if (widget.tokenReward > 0)
                                _RewardChip(
                                  label: '⚔️ +${widget.tokenReward}',
                                  color: const Color(0xFF1565C0),
                                ),
                              if (widget.animalRewardName != null)
                                _RewardChip(
                                  label: 'Elite: ${widget.animalRewardName!}',
                                  color: Colors.deepPurple.shade400,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (canSkip)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: TextButton.icon(
                      onPressed: _trySkip,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        backgroundColor: Colors.black45,
                      ),
                      icon: const Icon(Icons.fast_forward_rounded),
                      label: const Text('Skip'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SlimeBossStage extends StatelessWidget {
  const _SlimeBossStage({
    required this.boss,
    required this.spriteSize,
    required this.expression,
    required this.timeMs,
    required this.wobblePhase,
    required this.pressurePhase,
    required this.pressureGlow,
    required this.panicPhase,
  });

  final BossBattleDefinition boss;
  final double spriteSize;
  final _SlimeExpression expression;
  final double timeMs;
  final double wobblePhase;
  final double pressurePhase;
  final double pressureGlow;
  final double panicPhase;

  @override
  Widget build(BuildContext context) {
    final starAngle = timeMs / 600 * math.pi * 2;

    return SizedBox(
      width: spriteSize + 100,
      height: spriteSize + 100,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (pressureGlow > 0)
            Container(
              width: spriteSize * (1.15 + pressurePhase * 0.55 + panicPhase * 0.25),
              height: spriteSize * (1.15 + pressurePhase * 0.55 + panicPhase * 0.25),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color.lerp(
                      const Color(0xFF66BB6A),
                      const Color(0xFF76FF03),
                      panicPhase,
                    )!.withValues(
                      alpha: 0.28 + pressureGlow * 0.55,
                    ),
                    blurRadius: 32 + pressurePhase * 28 + panicPhase * 20,
                    spreadRadius: 8 + pressurePhase * 12 + panicPhase * 8,
                  ),
                ],
              ),
            ),
          if (pressurePhase > 0.15)
            ...List.generate(3, (i) {
              final pulse = (pressurePhase - i * 0.12).clamp(0.0, 1.0);
              if (pulse <= 0) return const SizedBox.shrink();
              return Opacity(
                opacity: pulse * 0.35,
                child: Container(
                  width: spriteSize * (0.9 + i * 0.18 + pressurePhase * 0.35),
                  height: spriteSize * (0.9 + i * 0.18 + pressurePhase * 0.35),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFA5D6A7).withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                ),
              );
            }),
          if (expression == _SlimeExpression.dizzy)
            ...List.generate(3, (i) {
              final a = starAngle + i * math.pi * 2 / 3;
              return Transform.translate(
                offset: Offset(
                  math.cos(a) * (spriteSize * 0.44),
                  math.sin(a) * (spriteSize * 0.3) - spriteSize * 0.12,
                ),
                child: Text(
                  '⭐',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.yellow.withValues(
                      alpha: 0.55 + wobblePhase * 0.35,
                    ),
                  ),
                ),
              );
            }),
          BossSprite(
            spritePath: boss.spritePath,
            fallbackEmoji: boss.emoji,
            bossId: boss.id,
            size: spriteSize,
            semanticLabel: boss.name,
          ),
          if (expression == _SlimeExpression.dizzy ||
              expression == _SlimeExpression.surprised)
            Positioned(
              top: spriteSize * 0.2,
              child: CustomPaint(
                size: Size(spriteSize * 0.58, spriteSize * 0.3),
                painter: _SlimeFacePainter(
                  expression: expression,
                  spin: timeMs / 400 * math.pi * 2,
                  surprisedScale: expression == _SlimeExpression.surprised
                      ? 1.25 + panicPhase * 0.35
                      : 1.0,
                ),
              ),
            ),
          if ((expression == _SlimeExpression.dizzy && wobblePhase > 0.2) ||
              pressurePhase > 0.2)
            Positioned(
              top: spriteSize * 0.55,
              child: Opacity(
                opacity: (wobblePhase * 0.45 + pressurePhase * 0.55).clamp(0.0, 1.0),
                child: CustomPaint(
                  size: Size(spriteSize * 0.75, spriteSize * 0.38),
                  painter: _SlimeBubblePainter(
                    seed: 3,
                    count: 6 + (pressurePhase * 8).round(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SlimeFacePainter extends CustomPainter {
  _SlimeFacePainter({
    required this.expression,
    required this.spin,
    required this.surprisedScale,
  });

  final _SlimeExpression expression;
  final double spin;
  final double surprisedScale;

  @override
  void paint(Canvas canvas, Size size) {
    final leftEye = Offset(size.width * 0.28, size.height * 0.42);
    final rightEye = Offset(size.width * 0.72, size.height * 0.42);
    final eyeR = 11.0 * surprisedScale;

    if (expression == _SlimeExpression.dizzy) {
      _drawSpiralEye(canvas, leftEye, eyeR, spin);
      _drawSpiralEye(canvas, rightEye, eyeR, -spin);
      return;
    }

    if (expression == _SlimeExpression.surprised) {
      final white = Paint()..color = Colors.white;
      final pupil = Paint()..color = const Color(0xFF1B5E20);
      canvas.drawCircle(leftEye, eyeR + 4, white);
      canvas.drawCircle(rightEye, eyeR + 4, white);
      canvas.drawCircle(leftEye, 5.5, pupil);
      canvas.drawCircle(rightEye, 5.5, pupil);

      final mouth = Paint()
        ..color = const Color(0xFF1B5E20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.9),
          width: 22 * surprisedScale,
          height: 18 * surprisedScale,
        ),
        mouth,
      );
    }
  }

  void _drawSpiralEye(Canvas canvas, Offset center, double radius, double angle) {
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    final spiral = Paint()
      ..color = const Color(0xFF1B5E20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path();
    for (var i = 0; i <= 24; i++) {
      final t = i / 24;
      final r = radius * 0.15 + radius * 0.75 * t;
      final a = angle + t * math.pi * 3;
      final p = center + Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, spiral);
  }

  @override
  bool shouldRepaint(covariant _SlimeFacePainter oldDelegate) =>
      oldDelegate.expression != expression ||
      oldDelegate.spin != spin ||
      oldDelegate.surprisedScale != surprisedScale;
}

class _SlimeBubblePainter extends CustomPainter {
  _SlimeBubblePainter({required this.seed, this.count = 6});

  final int seed;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final bubble = Paint()..color = const Color(0xFFA5D6A7).withValues(alpha: 0.5);
    for (var i = 0; i < count; i++) {
      canvas.drawCircle(
        Offset(
          size.width * (0.12 + random.nextDouble() * 0.76),
          size.height * (0.15 + random.nextDouble() * 0.7),
        ),
        3 + random.nextDouble() * 5,
        bubble,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SlimeBubblePainter oldDelegate) =>
      oldDelegate.count != count;
}

class _GooParticle {
  _GooParticle({
    required this.kind,
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
    required this.outlineColor,
    required this.verticalBias,
    required this.stickNx,
    required this.stickNy,
    required this.aspectRatio,
    required this.rotation,
    required this.lumpiness,
  });

  final _GooKind kind;
  final double angle;
  final double distance;
  final double size;
  final Color color;
  final Color outlineColor;
  final double verticalBias;
  final double stickNx;
  final double stickNy;
  final double aspectRatio;
  final double rotation;
  final double lumpiness;

  Offset landingOffset(Offset center, Size size, double maxDim) {
    final isAnchored = kind == _GooKind.splat ||
        kind == _GooKind.smear ||
        kind == _GooKind.screenSplat;
    if (isAnchored) {
      return center +
          Offset(
            stickNx * size.width * 0.48,
            stickNy * size.height * 0.46,
          );
    }
    final gravity = verticalBias * maxDim * 0.12;
    return center +
        Offset(
          math.cos(angle) * distance * maxDim,
          math.sin(angle) * distance * maxDim * 0.72 + gravity,
        );
  }

  static List<_GooParticle> generate() {
    final random = math.Random(42);
    const palette = [
      Color(0xFF66BB6A),
      Color(0xFF43A047),
      Color(0xFF2E7D32),
      Color(0xFFA5D6A7),
      Color(0xFF1B5E20),
      Color(0xFF81C784),
    ];
    const outlines = [
      Color(0xFF1B5E20),
      Color(0xFF33691E),
      Color(0xFF2E7D32),
    ];

    final particles = <_GooParticle>[];

    for (var i = 0; i < 38; i++) {
      particles.add(
        _GooParticle(
          kind: _GooKind.blob,
          angle: random.nextDouble() * math.pi * 2,
          distance: 0.22 + random.nextDouble() * 0.48,
          size: 5 + random.nextDouble() * 10,
          color: palette[i % palette.length],
          outlineColor: outlines[i % outlines.length],
          verticalBias: 0.2 + random.nextDouble() * 0.6,
          stickNx: 0,
          stickNy: 0,
          aspectRatio: 1,
          rotation: 0,
          lumpiness: 0,
        ),
      );
    }

    for (var i = 0; i < 14; i++) {
      particles.add(
        _GooParticle(
          kind: _GooKind.splat,
          angle: random.nextDouble() * math.pi * 2,
          distance: 0.35 + random.nextDouble() * 0.55,
          size: 14 + random.nextDouble() * 22,
          color: palette[(i + 2) % palette.length],
          outlineColor: outlines[i % outlines.length],
          verticalBias: 0.15 + random.nextDouble() * 0.5,
          stickNx: -0.92 + random.nextDouble() * 1.84,
          stickNy: -0.88 + random.nextDouble() * 1.76,
          aspectRatio: 0.65 + random.nextDouble() * 0.7,
          rotation: random.nextDouble() * math.pi,
          lumpiness: 0.3 + random.nextDouble() * 0.5,
        ),
      );
    }

    for (var i = 0; i < 8; i++) {
      particles.add(
        _GooParticle(
          kind: _GooKind.smear,
          angle: random.nextDouble() * math.pi * 2,
          distance: 0.4 + random.nextDouble() * 0.45,
          size: 18 + random.nextDouble() * 28,
          color: palette[(i + 4) % palette.length],
          outlineColor: outlines[i % outlines.length],
          verticalBias: 0.5 + random.nextDouble() * 0.4,
          stickNx: -0.85 + random.nextDouble() * 1.7,
          stickNy: -0.75 + random.nextDouble() * 1.5,
          aspectRatio: 1.6 + random.nextDouble() * 1.2,
          rotation: random.nextDouble() * math.pi,
          lumpiness: 0.4,
        ),
      );
    }

    const screenAnchors = [
      (-0.85, -0.82),
      (0.0, -0.88),
      (0.85, -0.82),
      (-0.92, -0.2),
      (0.92, -0.15),
      (-0.88, 0.55),
      (0.88, 0.58),
      (0.0, 0.72),
      (-0.55, 0.35),
      (0.55, 0.38),
      (-0.35, -0.45),
      (0.4, -0.42),
    ];

    for (var i = 0; i < screenAnchors.length; i++) {
      final (nx, ny) = screenAnchors[i];
      particles.add(
        _GooParticle(
          kind: _GooKind.screenSplat,
          angle: random.nextDouble() * math.pi * 2,
          distance: 0.5 + random.nextDouble() * 0.35,
          size: 28 + random.nextDouble() * 38,
          color: palette[i % palette.length],
          outlineColor: outlines[i % outlines.length],
          verticalBias: 0,
          stickNx: nx + (random.nextDouble() - 0.5) * 0.08,
          stickNy: ny + (random.nextDouble() - 0.5) * 0.08,
          aspectRatio: 0.7 + random.nextDouble() * 0.55,
          rotation: random.nextDouble() * math.pi,
          lumpiness: 0.45 + random.nextDouble() * 0.35,
        ),
      );
    }

    return particles;
  }
}

class _ExplosionEffectsPainter extends CustomPainter {
  _ExplosionEffectsPainter({
    required this.shockwaveProgress,
    required this.burstCore,
    required this.fade,
  });

  final double shockwaveProgress;
  final double burstCore;
  final double fade;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxDim = math.max(size.width, size.height);

    if (burstCore > 0) {
      final coreAlpha = (burstCore * (1 - burstCore * 0.25)).clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        36 + burstCore * 90,
        Paint()..color = Colors.white.withValues(alpha: coreAlpha * 0.95),
      );
      canvas.drawCircle(
        center,
        56 + burstCore * 120,
        Paint()..color = const Color(0xFF76FF03).withValues(alpha: coreAlpha * 0.7),
      );
    }

    if (shockwaveProgress > 0) {
      final radius = 28 + shockwaveProgress * maxDim * 0.68;
      final ringAlpha = ((1 - shockwaveProgress) * fade).clamp(0.0, 1.0);
      final ringPaint = Paint()
        ..color = Colors.white.withValues(alpha: ringAlpha * 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8 + (1 - shockwaveProgress) * 14;
      canvas.drawCircle(center, radius, ringPaint);

      final innerRing = Paint()
        ..color = const Color(0xFFC5E1A5).withValues(alpha: ringAlpha * 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 + (1 - shockwaveProgress) * 8;
      canvas.drawCircle(center, radius * 0.82, innerRing);
    }
  }

  @override
  bool shouldRepaint(covariant _ExplosionEffectsPainter oldDelegate) =>
      oldDelegate.shockwaveProgress != shockwaveProgress ||
      oldDelegate.burstCore != burstCore ||
      oldDelegate.fade != fade;
}

class _GooParticlePainter extends CustomPainter {
  _GooParticlePainter({
    required this.particles,
    required this.burstTravel,
    required this.splatReveal,
    required this.fade,
  });

  final List<_GooParticle> particles;
  final double burstTravel;
  final double splatReveal;
  final double fade;

  @override
  void paint(Canvas canvas, Size size) {
    if (burstTravel <= 0 && splatReveal <= 0 && fade >= 1) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxDim = math.max(size.width, size.height);
    final travel = burstTravel.clamp(0.0, 1.0);

    if (travel > 0.02) {
      final popAlpha = (travel * fade * 0.9).clamp(0.0, 1.0);
      _drawIrregularSplat(
        canvas,
        center,
        50 + travel * maxDim * 0.22,
        38 + travel * maxDim * 0.16,
        0,
        const Color(0xFF43A047),
        const Color(0xFF1B5E20),
        popAlpha,
        0.35,
      );
    }

    for (final p in particles) {
      final landing = p.landingOffset(center, size, maxDim);
      final flyT = Curves.easeOutCubic.transform(travel);
      final pos = Offset.lerp(center, landing, flyT)!;

      final isSticky = p.kind == _GooKind.splat ||
          p.kind == _GooKind.smear ||
          p.kind == _GooKind.screenSplat;

      if (travel > 0 && travel < 1.0) {
        final flyAlpha = (fade * (1 - travel * 0.03)).clamp(0.0, 1.0);
        if (flyAlpha <= 0) continue;

        final blobSize = p.size * (0.9 + flyT * 0.45);
        final blobPaint = Paint()..color = p.color.withValues(alpha: flyAlpha * 0.92);
        canvas.drawCircle(pos, blobSize, blobPaint);
        canvas.drawCircle(
          pos + Offset(-blobSize * 0.25, -blobSize * 0.25),
          blobSize * 0.3,
          Paint()..color = Colors.white.withValues(alpha: flyAlpha * 0.4),
        );
        canvas.drawCircle(
          pos,
          blobSize + 1.5,
          Paint()
            ..color = p.outlineColor.withValues(alpha: flyAlpha * 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );

        if (flyT > 0.15) {
          final trail = Offset.lerp(center, pos, flyT * 0.55)!;
          canvas.drawCircle(
            trail,
            blobSize * 0.55,
            Paint()..color = p.color.withValues(alpha: flyAlpha * 0.35),
          );
        }
      }

      if (isSticky && splatReveal > 0 && travel >= 0.65) {
        final stickAlpha =
            (splatReveal * fade * Curves.easeOut.transform((travel - 0.65) / 0.35))
                .clamp(0.0, 1.0);
        if (stickAlpha <= 0) continue;

        if (p.kind == _GooKind.smear) {
          _drawSmear(
            canvas,
            landing,
            p.size * (0.85 + splatReveal * 0.45),
            p.rotation,
            p.color,
            p.outlineColor,
            stickAlpha * 0.9,
          );
        } else {
          _drawIrregularSplat(
            canvas,
            landing,
            p.size * (1.5 + splatReveal * 0.55),
            p.size * p.aspectRatio * (1.35 + splatReveal * 0.45),
            p.rotation,
            p.color,
            p.outlineColor,
            stickAlpha * 0.94,
            p.lumpiness,
          );
        }
      } else if (!isSticky && travel >= 0.95 && p.kind == _GooKind.blob) {
        final blobAlpha = (fade * splatReveal * 0.7).clamp(0.0, 1.0);
        if (blobAlpha <= 0) continue;
        canvas.drawCircle(
          landing,
          p.size * 0.85,
          Paint()..color = p.color.withValues(alpha: blobAlpha),
        );
      }
    }
  }

  void _drawIrregularSplat(
    Canvas canvas,
    Offset center,
    double width,
    double height,
    double rotation,
    Color fill,
    Color outline,
    double alpha,
    double lumpiness,
  ) {
    if (alpha <= 0) return;

    final path = Path();
    const points = 10;
    for (var i = 0; i <= points; i++) {
      final t = i / points;
      final angle = rotation + t * math.pi * 2;
      final wobble = 1 + math.sin(t * math.pi * 5) * lumpiness * 0.22;
      final rX = width * 0.5 * wobble;
      final rY = height * 0.5 * (1 + math.cos(t * math.pi * 4) * lumpiness * 0.15);
      final p = center + Offset(math.cos(angle) * rX, math.sin(angle) * rY);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()..color = fill.withValues(alpha: alpha * 0.88),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = outline.withValues(alpha: alpha * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawCircle(
      center + Offset(-width * 0.12, -height * 0.1),
      width * 0.08,
      Paint()..color = Colors.white.withValues(alpha: alpha * 0.25),
    );
  }

  void _drawSmear(
    Canvas canvas,
    Offset center,
    double length,
    double rotation,
    Color fill,
    Color outline,
    double alpha,
  ) {
    if (alpha <= 0) return;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final smear = Path()
      ..moveTo(-length * 0.15, -length * 0.08)
      ..quadraticBezierTo(length * 0.35, 0, length * 0.55, length * 0.12)
      ..quadraticBezierTo(length * 0.2, length * 0.18, -length * 0.1, length * 0.06)
      ..close();

    canvas.drawPath(
      smear,
      Paint()..color = fill.withValues(alpha: alpha * 0.82),
    );
    canvas.drawPath(
      smear,
      Paint()
        ..color = outline.withValues(alpha: alpha * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GooParticlePainter oldDelegate) =>
      oldDelegate.burstTravel != burstTravel ||
      oldDelegate.splatReveal != splatReveal ||
      oldDelegate.fade != fade;
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.75)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }
}
