import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/audio_assets.dart';
import '../models/animal_sprite_theme.dart';
import '../models/background_theme.dart';
import '../models/boss_battle.dart';
import '../utils/cinematic_sound_guard.dart';
import 'animal_sprite_theme_scope.dart';
import 'audio_scope.dart';
import 'boss_cinematic_ui.dart';
import 'boss_sprite.dart';
import 'rotten_shell_cinematic_background.dart';

/// Cinematic Rotten Shell defeat — Rotten Core Meltdown (~14s).
class RottenShellDefeatAnimation extends StatefulWidget {
  const RottenShellDefeatAnimation({
    super.key,
    required this.theme,
    required this.boss,
    required this.coinReward,
    required this.tokenReward,
    required this.eggShardReward,
    required this.onComplete,
  });

  static const duration = Duration(milliseconds: 14000);

  final BackgroundTheme theme;
  final BossBattleDefinition boss;
  final int coinReward;
  final int tokenReward;
  final int eggShardReward;
  final VoidCallback onComplete;

  @override
  State<RottenShellDefeatAnimation> createState() =>
      _RottenShellDefeatAnimationState();
}

class _RottenShellDefeatAnimationState extends State<RottenShellDefeatAnimation>
    with SingleTickerProviderStateMixin {
  static const _totalMs = 14000.0;
  static const _skipAfterMs = 1000.0;
  static const _baseSpriteSize = 172.0;
  static const _sizeBoost = 1.42;

  late final AnimationController _controller;
  late final List<_ShellFragment> _fragments;
  late final List<_SmokePuff> _smokePuffs;
  late final List<_EggShardVisual> _eggShards;
  late final List<_SuctionParticle> _suctionParticles;
  late final CinematicSoundGuard _soundGuard;
  var _completed = false;

  @override
  void initState() {
    super.initState();
    _fragments = _ShellFragment.generate(28);
    _smokePuffs = _SmokePuff.generate(14);
    _eggShards = _EggShardVisual.generate(
      math.max(widget.eggShardReward, 10),
    );
    _suctionParticles = _SuctionParticle.generate(20);
    _soundGuard = CinematicSoundGuard();
    _controller = AnimationController(
      vsync: this,
      duration: RottenShellDefeatAnimation.duration,
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

  double _corePulseScale(double t) {
    final meltdown = _phase(5500, 7500);
    final collapse = _phase(7500, 9200);
    final period = 140.0 - meltdown * 55 - collapse * 45;
    final wave = math.sin(t / period * math.pi * 2);
    final base = 0.82 + (wave + 1) * 0.12;
    final compress = 1 - collapse * 0.55;
    return base * compress;
  }

  void _playPhaseSounds(double t) {
    final audio = AudioScope.maybeOf(context);
    if (audio == null) return;
    _soundGuard.maybeAt(t, 'cracks', 1000, audio.playEggCrack);
    _soundGuard.maybeAt(t, 'core', 3000, () => audio.playSfx(Sfx.rottenPulse));
    _soundGuard.maybeAt(t, 'shellSplit', 5500, audio.playEggCrack);
    _soundGuard.maybeAt(t, 'meltdown', 6100, () => audio.playSfx(Sfx.rottenPulse));
    _soundGuard.maybeAt(t, 'collapse', 7500, () => audio.playSfx(Sfx.rottenCollapse));
    _soundGuard.maybeAt(
      t,
      'explosion',
      9200,
      () => audio.playSfx(Sfx.rottenExplosion),
    );
    _soundGuard.maybeAt(t, 'harvest', 10200, () {
      if (widget.eggShardReward > 0) {
        audio.playBigRewardTriumph();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRetro =
        AnimalSpriteThemeScope.of(context).id ==
        AnimalSpriteThemes.retroPixel.id;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _timeMs();
        _playPhaseSounds(t);

        final pauseZoom = Curves.easeOutCubic.transform(_phase(0, 1000));
        final zoomScale = (0.84 + pauseZoom * 0.48) * _sizeBoost;

        final crackSpread = Curves.easeIn.transform(_phase(1000, 3000));
        final coreReveal = Curves.easeOutCubic.transform(_phase(3000, 5500));
        final meltdown = _phase(5500, 7500);
        final collapse = Curves.easeIn.transform(_phase(7500, 9200));
        final explosion = Curves.easeOutCubic.transform(_phase(9200, 10200));
        final harvest = Curves.easeOut.transform(_phase(10200, 12500));
        final aftermath = _phase(12500, 14000);

        final collapseDarken = collapse * 0.42;
        final explosionBright =
            (1 - _phase(9200, 9800)).clamp(0.0, 1.0) * 0.38;
        final overlayDarken = (0.22 + pauseZoom * 0.18 + collapseDarken -
                explosionBright)
            .clamp(0.0, 0.72);

        final shakeAmp = _phase(0, 1000) * 3 +
            crackSpread * 11 +
            coreReveal * 8 +
            meltdown * 16 +
            collapse * 30 +
            explosion * 22 * (1 - _phase(9800, 10200));
        final shakeX = t < 10200 && shakeAmp > 0
            ? math.sin(t / 36 * math.pi) * shakeAmp
            : 0.0;
        final shakeY = t < 10200 && shakeAmp > 0
            ? math.cos(t / 44 * math.pi) * shakeAmp * 0.55
            : 0.0;

        final showBoss = t < 9200;
        final bossOpacity = t < 7500
            ? 1.0
            : (1 - _phase(7500, 9100)).clamp(0.0, 1.0);
        final bossShrink = 1 - collapse * 0.35;
        final shellSplit = coreReveal * 14;

        final coreVisible = coreReveal > 0.05;
        final coreScale = _corePulseScale(t);
        final coreGlow = (0.35 +
                crackSpread * 0.25 +
                coreReveal * 0.45 +
                meltdown * 0.35 +
                collapse * 0.55)
            .clamp(0.0, 1.0);

        final ringIntensity =
            meltdown * (0.5 + math.sin(t / 70 * math.pi) * 0.35);
        final suctionIntensity = collapse;
        final shardGlint = meltdown * (0.25 + math.sin(t / 55 * math.pi) * 0.2);

        final burstFlash = t >= 9200
            ? (1 - _phase(9200, 9800)).clamp(0.0, 1.0)
            : 0.0;
        final shockwave = t >= 9200
            ? Curves.easeOut.transform(_phase(9200, 10400))
            : 0.0;
        final effectFade = (1 - aftermath).clamp(0.0, 1.0);

        final eyeGlitch = crackSpread > 0.1 && t < 5500
            ? (math.sin(t / 38 * math.pi) > -0.15 ? 1.0 : 0.15)
            : 1.0;

        final fumeLeak = Curves.easeOut.transform(_phase(0, 3000)) *
            (1 - explosion * 0.6);

        final titleProgress = Curves.elasticOut.transform(_phase(10200, 11000));
        final titleOpacity = Curves.easeOut.transform(_phase(10200, 10800));
        final rewardsOpacity = Curves.easeOut.transform(_phase(11000, 12500));
        final rewardsSlide = (1 - rewardsOpacity) * 28;

        return Material(
          color: Colors.black.withValues(alpha: 0.86),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: t >= _skipAfterMs && !_completed ? _trySkip : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                RottenShellCinematicBackground(
                  vignetteStrength: 0.35 + collapse * 0.35,
                ),
                ColoredBox(color: Colors.black.withValues(alpha: overlayDarken)),
                if (fumeLeak > 0)
                  CustomPaint(
                    painter: _ToxicFumePainter(
                      expand: fumeLeak,
                      burst: explosion,
                      isRetro: isRetro,
                      fade: effectFade,
                    ),
                  ),
                if (ringIntensity > 0)
                  Transform.translate(
                    offset: Offset(shakeX, shakeY),
                    child: CustomPaint(
                      painter: _EnergyRingPainter(
                        intensity: ringIntensity,
                        timeMs: t,
                        isRetro: isRetro,
                        fade: effectFade,
                      ),
                    ),
                  ),
                if (suctionIntensity > 0)
                  CustomPaint(
                    painter: _SuctionSpiralPainter(
                      particles: _suctionParticles,
                      progress: suctionIntensity,
                      timeMs: t,
                      isRetro: isRetro,
                      fade: effectFade,
                    ),
                  ),
                if (coreVisible && showBoss)
                  Transform.translate(
                    offset: Offset(shakeX, shakeY),
                    child: Transform.scale(
                      scale: zoomScale * bossShrink,
                      child: CustomPaint(
                        painter: _RottenCorePainter(
                          scale: coreScale * zoomScale,
                          glow: coreGlow,
                          reveal: coreReveal,
                          collapse: collapse,
                          isRetro: isRetro,
                        ),
                      ),
                    ),
                  ),
                if (showBoss && bossOpacity > 0)
                  Transform.translate(
                    offset: Offset(shakeX, shakeY),
                    child: Transform.scale(
                      scale: zoomScale * bossShrink,
                      child: Opacity(
                        opacity: bossOpacity,
                        child: SizedBox(
                          width: _baseSpriteSize,
                          height: _baseSpriteSize * 1.08,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              if (coreGlow > 0.2)
                                Container(
                                  width: _baseSpriteSize * 0.72,
                                  height: _baseSpriteSize * 0.72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF7B1FA2)
                                            .withValues(alpha: coreGlow * 0.45),
                                        blurRadius: 40,
                                        spreadRadius: 6,
                                      ),
                                      BoxShadow(
                                        color: const Color(0xFF558B2F)
                                            .withValues(alpha: coreGlow * 0.35),
                                        blurRadius: 28,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              if (shellSplit > 1)
                                Transform.translate(
                                  offset: Offset(0, -shellSplit * 0.5),
                                  child: ClipRect(
                                    clipper: _HalfClipper(
                                      topHalf: true,
                                      gap: shellSplit,
                                    ),
                                    child: BossSprite(
                                      spritePath: widget.boss.spritePath,
                                      fallbackEmoji: widget.boss.emoji,
                                      bossId: widget.boss.id,
                                      size: _baseSpriteSize,
                                      semanticLabel: widget.boss.name,
                                    ),
                                  ),
                                ),
                              if (shellSplit > 1)
                                Transform.translate(
                                  offset: Offset(0, shellSplit * 0.5),
                                  child: ClipRect(
                                    clipper: _HalfClipper(
                                      topHalf: false,
                                      gap: shellSplit,
                                    ),
                                    child: BossSprite(
                                      spritePath: widget.boss.spritePath,
                                      fallbackEmoji: widget.boss.emoji,
                                      bossId: widget.boss.id,
                                      size: _baseSpriteSize,
                                      semanticLabel: widget.boss.name,
                                    ),
                                  ),
                                )
                              else
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
                                  _baseSpriteSize * 1.08,
                                ),
                                painter: _CrackOverlayPainter(
                                  progress: crackSpread,
                                  coreReveal: coreReveal,
                                  shardGlint: shardGlint,
                                  isRetro: isRetro,
                                ),
                              ),
                              if (crackSpread > 0.05)
                                Opacity(
                                  opacity: eyeGlitch,
                                  child: CustomPaint(
                                    size: Size(
                                      _baseSpriteSize,
                                      _baseSpriteSize,
                                    ),
                                    painter: _AngryEyeGlitchPainter(
                                      flicker: crackSpread,
                                      isRetro: isRetro,
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
                    painter: _FragmentPainter(
                      fragments: _fragments,
                      timeMs: t,
                      isRetro: isRetro,
                      fade: effectFade,
                    ),
                  ),
                ),
                if (explosion > 0 || harvest > 0)
                  CustomPaint(
                    painter: _ExplosionSmokePainter(
                      smoke: _smokePuffs,
                      explosion: explosion,
                      harvest: harvest,
                      shockwave: shockwave,
                      timeMs: t,
                      isRetro: isRetro,
                      fade: effectFade,
                    ),
                  ),
                if (explosion > 0 || harvest > 0)
                  CustomPaint(
                    painter: _EggShardHarvestPainter(
                      shards: _eggShards,
                      explosion: explosion,
                      harvest: harvest,
                      timeMs: t,
                      isRetro: isRetro,
                      fade: effectFade,
                    ),
                  ),
                if (burstFlash > 0)
                  ColoredBox(
                    color: Colors.white.withValues(alpha: burstFlash * 0.55),
                  ),
                if (burstFlash > 0)
                  ColoredBox(
                    color: const Color(0xFFAB47BC)
                        .withValues(alpha: burstFlash * 0.35),
                  ),
                if (burstFlash > 0)
                  ColoredBox(
                    color: const Color(0xFF9CCC65)
                        .withValues(alpha: burstFlash * 0.22),
                  ),
                BossCinematicVictoryOverlay(
                  theme: widget.theme,
                  bossName: widget.boss.name,
                  defeatTitle: 'ROTTEN CORE MELTDOWN!',
                  coinReward: widget.coinReward,
                  tokenReward: widget.tokenReward,
                  eggShardReward: widget.eggShardReward,
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

class _HalfClipper extends CustomClipper<Rect> {
  _HalfClipper({required this.topHalf, required this.gap});

  final bool topHalf;
  final double gap;

  @override
  Rect getClip(Size size) {
    final mid = size.height * 0.5;
    final halfGap = gap * 0.5;
    if (topHalf) {
      return Rect.fromLTRB(0, 0, size.width, mid - halfGap);
    }
    return Rect.fromLTRB(0, mid + halfGap, size.width, size.height);
  }

  @override
  bool shouldReclip(covariant _HalfClipper oldClipper) =>
      oldClipper.gap != gap || oldClipper.topHalf != topHalf;
}

class _ShellFragment {
  _ShellFragment({
    required this.orbitAngle,
    required this.orbitRadius,
    required this.orbitSpeed,
    required this.blastDistance,
    required this.size,
    required this.color,
    required this.rotation,
  });

  final double orbitAngle;
  final double orbitRadius;
  final double orbitSpeed;
  final double blastDistance;
  final double size;
  final Color color;
  final double rotation;

  static List<_ShellFragment> generate(int count) {
    final random = math.Random(77);
    const palette = [
      Color(0xFFC8BFB0),
      Color(0xFF8D8478),
      Color(0xFF558B2F),
      Color(0xFF7B1FA2),
      Color(0xFF4E342E),
      Color(0xFFF0EBE3),
    ];
    return List.generate(count, (i) {
      return _ShellFragment(
        orbitAngle: random.nextDouble() * math.pi * 2,
        orbitRadius: 52 + random.nextDouble() * 58,
        orbitSpeed: 0.4 + random.nextDouble() * 0.9,
        blastDistance: 90 + random.nextDouble() * 130,
        size: 6 + random.nextDouble() * 12,
        color: palette[i % palette.length],
        rotation: random.nextDouble() * math.pi,
      );
    });
  }
}

class _SmokePuff {
  _SmokePuff({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
  });

  final double angle;
  final double distance;
  final double size;
  final Color color;

  static List<_SmokePuff> generate(int count) {
    final random = math.Random(91);
    return List.generate(count, (i) {
      return _SmokePuff(
        angle: random.nextDouble() * math.pi * 2,
        distance: 30 + random.nextDouble() * 70,
        size: 18 + random.nextDouble() * 28,
        color: i.isEven
            ? const Color(0xFF7B1FA2)
            : const Color(0xFF558B2F),
      );
    });
  }
}

class _EggShardVisual {
  _EggShardVisual({
    required this.angle,
    required this.distance,
    required this.size,
    required this.delay,
    required this.spiralTurns,
  });

  final double angle;
  final double distance;
  final double size;
  final double delay;
  final double spiralTurns;

  static List<_EggShardVisual> generate(int count) {
    final random = math.Random(103);
    return List.generate(count, (i) {
      return _EggShardVisual(
        angle: (i / count) * math.pi * 2 + random.nextDouble() * 0.4,
        distance: 40 + random.nextDouble() * 50,
        size: 10 + random.nextDouble() * 8,
        delay: random.nextDouble() * 0.35,
        spiralTurns: 0.8 + random.nextDouble() * 0.6,
      );
    });
  }
}

class _SuctionParticle {
  _SuctionParticle({
    required this.startAngle,
    required this.startRadius,
    required this.spiralOffset,
    required this.size,
    required this.color,
  });

  final double startAngle;
  final double startRadius;
  final double spiralOffset;
  final double size;
  final Color color;

  static List<_SuctionParticle> generate(int count) {
    final random = math.Random(117);
    return List.generate(count, (i) {
      return _SuctionParticle(
        startAngle: random.nextDouble() * math.pi * 2,
        startRadius: 80 + random.nextDouble() * 120,
        spiralOffset: random.nextDouble() * math.pi * 2,
        size: 3 + random.nextDouble() * 5,
        color: i.isEven
            ? const Color(0xFF9CCC65)
            : const Color(0xFFAB47BC),
      );
    });
  }
}

class _RottenCorePainter extends CustomPainter {
  _RottenCorePainter({
    required this.scale,
    required this.glow,
    required this.reveal,
    required this.collapse,
    required this.isRetro,
  });

  final double scale;
  final double glow;
  final double reveal;
  final double collapse;
  final bool isRetro;

  @override
  void paint(Canvas canvas, Size size) {
    if (reveal <= 0) return;
    final cx = size.width * 0.5;
    final cy = size.height * 0.54;
    final baseR = 28.0 * scale * (0.65 + reveal * 0.55);

    if (isRetro) {
      final w = baseR * 1.6;
      final h = baseR * 1.4;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(cx, cy), width: w + 8, height: h + 8),
        Paint()..color = const Color(0xFF1A1510).withValues(alpha: glow * 0.5),
      );
      canvas.drawRect(
        Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
        Paint()..color = const Color(0xFF33691E).withValues(alpha: glow * 0.85),
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(cx, cy - 2),
          width: w * 0.55,
          height: h * 0.45,
        ),
        Paint()..color = const Color(0xFF7B1FA2).withValues(alpha: glow * 0.75),
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: w * 0.3,
          height: h * 0.25,
        ),
        Paint()..color = const Color(0xFFFFEB3B).withValues(alpha: glow * 0.6),
      );
    } else {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFEB3B).withValues(alpha: glow * 0.7),
            const Color(0xFF7B1FA2).withValues(alpha: glow * 0.65),
            const Color(0xFF33691E).withValues(alpha: glow * 0.55),
            const Color(0xFF1A1510).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: baseR * 2));
      canvas.drawCircle(Offset(cx, cy), baseR * 1.8, glowPaint);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: baseR * 1.5, height: baseR * 1.3),
        Paint()..color = const Color(0xFF33691E).withValues(alpha: glow * 0.9),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy - 3),
          width: baseR * 0.85,
          height: baseR * 0.7,
        ),
        Paint()..color = const Color(0xFFAB47BC).withValues(alpha: glow * 0.8),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: baseR * 0.45,
          height: baseR * 0.35,
        ),
        Paint()..color = const Color(0xFFFFF59D).withValues(alpha: glow * 0.75),
      );
    }

    if (collapse > 0.1) {
      final flash = collapse * (0.25 + math.sin(collapse * 18) * 0.15);
      canvas.drawCircle(
        Offset(cx, cy),
        baseR * (1.2 - collapse * 0.5),
        Paint()..color = Colors.white.withValues(alpha: flash),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RottenCorePainter oldDelegate) =>
      oldDelegate.scale != scale ||
      oldDelegate.glow != glow ||
      oldDelegate.reveal != reveal ||
      oldDelegate.collapse != collapse ||
      oldDelegate.isRetro != isRetro;
}

class _CrackOverlayPainter extends CustomPainter {
  _CrackOverlayPainter({
    required this.progress,
    required this.coreReveal,
    required this.shardGlint,
    required this.isRetro,
  });

  final double progress;
  final double coreReveal;
  final double shardGlint;
  final bool isRetro;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final cx = size.width * 0.5;
    final cy = size.height * 0.5;
    final crackPaint = Paint()
      ..color = const Color(0xFF4E342E)
      ..strokeWidth = isRetro ? 3 : 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = const Color(0xFF9CCC65).withValues(alpha: progress * 0.85)
      ..strokeWidth = isRetro ? 4 : 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void drawCrack(List<Offset> points) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, crackPaint);
      if (progress > 0.2) canvas.drawPath(path, glowPaint);
    }

    final spread = progress;
    drawCrack([
      Offset(cx - 8 * spread, cy - 42),
      Offset(cx + 2, cy - 8),
      Offset(cx - 4, cy + 12),
    ]);
    drawCrack([
      Offset(cx + 10 * spread, cy - 38),
      Offset(cx + 4, cy - 4),
      Offset(cx + 8, cy + 16),
    ]);
    drawCrack([
      Offset(cx - 20, cy - 10),
      Offset(cx - 6, cy + 4),
      Offset(cx + 14, cy + 22 * spread),
    ]);

    if (coreReveal > 0.3 && shardGlint > 0) {
      final glintPaint = Paint()
        ..color = const Color(0xFFFFF59D).withValues(alpha: shardGlint);
      for (var i = 0; i < 4; i++) {
        final px = cx + (i - 1.5) * 14;
        final py = cy + 6 + i * 3.0;
        if (isRetro) {
          canvas.drawRect(Rect.fromCenter(center: Offset(px, py), width: 5, height: 5), glintPaint);
        } else {
          canvas.drawCircle(Offset(px, py), 3, glintPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CrackOverlayPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.coreReveal != coreReveal ||
      oldDelegate.shardGlint != shardGlint ||
      oldDelegate.isRetro != isRetro;
}

class _AngryEyeGlitchPainter extends CustomPainter {
  _AngryEyeGlitchPainter({required this.flicker, required this.isRetro});

  final double flicker;
  final bool isRetro;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.46;
    final paint = Paint()..color = const Color(0xFFD32F2F).withValues(alpha: flicker);
    if (isRetro) {
      canvas.drawRect(Rect.fromCenter(center: Offset(cx - 22, cy), width: 10, height: 8), paint);
      canvas.drawRect(Rect.fromCenter(center: Offset(cx + 18, cy), width: 10, height: 8), paint);
    } else {
      canvas.drawOval(Rect.fromCenter(center: Offset(cx - 22, cy), width: 12, height: 9), paint);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + 18, cy), width: 12, height: 9), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AngryEyeGlitchPainter oldDelegate) =>
      oldDelegate.flicker != flicker || oldDelegate.isRetro != isRetro;
}

class _FragmentPainter extends CustomPainter {
  _FragmentPainter({
    required this.fragments,
    required this.timeMs,
    required this.isRetro,
    required this.fade,
  });

  final List<_ShellFragment> fragments;
  final double timeMs;
  final bool isRetro;
  final double fade;

  double _phase(double start, double end) {
    if (timeMs <= start) return 0;
    if (timeMs >= end) return 1;
    return (timeMs - start) / (end - start);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.52;
    final crackProgress = Curves.easeIn.transform(_phase(1000, 3000));
    final orbitPhase = _phase(5500, 7500);
    final collapse = Curves.easeIn.transform(_phase(7500, 9200));
    final explode = Curves.easeOutCubic.transform(_phase(9200, 10200));
    final settle = _phase(12500, 14000);

    for (final f in fragments) {
      late Offset pos;
      late double alpha;

      if (timeMs < 5500) {
        final angle = f.orbitAngle;
        final r = f.orbitRadius * 0.55 * (0.85 + crackProgress * 0.2);
        pos = Offset(cx + math.cos(angle) * r, cy + math.sin(angle) * r);
        alpha = crackProgress * 0.7;
      } else if (timeMs < 7500) {
        final t = Curves.easeOut.transform(orbitPhase);
        final angle = f.orbitAngle + t * f.orbitSpeed * math.pi * 3;
        final r = f.orbitRadius * (0.75 + t * 0.35);
        pos = Offset(cx + math.cos(angle) * r, cy + math.sin(angle) * r * 0.9);
        alpha = 0.75 + t * 0.2;
      } else if (timeMs < 9200) {
        final spiralAngle = f.orbitAngle + collapse * f.orbitSpeed * 6;
        final r = f.orbitRadius * (1 - collapse * 0.94);
        pos = Offset(
          cx + math.cos(spiralAngle) * r,
          cy + math.sin(spiralAngle) * r * 0.82,
        );
        alpha = 0.7 + collapse * 0.3;
      } else if (timeMs < 12500) {
        final angle = f.orbitAngle;
        final dist = explode * f.blastDistance;
        final fall = explode * 28 * _phase(9600, 12000);
        pos = Offset(
          cx + math.cos(angle) * dist,
          cy + math.sin(angle) * dist * 0.75 + fall,
        );
        alpha = (1 - explode * 0.35) * fade;
      } else {
        final angle = f.orbitAngle;
        final dist = f.blastDistance * 0.85;
        pos = Offset(
          cx + math.cos(angle) * dist,
          cy + math.sin(angle) * dist * 0.6 + 40 + settle * 20,
        );
        alpha = (1 - settle) * fade * 0.4;
      }

      if (alpha <= 0.02) continue;
      final paint = Paint()..color = f.color.withValues(alpha: alpha.clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(f.rotation + collapse * 2);
      if (isRetro) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: f.size, height: f.size * 0.85),
          paint,
        );
      } else {
        final path = Path()
          ..moveTo(-f.size * 0.5, 0)
          ..lineTo(0, -f.size * 0.6)
          ..lineTo(f.size * 0.5, 0)
          ..lineTo(0, f.size * 0.5)
          ..close();
        canvas.drawPath(path, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FragmentPainter oldDelegate) =>
      oldDelegate.timeMs != timeMs ||
      oldDelegate.fade != fade ||
      oldDelegate.isRetro != isRetro;
}

class _EnergyRingPainter extends CustomPainter {
  _EnergyRingPainter({
    required this.intensity,
    required this.timeMs,
    required this.isRetro,
    required this.fade,
  });

  final double intensity;
  final double timeMs;
  final bool isRetro;
  final double fade;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0) return;
    final cx = size.width * 0.5;
    final cy = size.height * 0.54;
    for (var i = 0; i < 3; i++) {
      final pulse = (timeMs / 180 + i * 0.35) % 1.0;
      final radius = 40 + pulse * 90 + i * 22;
      final alpha = intensity * fade * (1 - pulse) * 0.55;
      final paint = Paint()
        ..color = (i.isEven ? const Color(0xFF7B1FA2) : const Color(0xFF558B2F))
            .withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isRetro ? 4 : 3;
      if (isRetro) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy), width: radius * 2, height: radius * 1.6),
          paint,
        );
      } else {
        canvas.drawCircle(Offset(cx, cy), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EnergyRingPainter oldDelegate) =>
      oldDelegate.intensity != intensity ||
      oldDelegate.timeMs != timeMs ||
      oldDelegate.fade != fade;
}

class _SuctionSpiralPainter extends CustomPainter {
  _SuctionSpiralPainter({
    required this.particles,
    required this.progress,
    required this.timeMs,
    required this.isRetro,
    required this.fade,
  });

  final List<_SuctionParticle> particles;
  final double progress;
  final double timeMs;
  final bool isRetro;
  final double fade;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final cx = size.width * 0.5;
    final cy = size.height * 0.54;
    for (final p in particles) {
      final spiral = p.startAngle + progress * (4 + p.spiralOffset) + timeMs / 200;
      final r = p.startRadius * (1 - progress * 0.96);
      final pos = Offset(
        cx + math.cos(spiral) * r,
        cy + math.sin(spiral) * r * 0.85,
      );
      final alpha = progress * fade * 0.75;
      final paint = Paint()..color = p.color.withValues(alpha: alpha);
      if (isRetro) {
        canvas.drawRect(
          Rect.fromCenter(center: pos, width: p.size, height: p.size),
          paint,
        );
      } else {
        canvas.drawCircle(pos, p.size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SuctionSpiralPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.timeMs != timeMs ||
      oldDelegate.fade != fade;
}

class _ExplosionSmokePainter extends CustomPainter {
  _ExplosionSmokePainter({
    required this.smoke,
    required this.explosion,
    required this.harvest,
    required this.shockwave,
    required this.timeMs,
    required this.isRetro,
    required this.fade,
  });

  final List<_SmokePuff> smoke;
  final double explosion;
  final double harvest;
  final double shockwave;
  final double timeMs;
  final bool isRetro;
  final double fade;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.52;

    if (shockwave > 0) {
      final paint = Paint()
        ..color = const Color(0xFFAB47BC).withValues(alpha: (1 - shockwave) * explosion * fade * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isRetro ? 6 : 4;
      final r = shockwave * size.width * 0.55;
      if (isRetro) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 1.5),
          paint,
        );
      } else {
        canvas.drawCircle(Offset(cx, cy), r, paint);
      }
    }

    if (explosion <= 0 && harvest <= 0) return;

    for (final puff in smoke) {
      final expand = explosion * 1.2 + harvest * 0.35;
      final dist = puff.distance * expand;
      final pos = Offset(
        cx + math.cos(puff.angle) * dist,
        cy + math.sin(puff.angle) * dist * 0.7 - harvest * 18,
      );
      final alpha = (explosion * 0.55 + harvest * 0.25) * fade;
      final paint = Paint()..color = puff.color.withValues(alpha: alpha.clamp(0.0, 0.65));
      if (isRetro) {
        canvas.drawRect(
          Rect.fromCenter(
            center: pos,
            width: puff.size * (0.8 + expand * 0.5),
            height: puff.size * (0.65 + expand * 0.4),
          ),
          paint,
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(
            center: pos,
            width: puff.size * (1 + expand * 0.6),
            height: puff.size * (0.75 + expand * 0.45),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ExplosionSmokePainter oldDelegate) =>
      oldDelegate.explosion != explosion ||
      oldDelegate.harvest != harvest ||
      oldDelegate.shockwave != shockwave ||
      oldDelegate.fade != fade;
}

class _EggShardHarvestPainter extends CustomPainter {
  _EggShardHarvestPainter({
    required this.shards,
    required this.explosion,
    required this.harvest,
    required this.timeMs,
    required this.isRetro,
    required this.fade,
  });

  final List<_EggShardVisual> shards;
  final double explosion;
  final double harvest;
  final double timeMs;
  final bool isRetro;
  final double fade;

  @override
  void paint(Canvas canvas, Size size) {
    if (explosion <= 0 && harvest <= 0) return;
    final cx = size.width * 0.5;
    final cy = size.height * 0.52;
    final rewardY = size.height * 0.22;

    for (final shard in shards) {
      final localHarvest = ((harvest - shard.delay) / (1 - shard.delay)).clamp(0.0, 1.0);
      if (localHarvest <= 0 && explosion < 0.15) continue;

      final blast = Curves.easeOut.transform(
        (explosion - shard.delay * 0.3).clamp(0.0, 1.0),
      );
      final spiralAngle =
          shard.angle + localHarvest * shard.spiralTurns * math.pi * 2;
      final blastDist = shard.distance * blast * 1.4;
      final rise = localHarvest * (rewardY - cy + 40);
      final pullToReward = Curves.easeInOut.transform(localHarvest);

      var pos = Offset(
        cx + math.cos(spiralAngle) * blastDist * (1 - pullToReward * 0.65),
        cy + math.sin(spiralAngle) * blastDist * 0.5 - rise,
      );
      pos = Offset(
        pos.dx + (cx - pos.dx) * pullToReward * 0.15,
        pos.dy + (rewardY - pos.dy) * pullToReward * 0.35,
      );

      final sparkle = 0.55 + math.sin(timeMs / 80 + shard.angle * 3) * 0.35;
      final alpha = (blast * 0.5 + localHarvest * 0.5) * fade * sparkle;
      if (alpha <= 0.03) continue;

      final body = Paint()
        ..color = const Color(0xFFE8F5E9).withValues(alpha: alpha);
      final edge = Paint()
        ..color = const Color(0xFFFFF59D).withValues(alpha: alpha * 0.9);
      final core = Paint()
        ..color = const Color(0xFF9CCC65).withValues(alpha: alpha);

      if (isRetro) {
        canvas.drawRect(
          Rect.fromCenter(
            center: pos,
            width: shard.size,
            height: shard.size * 1.15,
          ),
          body,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: pos + const Offset(0, -1),
            width: shard.size * 0.45,
            height: shard.size * 0.45,
          ),
          core,
        );
      } else {
        final path = Path()
          ..moveTo(pos.dx, pos.dy - shard.size * 0.55)
          ..lineTo(pos.dx + shard.size * 0.42, pos.dy)
          ..lineTo(pos.dx, pos.dy + shard.size * 0.55)
          ..lineTo(pos.dx - shard.size * 0.42, pos.dy)
          ..close();
        canvas.drawPath(path, body);
        canvas.drawPath(path, edge..style = PaintingStyle.stroke..strokeWidth = 1.2);
        canvas.drawCircle(pos, shard.size * 0.18, core);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EggShardHarvestPainter oldDelegate) =>
      oldDelegate.explosion != explosion ||
      oldDelegate.harvest != harvest ||
      oldDelegate.timeMs != timeMs ||
      oldDelegate.fade != fade;
}

class _ToxicFumePainter extends CustomPainter {
  _ToxicFumePainter({
    required this.expand,
    required this.burst,
    required this.isRetro,
    required this.fade,
  });

  final double expand;
  final double burst;
  final bool isRetro;
  final double fade;

  @override
  void paint(Canvas canvas, Size size) {
    if (expand <= 0 && burst <= 0) return;
    final cx = size.width * 0.5;
    final cy = size.height * 0.58;
    for (var i = 0; i < 10; i++) {
      final angle = i * math.pi / 5;
      final radius = (36 + expand * 100 + burst * 90) * (0.75 + i * 0.04);
      final color = i.isEven
          ? const Color(0xFF66BB6A)
          : const Color(0xFF8E24AA);
      final alpha = (0.18 + expand * 0.22 + burst * 0.25) * fade;
      final center = Offset(
        cx + math.cos(angle) * radius * 0.32,
        cy + math.sin(angle) * radius * 0.22,
      );
      final paint = Paint()..color = color.withValues(alpha: alpha);
      if (isRetro) {
        canvas.drawRect(
          Rect.fromCenter(
            center: center,
            width: 22 + expand * 18,
            height: 16 + expand * 14,
          ),
          paint,
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: 26 + expand * 22,
            height: 18 + expand * 16,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ToxicFumePainter oldDelegate) =>
      oldDelegate.expand != expand ||
      oldDelegate.burst != burst ||
      oldDelegate.fade != fade;
}
