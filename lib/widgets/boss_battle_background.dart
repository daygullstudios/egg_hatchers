import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/animal_sprite_theme.dart';
import '../utils/boss_visual_config.dart';
import 'animal_sprite_theme_scope.dart';
import 'realistic_boss_battle_background.dart';
import 'retro_pixel_boss_battle_background.dart';

/// Full-arena boss-specific battle background for manual battles.
class BossBattleBackground extends StatelessWidget {
  const BossBattleBackground({
    super.key,
    required this.bossId,
    this.showOverlay = true,
  });

  final String bossId;
  final bool showOverlay;

  @override
  Widget build(BuildContext context) {
    final animalTheme = AnimalSpriteThemeScope.of(context);
    if (animalTheme.id == AnimalSpriteThemes.retroPixel.id) {
      return RetroPixelBossBattleBackground(
        bossId: bossId,
        showOverlay: showOverlay,
      );
    }
    if (animalTheme.id == AnimalSpriteThemes.realistic.id) {
      return RealisticBossBattleBackground(
        bossId: bossId,
        showOverlay: showOverlay,
      );
    }

    final type = BossVisualConfig.backgroundTypeForBossId(bossId);
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _BossBattleBackgroundPainter(type: type)),
        if (showOverlay)
          ColoredBox(
            color: Colors.black.withValues(alpha: _overlayAlpha(type)),
          ),
      ],
    );
  }

  static double _overlayAlpha(BossBattleBackgroundType type) {
    return switch (type) {
      BossBattleBackgroundType.royalPalace => 0.18,
      BossBattleBackgroundType.guardianNest => 0.22,
      BossBattleBackgroundType.phoenixLair => 0.12,
      BossBattleBackgroundType.slimeSwamp => 0.15,
      _ => 0.2,
    };
  }
}

class _BossBattleBackgroundPainter extends CustomPainter {
  _BossBattleBackgroundPainter({required this.type});

  final BossBattleBackgroundType type;

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case BossBattleBackgroundType.slimeSwamp:
        _paintSlimeSwamp(canvas, size);
      case BossBattleBackgroundType.eggCave:
        _paintEggCave(canvas, size);
      case BossBattleBackgroundType.shadowRoost:
        _paintShadowRoost(canvas, size);
      case BossBattleBackgroundType.royalPalace:
        _paintRoyalPalace(canvas, size);
      case BossBattleBackgroundType.guardianNest:
        _paintGuardianNest(canvas, size);
      case BossBattleBackgroundType.phoenixLair:
        _paintPhoenixLair(canvas, size);
      case BossBattleBackgroundType.rottenNest:
        _paintRottenNest(canvas, size);
      case BossBattleBackgroundType.genericArena:
        _paintGenericArena(canvas, size);
    }
    _paintClassicFinish(canvas, size);
  }

  void _paintClassicFinish(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // A soft stage light keeps the combat lane readable and grounds both sprites.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.84),
        width: size.width * 0.72,
        height: size.height * 0.18,
      ),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.13),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );

    final horizon = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(0, size.height * 0.66),
      Offset(size.width, size.height * 0.66),
      horizon,
    );

    // Gentle edge shading adds depth without making Classic look realistic.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.black.withValues(alpha: 0.18),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.18),
          ],
          stops: const [0, 0.18, 0.82, 1],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.12),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.16),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );

    final speck = Paint()..color = Colors.white.withValues(alpha: 0.12);
    final random = math.Random(type.index * 37 + 11);
    for (var i = 0; i < 10; i++) {
      canvas.drawCircle(
        Offset(
          size.width * (0.08 + random.nextDouble() * 0.84),
          size.height * (0.15 + random.nextDouble() * 0.48),
        ),
        1.2 + random.nextDouble() * 1.8,
        speck,
      );
    }
  }

  void _paintSlimeSwamp(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B5E20), Color(0xFF33691E), Color(0xFF2E4F1C)],
        ).createShader(rect),
    );

    final distant = Paint()
      ..color = const Color(0xFF123F25).withValues(alpha: 0.72);
    for (var i = 0; i < 6; i++) {
      final x = size.width * (-0.04 + i * 0.21);
      final crownY = size.height * (0.4 + (i % 2) * 0.035);
      canvas.drawCircle(Offset(x, crownY), 42 + (i % 3) * 8, distant);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x, size.height * 0.57),
          width: 13,
          height: size.height * 0.28,
        ),
        distant,
      );
    }

    final puddle = Paint()
      ..color = const Color(0xFF66BB6A).withValues(alpha: 0.45);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.28, size.height * 0.72),
        width: size.width * 0.42,
        height: 28,
      ),
      puddle,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.72, size.height * 0.82),
        width: size.width * 0.35,
        height: 22,
      ),
      puddle,
    );

    final bubble = Paint()
      ..color = const Color(0xFFA5D6A7).withValues(alpha: 0.35);
    for (var i = 0; i < 8; i++) {
      final x = size.width * (0.12 + i * 0.11);
      final y = size.height * (0.18 + (i % 3) * 0.12);
      canvas.drawCircle(Offset(x, y), 4 + (i % 3) * 2.0, bubble);
    }

    final reed = Paint()
      ..color = const Color(0xFF173F23).withValues(alpha: 0.85)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final x in [0.06, 0.11, 0.87, 0.93]) {
      final base = Offset(size.width * x, size.height * 0.86);
      canvas.drawLine(base, Offset(base.dx - 5, size.height * 0.68), reed);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(base.dx - 6, size.height * 0.67),
          width: 8,
          height: 22,
        ),
        reed,
      );
    }
  }

  void _paintEggCave(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4E342E), Color(0xFF3E2723), Color(0xFF2C1810)],
        ).createShader(rect),
    );

    final caveEdge = Paint()..color = const Color(0xFF24130E);
    final ceiling = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.08,
        size.width * 0.55,
        size.height * 0.2,
      )
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.06,
        0,
        size.height * 0.24,
      )
      ..close();
    canvas.drawPath(ceiling, caveEdge);

    final stone = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.55);
    for (var i = 0; i < 6; i++) {
      final x = size.width * (0.08 + i * 0.16);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height * 0.55, 28, 36 + (i % 2) * 8.0),
          const Radius.circular(6),
        ),
        stone,
      );
    }

    final crack = Paint()
      ..color = const Color(0xFFD7CCC8).withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.3)
      ..lineTo(size.width * 0.35, size.height * 0.45)
      ..lineTo(size.width * 0.28, size.height * 0.62);
    canvas.drawPath(path, crack);

    final eggGlow = Paint()
      ..color = const Color(0xFFFFF8E1).withValues(alpha: 0.12);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.78, size.height * 0.68),
        width: 34,
        height: 42,
      ),
      eggGlow,
    );

    final crystal = Paint()
      ..color = const Color(0xFF80DEEA).withValues(alpha: 0.5);
    for (final x in [0.08, 0.88]) {
      final path = Path()
        ..moveTo(size.width * x, size.height * 0.72)
        ..lineTo(size.width * (x + 0.035), size.height * 0.57)
        ..lineTo(size.width * (x + 0.07), size.height * 0.72)
        ..close();
      canvas.drawPath(path, crystal);
    }
  }

  void _paintShadowRoost(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A237E), Color(0xFF311B92), Color(0xFF1A1A2E)],
        ).createShader(rect),
    );

    final moon = Paint()
      ..color = const Color(0xFFE8EAF6).withValues(alpha: 0.75);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.14), 18, moon);

    final cloud = Paint()
      ..color = const Color(0xFF7986CB).withValues(alpha: 0.16);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.32, size.height * 0.22),
        width: size.width * 0.38,
        height: 34,
      ),
      cloud,
    );

    final barn = Paint()
      ..color = const Color(0xFF120F25).withValues(alpha: 0.72);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.49,
        size.width * 0.3,
        size.height * 0.31,
      ),
      barn,
    );
    final roof = Path()
      ..moveTo(size.width * 0.04, size.height * 0.5)
      ..lineTo(size.width * 0.23, size.height * 0.34)
      ..lineTo(size.width * 0.42, size.height * 0.5)
      ..close();
    canvas.drawPath(roof, barn);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.18,
        size.height * 0.61,
        size.width * 0.1,
        size.height * 0.19,
      ),
      Paint()..color = const Color(0xFF311B52),
    );

    final fence = Paint()
      ..color = const Color(0xFF0D0D1A).withValues(alpha: 0.65);
    for (var i = 0; i < 7; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * (0.08 + i * 0.13),
          size.height * 0.78,
          8,
          28,
        ),
        fence,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.06,
        size.height * 0.78,
        size.width * 0.88,
        4,
      ),
      fence,
    );

    final feather = Paint()
      ..color = const Color(0xFF4527A0).withValues(alpha: 0.35);
    for (var i = 0; i < 5; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            size.width * (0.15 + i * 0.17),
            size.height * (0.35 + (i % 2) * 0.08),
          ),
          width: 16,
          height: 8,
        ),
        feather,
      );
    }
  }

  void _paintRoyalPalace(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B5E20), Color(0xFF33691E), Color(0xFF1B4332)],
        ).createShader(rect),
    );

    final pillar = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.7);
    for (final x in [0.08, 0.25, 0.72, 0.89]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * x,
            size.height * 0.2,
            18,
            size.height * 0.62,
          ),
          const Radius.circular(7),
        ),
        pillar,
      );
    }

    final gold = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.55);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.18, size.width, 10), gold);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.28, size.width * 0.6, 8),
      gold,
    );

    final banner = Paint()
      ..color = const Color(0xFF43A047).withValues(alpha: 0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.42),
          width: 36,
          height: 48,
        ),
        const Radius.circular(4),
      ),
      banner,
    );

    final throne = Paint()
      ..color = const Color(0xFF1B5E20).withValues(alpha: 0.85);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.72),
          width: 72,
          height: 40,
        ),
        const Radius.circular(8),
      ),
      throne,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.63),
          width: 52,
          height: 86,
        ),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFF6A1B9A).withValues(alpha: 0.58),
    );

    final tile = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.14)
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.68 + i * 0.07);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), tile);
    }

    final sparkle = Paint()
      ..color = const Color(0xFFFFEB3B).withValues(alpha: 0.45);
    for (var i = 0; i < 6; i++) {
      final x = size.width * (0.25 + i * 0.1);
      canvas.drawCircle(Offset(x, size.height * 0.32), 2.5, sparkle);
    }
  }

  void _paintGuardianNest(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF263238), Color(0xFF37474F), Color(0xFF1C313A)],
        ).createShader(rect),
    );

    final cave = Paint()
      ..color = const Color(0xFF102027).withValues(alpha: 0.75);
    final cavePath = Path()
      ..moveTo(0, size.height * 0.35)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.05,
        size.width,
        size.height * 0.35,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(cavePath, cave);

    final arch = Paint()
      ..color = const Color(0xFF78909C).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.48),
        width: size.width * 0.78,
        height: size.height * 0.72,
      ),
      math.pi,
      math.pi,
      false,
      arch,
    );

    final nest = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.55);
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * (0.28 + i * 0.22), size.height * 0.68),
          width: 44,
          height: 22,
        ),
        nest,
      );
    }

    final glow = Paint()
      ..color = const Color(0xFF42A5F5).withValues(alpha: 0.35);
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * (0.28 + i * 0.22), size.height * 0.64),
          width: 18,
          height: 22,
        ),
        glow,
      );
    }

    final gold = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.25);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.55), 6, gold);

    final rune = Paint()
      ..color = const Color(0xFF64B5F6).withValues(alpha: 0.33)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final x in [0.12, 0.88]) {
      canvas.drawCircle(Offset(size.width * x, size.height * 0.55), 17, rune);
      canvas.drawLine(
        Offset(size.width * x - 10, size.height * 0.55),
        Offset(size.width * x + 10, size.height * 0.55),
        rune,
      );
    }
  }

  void _paintPhoenixLair(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1B2A), Color(0xFF1B263B), Color(0xFF0A1628)],
        ).createShader(rect),
    );

    final canyon = Paint()
      ..color = const Color(0xFF263850).withValues(alpha: 0.72);
    final leftCliff = Path()
      ..moveTo(0, size.height * 0.36)
      ..lineTo(size.width * 0.17, size.height * 0.46)
      ..lineTo(size.width * 0.24, size.height)
      ..lineTo(0, size.height)
      ..close();
    final rightCliff = Path()
      ..moveTo(size.width, size.height * 0.3)
      ..lineTo(size.width * 0.82, size.height * 0.45)
      ..lineTo(size.width * 0.76, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(leftCliff, canyon);
    canvas.drawPath(rightCliff, canyon);

    final distantGlow = Paint()
      ..color = const Color(0xFF7E57C2).withValues(alpha: 0.2);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.31),
      size.width * 0.15,
      distantGlow,
    );

    final ruin = Paint()
      ..color = const Color(0xFF415A77).withValues(alpha: 0.45);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.62,
        22,
        size.height * 0.28,
      ),
      ruin,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.78,
        size.height * 0.58,
        18,
        size.height * 0.32,
      ),
      ruin,
    );

    final ember = Paint()
      ..color = const Color(0xFF1565C0).withValues(alpha: 0.5);
    final random = math.Random(7);
    for (var i = 0; i < 14; i++) {
      final x = size.width * random.nextDouble();
      final y = size.height * (0.25 + random.nextDouble() * 0.55);
      canvas.drawCircle(Offset(x, y), 2 + random.nextDouble() * 3, ember);
    }

    final flame = Paint()
      ..color = const Color(0xFF1E88E5).withValues(alpha: 0.2);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.82),
        width: size.width * 0.7,
        height: 36,
      ),
      flame,
    );
  }

  void _paintRottenNest(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1028),
            Color(0xFF311B92),
            Color(0xFF33691E),
            Color(0xFF1B5E20),
          ],
        ).createShader(rect),
    );

    final rib = Paint()
      ..color = const Color(0xFF6D5A50).withValues(alpha: 0.58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(
        -size.width * 0.18,
        size.height * 0.23,
        size.width * 0.48,
        size.height * 0.58,
      ),
      -math.pi / 2,
      math.pi,
      false,
      rib,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.7,
        size.height * 0.23,
        size.width * 0.48,
        size.height * 0.58,
      ),
      math.pi / 2,
      math.pi,
      false,
      rib,
    );

    final fog = Paint()
      ..color = const Color(0xFF66BB6A).withValues(alpha: 0.25);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.3, size.height * 0.65),
        width: size.width * 0.5,
        height: 40,
      ),
      fog,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.72, size.height * 0.72),
        width: size.width * 0.45,
        height: 32,
      ),
      Paint()..color = const Color(0xFF8E24AA).withValues(alpha: 0.28),
    );

    final shell = Paint()..color = const Color(0xFF8D6E63);
    for (var i = 0; i < 6; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * (0.08 + i * 0.15),
            size.height * 0.78,
            size.width * 0.12,
            14,
          ),
          const Radius.circular(4),
        ),
        shell,
      );
    }

    final crack = Paint()
      ..color = const Color(0xFFB2FF59).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final crackPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.7)
      ..lineTo(size.width * 0.46, size.height * 0.76)
      ..lineTo(size.width * 0.52, size.height * 0.82)
      ..lineTo(size.width * 0.47, size.height * 0.9);
    canvas.drawPath(crackPath, crack);
  }

  void _paintGenericArena(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF37474F).withValues(alpha: 0.9),
            const Color(0xFF263238),
          ],
        ).createShader(rect),
    );

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  @override
  bool shouldRepaint(covariant _BossBattleBackgroundPainter oldDelegate) =>
      oldDelegate.type != type;
}
