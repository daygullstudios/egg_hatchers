import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/retro_pixel_boss_projectiles.dart';
import '../models/animal_sprite_theme.dart';
import '../utils/boss_visual_config.dart';
import 'animal_sprite_theme_scope.dart';
import 'realistic_boss_projectile.dart';
import 'retro_pixel_sprite.dart';
import 'rotten_egg_projectile.dart';

/// Boss-specific falling projectile visual (same hitbox as rotten egg).
class BossProjectileWidget extends StatelessWidget {
  const BossProjectileWidget({super.key, required this.bossId, this.size = 22});

  final String bossId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final type = BossVisualConfig.projectileTypeForBossId(bossId);
    final animalTheme = AnimalSpriteThemeScope.of(context);
    final isRetroPixel = animalTheme.id == AnimalSpriteThemes.retroPixel.id;
    final projectile = _buildProjectile(type: type, animalTheme: animalTheme);

    return RepaintBoundary(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          CustomPaint(
            key: ValueKey('boss-projectile-trail-$bossId'),
            size: Size(size, size * 1.12),
            painter: _ProjectileTrailPainter(
              type: type,
              pixelated: isRetroPixel,
            ),
          ),
          projectile,
        ],
      ),
    );
  }

  Widget _buildProjectile({
    required BossProjectileVisualType type,
    required AnimalSpriteTheme animalTheme,
  }) {
    if (type == BossProjectileVisualType.rottenEgg) {
      return RottenEggProjectile(size: size);
    }

    if (animalTheme.id == AnimalSpriteThemes.realistic.id) {
      return RealisticBossProjectile(type: type, size: size);
    }

    if (animalTheme.id == AnimalSpriteThemes.retroPixel.id) {
      final pixelArt = RetroPixelBossProjectiles.forType(type);
      if (pixelArt != null) {
        return RetroPixelSprite(definition: pixelArt, size: size);
      }
    }

    return SizedBox(
      width: size,
      height: size * 1.12,
      child: CustomPaint(
        size: Size(size, size * 1.12),
        painter: _BossProjectilePainter(type: type),
      ),
    );
  }
}

class _ProjectileTrailPainter extends CustomPainter {
  const _ProjectileTrailPainter({required this.type, required this.pixelated});

  final BossProjectileVisualType type;
  final bool pixelated;

  Color get _color => switch (type) {
    BossProjectileVisualType.slimeGlob => const Color(0xFF69F0AE),
    BossProjectileVisualType.rockEgg => const Color(0xFFFFCC80),
    BossProjectileVisualType.shadowFeather => const Color(0xFFB388FF),
    BossProjectileVisualType.royalSlime => const Color(0xFF64FFDA),
    BossProjectileVisualType.guardianShard => const Color(0xFF80D8FF),
    BossProjectileVisualType.phoenixFlame => const Color(0xFFFFAB40),
    BossProjectileVisualType.rottenEgg => const Color(0xFF76FF03),
    BossProjectileVisualType.rottenShell => const Color(0xFFCE93D8),
  };

  @override
  void paint(Canvas canvas, Size size) {
    if (pixelated) {
      _paintPixelTrail(canvas, size);
      return;
    }

    final centerX = size.width / 2;
    final trailLength = size.height * 1.7;
    final glowPath = Path()
      ..moveTo(centerX, size.height * 0.48)
      ..cubicTo(
        centerX - size.width * 0.34,
        -trailLength * 0.2,
        centerX + size.width * 0.24,
        -trailLength * 0.62,
        centerX,
        -trailLength,
      );
    canvas.drawPath(
      glowPath,
      Paint()
        ..color = _color.withValues(alpha: 0.3)
        ..strokeWidth = size.width * 0.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.3),
    );
    canvas.drawPath(
      glowPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [_color.withValues(alpha: 0.8), _color.withValues(alpha: 0)],
        ).createShader(Rect.fromLTRB(0, -trailLength, size.width, size.height))
        ..strokeWidth = size.width * 0.16
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    final particlePaint = Paint()..color = _color.withValues(alpha: 0.65);
    canvas.drawCircle(
      Offset(centerX - size.width * 0.34, -size.height * 0.34),
      size.width * 0.09,
      particlePaint,
    );
    canvas.drawCircle(
      Offset(centerX + size.width * 0.28, -size.height * 0.72),
      size.width * 0.055,
      particlePaint..color = _color.withValues(alpha: 0.4),
    );
  }

  void _paintPixelTrail(Canvas canvas, Size size) {
    final unit = math.max(2.0, (size.width / 7).floorToDouble());
    final centerX = (size.width / 2 / unit).round() * unit;
    final paint = Paint()..color = _color.withValues(alpha: 0.78);
    final blocks = <(double, double, double)>[
      (centerX - unit, -unit, unit * 2),
      (centerX, -unit * 3, unit),
      (centerX - unit * 2, -unit * 5, unit),
      (centerX + unit, -unit * 7, unit),
      (centerX, -unit * 9, unit),
    ];
    for (var i = 0; i < blocks.length; i++) {
      final (x, y, width) = blocks[i];
      paint.color = _color.withValues(alpha: 0.78 - i * 0.13);
      canvas.drawRect(Rect.fromLTWH(x, y, width, unit), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProjectileTrailPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.pixelated != pixelated;
  }
}

class _BossProjectilePainter extends CustomPainter {
  _BossProjectilePainter({required this.type});

  final BossProjectileVisualType type;

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case BossProjectileVisualType.slimeGlob:
        _paintSlimeGlob(canvas, size);
      case BossProjectileVisualType.rockEgg:
        _paintRockEgg(canvas, size);
      case BossProjectileVisualType.shadowFeather:
        _paintShadowFeather(canvas, size);
      case BossProjectileVisualType.royalSlime:
        _paintRoyalSlime(canvas, size);
      case BossProjectileVisualType.guardianShard:
        _paintGuardianShard(canvas, size);
      case BossProjectileVisualType.phoenixFlame:
        _paintPhoenixFlame(canvas, size);
      case BossProjectileVisualType.rottenShell:
        _paintRottenShell(canvas, size);
      case BossProjectileVisualType.rottenEgg:
        break;
    }
  }

  void _paintRottenShell(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.54);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.8,
        height: size.height * 0.82,
      ),
      Paint()
        ..shader =
            const RadialGradient(
              colors: [Color(0xFFDCEDC8), Color(0xFF81C784), Color(0xFF6A1B9A)],
            ).createShader(
              Rect.fromCircle(center: center, radius: size.width * 0.45),
            ),
    );
    final crack = Paint()
      ..color = const Color(0xFF1B5E20)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.35, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.55),
      crack,
    );
    canvas.drawLine(
      Offset(size.width * 0.65, size.height * 0.32),
      Offset(size.width * 0.52, size.height * 0.58),
      crack,
    );
    canvas.drawCircle(
      Offset(size.width * 0.42, size.height * 0.46),
      size.width * 0.06,
      Paint()..color = const Color(0xFFE53935).withValues(alpha: 0.85),
    );
  }

  void _paintSlimeGlob(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.54);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFFA5D6A7), Color(0xFF66BB6A), Color(0xFF388E3C)],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.5));
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.82,
        height: size.height * 0.78,
      ),
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.38, size.height * 0.42),
      size.width * 0.08,
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  void _paintRockEgg(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.54);
    final shell = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFFD7CCC8), Color(0xFF8D6E63), Color(0xFF5D4037)],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.5));
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.78,
        height: size.height * 0.82,
      ),
      shell,
    );
    final crack = Paint()
      ..color = const Color(0xFF3E2723)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.4, size.height * 0.28)
      ..lineTo(size.width * 0.5, size.height * 0.45)
      ..lineTo(size.width * 0.42, size.height * 0.58);
    canvas.drawPath(path, crack);
  }

  void _paintShadowFeather(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.52);
    final featherPaint = Paint()..color = const Color(0xFF311B92);
    final path = Path()
      ..moveTo(center.dx, center.dy - size.height * 0.35)
      ..quadraticBezierTo(
        center.dx + size.width * 0.42,
        center.dy,
        center.dx,
        center.dy + size.height * 0.35,
      )
      ..quadraticBezierTo(
        center.dx - size.width * 0.42,
        center.dy,
        center.dx,
        center.dy - size.height * 0.35,
      );
    canvas.drawPath(path, featherPaint);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.62, size.height * 0.48),
        width: size.width * 0.35,
        height: size.height * 0.55,
      ),
      Paint()..color = const Color(0xFF1A237E).withValues(alpha: 0.85),
    );
  }

  void _paintRoyalSlime(Canvas canvas, Size size) {
    _paintSlimeGlob(canvas, size);
    final crown = Paint()..color = const Color(0xFFFFD54F);
    final cx = size.width / 2;
    final top = size.height * 0.22;
    final path = Path()
      ..moveTo(cx - size.width * 0.22, top + 8)
      ..lineTo(cx - size.width * 0.12, top)
      ..lineTo(cx, top + 6)
      ..lineTo(cx + size.width * 0.12, top)
      ..lineTo(cx + size.width * 0.22, top + 8)
      ..lineTo(cx + size.width * 0.18, top + 12)
      ..lineTo(cx - size.width * 0.18, top + 12)
      ..close();
    canvas.drawPath(path, crown);
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.38),
      2,
      Paint()..color = const Color(0xFFFFEB3B),
    );
  }

  void _paintGuardianShard(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.54);
    final shard = Path()
      ..moveTo(center.dx, center.dy - size.height * 0.32)
      ..lineTo(center.dx + size.width * 0.28, center.dy + size.height * 0.08)
      ..lineTo(center.dx, center.dy + size.height * 0.32)
      ..lineTo(center.dx - size.width * 0.28, center.dy + size.height * 0.08)
      ..close();
    canvas.drawPath(
      shard,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const [
                Color(0xFFFFF8E1),
                Color(0xFFFFD54F),
                Color(0xFF8D6E63),
              ],
            ).createShader(
              Rect.fromCircle(center: center, radius: size.width * 0.4),
            ),
    );
    canvas.drawPath(
      shard,
      Paint()
        ..color = const Color(0xFF42A5F5).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _paintPhoenixFlame(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.56);
    final flame = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFF64B5F6), Color(0xFF1565C0), Color(0xFF0D47A1)],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.5));

    for (var i = 0; i < 3; i++) {
      final angle = -math.pi / 2 + (i - 1) * 0.35;
      final tip = Offset(
        center.dx + math.cos(angle) * size.width * 0.08,
        center.dy + math.sin(angle) * size.height * 0.38,
      );
      final path = Path()
        ..moveTo(center.dx - size.width * 0.18, center.dy + size.height * 0.1)
        ..quadraticBezierTo(center.dx, tip.dy, tip.dx, tip.dy)
        ..quadraticBezierTo(
          center.dx + size.width * 0.18,
          center.dy + size.height * 0.1,
          center.dx - size.width * 0.18,
          center.dy + size.height * 0.1,
        );
      canvas.drawPath(path, flame);
    }
  }

  @override
  bool shouldRepaint(covariant _BossProjectilePainter oldDelegate) =>
      oldDelegate.type != type;
}
