import 'package:flutter/material.dart';

import '../models/animal_sprite_theme.dart';
import '../utils/boss_visual_config.dart';
import 'animal_sprite_theme_scope.dart';

class BossAttackTelegraph extends StatelessWidget {
  const BossAttackTelegraph({
    super.key,
    required this.bossId,
    required this.progress,
    required this.width,
    required this.height,
    required this.reducedEffects,
  });

  final String bossId;
  final double progress;
  final double width;
  final double height;
  final bool reducedEffects;

  @override
  Widget build(BuildContext context) {
    final theme = AnimalSpriteThemeScope.of(context);
    return IgnorePointer(
      child: ExcludeSemantics(
        child: CustomPaint(
          size: Size(width, height),
          painter: _BossAttackTelegraphPainter(
            type: BossVisualConfig.projectileTypeForBossId(bossId),
            progress: progress,
            pixelated: theme.id == AnimalSpriteThemes.retroPixel.id,
            reducedEffects: reducedEffects,
          ),
        ),
      ),
    );
  }
}

class _BossAttackTelegraphPainter extends CustomPainter {
  const _BossAttackTelegraphPainter({
    required this.type,
    required this.progress,
    required this.pixelated,
    required this.reducedEffects,
  });

  final BossProjectileVisualType type;
  final double progress;
  final bool pixelated;
  final bool reducedEffects;

  Color get _color => switch (type) {
    BossProjectileVisualType.slimeGlob => const Color(0xFF8CFF74),
    BossProjectileVisualType.rockEgg => const Color(0xFFFFC46B),
    BossProjectileVisualType.shadowFeather => const Color(0xFFB388FF),
    BossProjectileVisualType.royalSlime => const Color(0xFF64FFDA),
    BossProjectileVisualType.guardianShard => const Color(0xFF80D8FF),
    BossProjectileVisualType.phoenixFlame => const Color(0xFFFF8A65),
    BossProjectileVisualType.rottenEgg => const Color(0xFFB2FF59),
    BossProjectileVisualType.rottenShell => const Color(0xFFEA80FC),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.clamp(0.0, 1.0);
    final pulse = reducedEffects ? 0.75 : 0.55 + p * 0.45;
    final color = _color;
    final laneRect = Offset.zero & size;

    if (pixelated) {
      final block = (size.width / 6).clamp(3.0, 8.0);
      final lane = Paint()..color = color.withValues(alpha: 0.08 + p * 0.1);
      for (var y = 0.0; y < size.height; y += block * 2) {
        canvas.drawRect(
          Rect.fromLTWH(size.width * 0.25, y, size.width * 0.5, block),
          lane,
        );
      }
      final marker = Paint()..color = color.withValues(alpha: 0.6 * pulse);
      canvas.drawRect(
        Rect.fromLTWH(0, size.height - block * 2, size.width, block * 2),
        marker,
      );
      canvas.drawRect(
        Rect.fromLTWH(size.width * 0.42, 0, size.width * 0.16, block),
        marker,
      );
      return;
    }

    canvas.drawRect(
      laneRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.02),
            color.withValues(alpha: 0.08 + p * 0.08),
            color.withValues(alpha: 0.2 + p * 0.12),
          ],
        ).createShader(laneRect),
    );

    final dashed = Paint()
      ..color = color.withValues(alpha: 0.5 * pulse)
      ..strokeWidth = 2;
    for (var y = 4.0; y < size.height - 30; y += 15) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + 7),
        dashed,
      );
    }

    final danger = Paint()
      ..color = color.withValues(alpha: 0.68 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 12),
        width: size.width * (0.72 + p * 0.18),
        height: 17,
      ),
      danger,
    );
    final triangle = Path()
      ..moveTo(size.width / 2, size.height - 28)
      ..lineTo(size.width / 2 - 6, size.height - 18)
      ..lineTo(size.width / 2 + 6, size.height - 18)
      ..close();
    canvas.drawPath(triangle, Paint()..color = color.withValues(alpha: pulse));
  }

  @override
  bool shouldRepaint(covariant _BossAttackTelegraphPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.progress != progress ||
        oldDelegate.pixelated != pixelated ||
        oldDelegate.reducedEffects != reducedEffects;
  }
}
