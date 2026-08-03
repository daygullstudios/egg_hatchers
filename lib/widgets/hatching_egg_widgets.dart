import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/egg.dart';
import 'game_sprite.dart';

/// Crack lines drawn over an egg sprite or emoji.
class EggCrackMarks extends StatelessWidget {
  const EggCrackMarks({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EggCrackPainter(),
      ),
    );
  }
}

class _EggCrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown.shade700
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.width / 88;

    canvas.drawLine(
      Offset(cx - 8 * scale, cy - 20 * scale),
      Offset(cx + 4 * scale, cy + 2 * scale),
      paint,
    );
    canvas.drawLine(
      Offset(cx + 6 * scale, cy - 18 * scale),
      Offset(cx - 6 * scale, cy + 6 * scale),
      paint,
    );
    canvas.drawLine(
      Offset(cx - 2 * scale, cy + 4 * scale),
      Offset(cx + 10 * scale, cy + 18 * scale),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// One egg sprite/emoji with optional crack overlay.
class AnimatedHatchingEgg extends StatelessWidget {
  const AnimatedHatchingEgg({
    super.key,
    required this.egg,
    required this.size,
    this.showCracks = false,
  });

  final Egg egg;
  final double size;
  final bool showCracks;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        GameEggSprite(
          egg: egg,
          size: size,
          semanticLabel: egg.name,
          emojiFontSize: size * 0.92,
        ),
        if (showCracks) EggCrackMarks(size: size),
      ],
    );
  }
}

/// Three eggs in a row with slightly staggered shake motion.
class AnimatedTripleEggRow extends StatelessWidget {
  const AnimatedTripleEggRow({
    super.key,
    required this.egg,
    required this.eggSize,
    required this.showCracks,
    required this.shakeAmount,
    required this.shakePhase,
    this.spacing = 10,
  });

  final Egg egg;
  final double eggSize;
  final bool showCracks;
  final double shakeAmount;
  final double shakePhase;
  final double spacing;

  static const _staggerPhases = [0.0, 0.35, 0.7];
  static const _wiggleFactors = [1.0, 1.15, 0.9];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          _StaggeredEgg(
            egg: egg,
            size: eggSize,
            showCracks: showCracks,
            shakeAmount: shakeAmount,
            phaseOffset: _staggerPhases[i],
            shakePhase: shakePhase,
            wiggleFactor: _wiggleFactors[i],
          ),
        ],
      ],
    );
  }
}

class _StaggeredEgg extends StatelessWidget {
  const _StaggeredEgg({
    required this.egg,
    required this.size,
    required this.showCracks,
    required this.shakeAmount,
    required this.phaseOffset,
    required this.shakePhase,
    required this.wiggleFactor,
  });

  final Egg egg;
  final double size;
  final bool showCracks;
  final double shakeAmount;
  final double phaseOffset;
  final double shakePhase;
  final double wiggleFactor;

  @override
  Widget build(BuildContext context) {
    final wave = math.sin((shakePhase + phaseOffset) * math.pi * 2);
    final horizontal = shakeAmount * wiggleFactor * wave;
    final vertical = showCracks
        ? shakeAmount * 0.15 * math.cos(shakePhase * math.pi * 2).toDouble()
        : 0.0;

    return Transform.translate(
      offset: Offset(horizontal, vertical),
      child: AnimatedHatchingEgg(
        egg: egg,
        size: size,
        showCracks: showCracks,
      ),
    );
  }
}
