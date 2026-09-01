import 'dart:math' as math;

import 'package:flutter/material.dart';

class BattleImpactOverlay extends StatelessWidget {
  const BattleImpactOverlay({
    super.key,
    required this.position,
    required this.progress,
    required this.color,
    required this.intensity,
    required this.reducedEffects,
  });

  final Offset position;
  final double progress;
  final Color color;
  final double intensity;
  final bool reducedEffects;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        key: const ValueKey('battle-impact-painter'),
        painter: _BattleImpactPainter(
          position: position,
          progress: progress.clamp(0, 1),
          color: color,
          intensity: intensity.clamp(0, 1),
          reducedEffects: reducedEffects,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _BattleImpactPainter extends CustomPainter {
  const _BattleImpactPainter({
    required this.position,
    required this.progress,
    required this.color,
    required this.intensity,
    required this.reducedEffects,
  });

  final Offset position;
  final double progress;
  final Color color;
  final double intensity;
  final bool reducedEffects;

  @override
  void paint(Canvas canvas, Size size) {
    final fade = (1 - progress) * intensity;
    if (fade <= 0) return;

    final center = Offset(
      position.dx.clamp(0, size.width),
      position.dy.clamp(0, size.height),
    );
    final ringRadius = 8 + 42 * Curves.easeOut.transform(progress);
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..color = color.withValues(alpha: fade * 0.72)
        ..strokeWidth = reducedEffects ? 2 : 3.5
        ..style = PaintingStyle.stroke,
    );

    if (!reducedEffects) {
      final rayPaint = Paint()
        ..color = color.withValues(alpha: fade * 0.82)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 10; i++) {
        final angle = math.pi * 2 * i / 10 + 0.18;
        final inner = ringRadius * 0.72;
        final outer = ringRadius * (1.2 + (i.isEven ? 0.22 : 0));
        canvas.drawLine(
          center + Offset(math.cos(angle) * inner, math.sin(angle) * inner),
          center + Offset(math.cos(angle) * outer, math.sin(angle) * outer),
          rayPaint,
        );
      }
    }

    canvas.drawCircle(
      center,
      18 * (1 - progress),
      Paint()
        ..color = Colors.white.withValues(
          alpha: fade * (reducedEffects ? 0.12 : 0.34),
        )
        ..maskFilter = reducedEffects
            ? null
            : const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = color.withValues(
          alpha: fade * (reducedEffects ? 0.018 : 0.055),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _BattleImpactPainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.intensity != intensity ||
        oldDelegate.reducedEffects != reducedEffects;
  }
}
