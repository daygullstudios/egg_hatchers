import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/boss_visual_config.dart';

/// Blocky pixel-art boss battle / cinematic background for Retro Pixel style.
class RetroPixelBossBattleBackground extends StatelessWidget {
  const RetroPixelBossBattleBackground({
    super.key,
    required this.bossId,
    this.showOverlay = true,
    this.topViewPhase = 0,
  });

  final String bossId;
  final bool showOverlay;

  /// 0 = side view; 1 = top-down (Shadow Phoenix cinematic only).
  final double topViewPhase;

  @override
  Widget build(BuildContext context) {
    final type = BossVisualConfig.backgroundTypeForBossId(bossId);
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: _RetroPixelBossBattleBackgroundPainter(
            type: type,
            topViewPhase: topViewPhase,
          ),
        ),
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

class _RetroPixelBossBattleBackgroundPainter extends CustomPainter {
  _RetroPixelBossBattleBackgroundPainter({
    required this.type,
    this.topViewPhase = 0,
  });

  final BossBattleBackgroundType type;
  final double topViewPhase;

  static const _sky2 = Color(0xFF4A148C);
  static const _sky3 = Color(0xFF1B5E20);
  static const _ground1 = Color(0xFF33691E);
  static const _ground2 = Color(0xFF4E342E);
  static const _ground3 = Color(0xFF5D4037);
  static const _stone = Color(0xFF78909C);
  static const _stoneDark = Color(0xFF455A64);
  static const _glow = Color(0xFF64B5F6);
  static const _gold = Color(0xFFFFD54F);
  static const _slime = Color(0xFF66BB6A);
  static const _tree = Color(0xFF2E7D32);
  static const _trunk = Color(0xFF5D4037);
  static const _night = Color(0xFF1A237E);
  static const _sand = Color(0xFFD7CCC8);
  static const _cliff = Color(0xFF8D6E63);

  @override
  void paint(Canvas canvas, Size size) {
    final block = math.max(6.0, (size.width / 48).floorToDouble());
    switch (type) {
      case BossBattleBackgroundType.slimeSwamp:
        _paintSlimeSwamp(canvas, size, block);
      case BossBattleBackgroundType.eggCave:
        _paintEggCave(canvas, size, block);
      case BossBattleBackgroundType.shadowRoost:
        _paintShadowRoost(canvas, size, block);
      case BossBattleBackgroundType.royalPalace:
        _paintRoyalPalace(canvas, size, block);
      case BossBattleBackgroundType.guardianNest:
        _paintGuardianNest(canvas, size, block);
      case BossBattleBackgroundType.phoenixLair:
        _paintPhoenixLair(canvas, size, block, topViewPhase);
      case BossBattleBackgroundType.rottenNest:
        _paintRottenNest(canvas, size, block);
      case BossBattleBackgroundType.genericArena:
        _paintGenericArena(canvas, size, block);
    }
    _paintPixelFinish(canvas, size, block);
  }

  void _fillBand(
    Canvas canvas,
    Size size,
    double yStart,
    double yEnd,
    Color color,
  ) {
    canvas.drawRect(
      Rect.fromLTRB(0, size.height * yStart, size.width, size.height * yEnd),
      Paint()..color = color,
    );
  }

  void _block(
    Canvas canvas,
    Size size,
    double block,
    int gx,
    int gy,
    Color color, {
    int gw = 1,
    int gh = 1,
  }) {
    canvas.drawRect(
      Rect.fromLTWH(gx * block, gy * block, gw * block, gh * block),
      Paint()..color = color,
    );
  }

  void _ditherGround(
    Canvas canvas,
    Size size,
    double block,
    Color base,
    Color alt,
  ) {
    final cols = (size.width / block).ceil();
    final rows = ((size.height * 0.35) / block).ceil();
    final startRow = ((size.height * 0.65) / block).floor();
    for (var row = startRow; row < startRow + rows; row++) {
      for (var col = 0; col < cols; col++) {
        final fleck = ((col * 17) ^ (row * 31) ^ (col * row * 3)) % 19;
        _block(canvas, size, block, col, row, fleck < 3 ? alt : base);
      }
    }
  }

  double _snap(double value, double block) => (value / block).round() * block;

  void _pixelRect(
    Canvas canvas,
    Size size,
    double block,
    double left,
    double top,
    double width,
    double height,
    Color color,
  ) {
    canvas.drawRect(
      Rect.fromLTWH(
        _snap(size.width * left, block),
        _snap(size.height * top, block),
        math.max(block, _snap(size.width * width, block)),
        math.max(block, _snap(size.height * height, block)),
      ),
      Paint()..color = color,
    );
  }

  void _paintPixelFinish(Canvas canvas, Size size, double block) {
    final horizon = _snap(size.height * 0.65, block);
    canvas.drawRect(
      Rect.fromLTWH(0, horizon, size.width, block),
      Paint()..color = Colors.white.withValues(alpha: 0.1),
    );

    // Sparse floor seams create depth without competing with projectiles.
    final seam = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..strokeWidth = block * 0.45;
    for (var row = 1; row <= 3; row++) {
      final y = _snap(horizon + row * (size.height - horizon) / 4, block);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), seam);
    }
    // Pixel vignette frames the action while leaving the arena center bright.
    final shade = Paint()..color = Colors.black.withValues(alpha: 0.09);
    canvas.drawRect(Rect.fromLTWH(0, 0, block * 2, size.height), shade);
    canvas.drawRect(
      Rect.fromLTWH(size.width - block * 2, 0, block * 2, size.height),
      shade,
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, block), shade);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - block * 2, size.width, block * 2),
      shade,
    );
  }

  void _paintSlimeSwamp(Canvas canvas, Size size, double block) {
    _fillBand(canvas, size, 0, 0.24, const Color(0xFF173B2A));
    _fillBand(canvas, size, 0.24, 0.55, _sky3);
    _fillBand(canvas, size, 0.55, 0.68, _ground1);
    _ditherGround(canvas, size, block, _ground1, const Color(0xFF2E5930));

    // Misty distant tree line.
    for (var i = 0; i < 12; i++) {
      _pixelRect(
        canvas,
        size,
        block,
        i / 12,
        0.38 - (i % 3) * 0.025,
        0.1,
        0.2 + (i % 2) * 0.05,
        const Color(0xFF215B34),
      );
    }

    // Blocky trees
    for (final tree in [
      (0.08, 0.42, 3, 5),
      (0.22, 0.38, 4, 6),
      (0.78, 0.4, 3, 5),
      (0.9, 0.44, 3, 4),
    ]) {
      final tx = size.width * tree.$1;
      final ty = size.height * tree.$2;
      canvas.drawRect(
        Rect.fromLTWH(tx, ty, block * tree.$3, block * tree.$4),
        Paint()..color = _tree,
      );
      canvas.drawRect(
        Rect.fromLTWH(tx + block, ty + block * tree.$4, block, block * 3),
        Paint()..color = _trunk,
      );
    }

    // Goo puddles
    for (final puddle in [
      (0.2, 0.78, 6, 2),
      (0.55, 0.82, 5, 2),
      (0.75, 0.76, 4, 2),
    ]) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * puddle.$1,
          size.height * puddle.$2,
          block * puddle.$3,
          block * puddle.$4,
        ),
        Paint()..color = _slime,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          _snap(size.width * puddle.$1 + block, block),
          _snap(size.height * puddle.$2, block),
          block * math.max(1, puddle.$3 - 2),
          block * 0.5,
        ),
        Paint()..color = const Color(0xFFA5D66A),
      );
    }

    for (final x in [0.05, 0.12, 0.86, 0.94]) {
      _pixelRect(canvas, size, block, x, 0.56, 0.015, 0.18, _trunk);
      _pixelRect(canvas, size, block, x - 0.025, 0.55, 0.06, 0.025, _tree);
    }
  }

  void _paintEggCave(Canvas canvas, Size size, double block) {
    _fillBand(canvas, size, 0, 0.2, const Color(0xFF26343B));
    _fillBand(canvas, size, 0.2, 0.5, _stoneDark);
    _fillBand(canvas, size, 0.5, 0.68, _stone);
    _ditherGround(canvas, size, block, _ground2, _ground3);

    // Cave walls
    for (var i = 0; i < 8; i++) {
      _block(canvas, size, block, 0, 4 + i, _stoneDark, gh: 2);
      _block(
        canvas,
        size,
        block,
        (size.width / block).floor() - 1,
        3 + i,
        _stoneDark,
        gh: 2,
      );
    }

    // Stalactites and cool crystal pockets frame the empty play space.
    for (final x in [0.04, 0.12, 0.22, 0.72, 0.84, 0.94]) {
      final height = 0.09 + ((x * 100).round() % 3) * 0.035;
      _pixelRect(canvas, size, block, x, 0, 0.055, height, _stone);
      _pixelRect(
        canvas,
        size,
        block,
        x + 0.014,
        height,
        0.026,
        0.035,
        _stoneDark,
      );
    }
    for (final crystal in [(0.1, 0.58), (0.86, 0.54)]) {
      _pixelRect(
        canvas,
        size,
        block,
        crystal.$1,
        crystal.$2,
        0.035,
        0.1,
        _glow,
      );
      _pixelRect(
        canvas,
        size,
        block,
        crystal.$1 + 0.035,
        crystal.$2 + 0.035,
        0.028,
        0.065,
        const Color(0xFFB3E5FC),
      );
    }

    // Cracked rocks & glow
    for (final crack in [
      (0.3, 0.55, 4, 3),
      (0.6, 0.48, 3, 4),
      (0.45, 0.72, 5, 2),
    ]) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * crack.$1,
          size.height * crack.$2,
          block * crack.$3,
          block * crack.$4,
        ),
        Paint()..color = _ground3,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.48,
        size.height * 0.52,
        block * 2,
        block * 4,
      ),
      Paint()..color = _glow,
    );
  }

  void _paintShadowRoost(Canvas canvas, Size size, double block) {
    _fillBand(canvas, size, 0, 0.22, const Color(0xFF10143F));
    _fillBand(canvas, size, 0.22, 0.45, _night);
    _fillBand(canvas, size, 0.45, 0.55, _sky2);
    _fillBand(canvas, size, 0.55, 0.7, _ground2);
    _ditherGround(canvas, size, block, const Color(0xFF3E2723), _ground2);

    // Moon and sparse stars.
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.72,
        size.height * 0.08,
        block * 4,
        block * 4,
      ),
      Paint()..color = const Color(0xFFFFF59D),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        _snap(size.width * 0.75, block),
        _snap(size.height * 0.08, block),
        block * 3,
        block * 3,
      ),
      Paint()..color = _night,
    );
    for (final star in [
      (0.12, 0.12),
      (0.33, 0.2),
      (0.56, 0.09),
      (0.91, 0.26),
    ]) {
      _pixelRect(
        canvas,
        size,
        block,
        star.$1,
        star.$2,
        0.012,
        0.012,
        const Color(0xFFB9C6FF),
      );
    }

    // Barn silhouette
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.42,
        block * 8,
        block * 6,
      ),
      Paint()..color = const Color(0xFF4A148C),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.16,
        size.height * 0.38,
        block * 6,
        block * 2,
      ),
      Paint()..color = const Color(0xFF311B92),
    );
    final roof = Path()
      ..moveTo(
        _snap(size.width * 0.09, block),
        _snap(size.height * 0.43, block),
      )
      ..lineTo(_snap(size.width * 0.2, block), _snap(size.height * 0.31, block))
      ..lineTo(
        _snap(size.width * 0.31, block),
        _snap(size.height * 0.43, block),
      )
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF23132F));

    // Fence
    for (var i = 0; i < 10; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * 0.05 + i * block * 1.2,
          size.height * 0.68,
          block,
          block * 3,
        ),
        Paint()..color = _trunk,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.04,
        size.height * 0.7,
        size.width * 0.55,
        block,
      ),
      Paint()..color = _trunk,
    );
  }

  void _paintRoyalPalace(Canvas canvas, Size size, double block) {
    _fillBand(canvas, size, 0, 0.16, const Color(0xFF123D2E));
    _fillBand(canvas, size, 0.16, 0.5, const Color(0xFF1B5E20));
    _fillBand(canvas, size, 0.5, 0.65, const Color(0xFF33691E));
    _ditherGround(canvas, size, block, const Color(0xFF2E5930), _ground1);

    // Repeating wall panels and a bright central throne alcove.
    for (var i = 0; i < 7; i++) {
      _pixelRect(
        canvas,
        size,
        block,
        0.04 + i * 0.145,
        0.16,
        0.1,
        0.34,
        i.isEven ? const Color(0xFF246B3A) : const Color(0xFF1D5933),
      );
    }
    _pixelRect(
      canvas,
      size,
      block,
      0.39,
      0.24,
      0.22,
      0.34,
      const Color(0xFF16452D),
    );
    _pixelRect(canvas, size, block, 0.41, 0.22, 0.18, 0.025, _gold);

    // Pillars
    for (final pillar in [0.15, 0.35, 0.65, 0.85]) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * pillar,
          size.height * 0.35,
          block * 2,
          block * 8,
        ),
        Paint()..color = _stone,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * pillar - block * 0.5,
          size.height * 0.33,
          block * 3,
          block,
        ),
        Paint()..color = _gold,
      );
    }

    // Throne platform
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.28,
        size.height * 0.72,
        size.width * 0.44,
        block * 2,
      ),
      Paint()..color = _gold,
    );
    _pixelRect(
      canvas,
      size,
      block,
      0.38,
      0.57,
      0.24,
      0.15,
      const Color(0xFF6A1B9A),
    );
    _pixelRect(
      canvas,
      size,
      block,
      0.42,
      0.51,
      0.16,
      0.09,
      const Color(0xFF4A148C),
    );

    // Banners
    for (final banner in [0.22, 0.78]) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * banner,
          size.height * 0.28,
          block * 2,
          block * 5,
        ),
        Paint()..color = const Color(0xFF8E24AA),
      );
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * banner + block * 0.5,
          size.height * 0.3,
          block,
          block * 3,
        ),
        Paint()..color = _gold,
      );
    }
  }

  void _paintGuardianNest(Canvas canvas, Size size, double block) {
    _fillBand(canvas, size, 0, 0.18, const Color(0xFF202D35));
    _fillBand(canvas, size, 0.18, 0.48, _stoneDark);
    _fillBand(canvas, size, 0.48, 0.62, _stone);
    _ditherGround(canvas, size, block, _ground3, _stoneDark);

    // A stepped cavern arch gives the chamber a protected, ancient feel.
    for (var step = 0; step < 5; step++) {
      _pixelRect(
        canvas,
        size,
        block,
        step * 0.035,
        step * 0.04,
        0.08,
        0.48 - step * 0.035,
        step.isEven ? const Color(0xFF263840) : const Color(0xFF314750),
      );
      _pixelRect(
        canvas,
        size,
        block,
        0.92 - step * 0.035,
        step * 0.04,
        0.08,
        0.48 - step * 0.035,
        step.isEven ? const Color(0xFF263840) : const Color(0xFF314750),
      );
    }

    // Circular nest platform
    final center = Offset(size.width * 0.5, size.height * 0.78);
    for (var ring = 0; ring < 6; ring++) {
      final r = block * (4 + ring);
      canvas.drawRect(
        Rect.fromCenter(center: center, width: r * 2, height: block * 2),
        Paint()..color = ring.isEven ? _gold : _ground3,
      );
    }

    // Glowing egg nests
    for (final nest in [(0.25, 0.58), (0.5, 0.52), (0.72, 0.6)]) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * nest.$1,
          size.height * nest.$2,
          block * 3,
          block * 4,
        ),
        Paint()..color = _glow,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * nest.$1 + block * 0.5,
          size.height * nest.$2 + block * 0.5,
          block * 2,
          block * 2,
        ),
        Paint()..color = const Color(0xFFFFF9C4),
      );
      canvas.drawRect(
        Rect.fromLTWH(
          _snap(size.width * nest.$1 + block, block),
          _snap(size.height * nest.$2 - block, block),
          block,
          block,
        ),
        Paint()..color = Colors.white,
      );
    }

    // Rune stones
    for (final rune in [0.12, 0.88]) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * rune,
          size.height * 0.65,
          block * 2,
          block * 4,
        ),
        Paint()..color = _stone,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * rune + block * 0.5,
          size.height * 0.68,
          block,
          block * 2,
        ),
        Paint()..color = _glow,
      );
    }
  }

  void _paintPhoenixLair(
    Canvas canvas,
    Size size,
    double block,
    double topView,
  ) {
    final tv = topView.clamp(0.0, 1.0);
    final skyTop = Color.lerp(
      const Color(0xFF150D2D),
      const Color(0xFF2D1B4E),
      tv,
    )!;
    final skyMid = Color.lerp(
      const Color(0xFF4A2C6A),
      const Color(0xFF6D4C41),
      tv * 0.35,
    )!;
    _fillBand(canvas, size, 0, 0.35, skyTop);
    _fillBand(canvas, size, 0.35, 0.55, skyMid);
    _fillBand(canvas, size, 0.55, 0.72, _cliff);
    _ditherGround(canvas, size, block, _sand, const Color(0xFFBCAAA4));

    // Pixel sunset glow and distant mesa silhouettes.
    _pixelRect(
      canvas,
      size,
      block,
      0.43,
      0.18,
      0.14,
      0.12,
      const Color(0xFFB45AE0),
    );
    _pixelRect(
      canvas,
      size,
      block,
      0.46,
      0.15,
      0.08,
      0.18,
      const Color(0xFFE38BEF),
    );
    for (final mesa in [(0.08, 0.43, 0.22), (0.7, 0.4, 0.2)]) {
      _pixelRect(
        canvas,
        size,
        block,
        mesa.$1,
        mesa.$2,
        mesa.$3,
        0.16,
        const Color(0xFF4A2C57),
      );
    }

    // Canyon cliffs
    final cliffH = size.height * (0.35 + tv * 0.15);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        cliffH,
        size.width * (0.22 + tv * 0.05),
        size.height - cliffH,
      ),
      Paint()..color = const Color(0xFF6D4C41),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * (0.78 - tv * 0.05),
        cliffH,
        size.width * 0.22,
        size.height - cliffH,
      ),
      Paint()..color = const Color(0xFF5D4037),
    );

    // Blocky strata lines
    for (var i = 0; i < 5; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, cliffH + i * block * 2, size.width * 0.2, block),
        Paint()..color = const Color(0xFF8D6E63),
      );
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * 0.8,
          cliffH + i * block * 2.2,
          size.width * 0.2,
          block,
        ),
        Paint()..color = const Color(0xFF795548),
      );
    }

    // Impact area on floor when top-view increases
    if (tv > 0.2) {
      final impactSize = block * (4 + tv * 4);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * (0.82 - tv * 0.05)),
          width: impactSize,
          height: block * 2,
        ),
        Paint()..color = const Color(0xFF4E342E),
      );
    }

    for (final ember in [
      (0.18, 0.3),
      (0.3, 0.48),
      (0.67, 0.25),
      (0.82, 0.46),
    ]) {
      _pixelRect(
        canvas,
        size,
        block,
        ember.$1,
        ember.$2,
        0.014,
        0.025,
        const Color(0xFFB968FF),
      );
    }
  }

  void _paintRottenNest(Canvas canvas, Size size, double block) {
    _fillBand(canvas, size, 0, 0.2, const Color(0xFF120B1E));
    _fillBand(canvas, size, 0.2, 0.45, const Color(0xFF1A1028));
    _fillBand(canvas, size, 0.45, 0.62, const Color(0xFF311B92));
    _ditherGround(
      canvas,
      size,
      block,
      const Color(0xFF33691E),
      const Color(0xFF4A148C),
    );

    // Broken shell ribs loom at the sides without covering the combat lane.
    for (final x in [0.03, 0.89]) {
      _pixelRect(
        canvas,
        size,
        block,
        x,
        0.25,
        0.08,
        0.36,
        const Color(0xFF6D5A50),
      );
      _pixelRect(
        canvas,
        size,
        block,
        x + 0.02,
        0.28,
        0.04,
        0.29,
        const Color(0xFF2A173C),
      );
    }
    for (final eye in [(0.2, 0.34), (0.78, 0.3)]) {
      _pixelRect(
        canvas,
        size,
        block,
        eye.$1,
        eye.$2,
        0.045,
        0.028,
        const Color(0xFF9CFF57),
      );
    }

    // Cracked shell floor tiles
    for (final tile in [
      (0.12, 0.72, 4, 2),
      (0.35, 0.78, 5, 2),
      (0.58, 0.74, 4, 2),
      (0.78, 0.8, 3, 2),
    ]) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * tile.$1,
          size.height * tile.$2,
          block * tile.$3,
          block * tile.$4,
        ),
        Paint()..color = const Color(0xFF8D6E63),
      );
    }

    // Toxic fog bands
    for (var i = 0; i < 4; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          0,
          size.height * (0.5 + i * 0.06),
          size.width,
          block * 1.5,
        ),
        Paint()
          ..color = Color.lerp(
            const Color(0xFF66BB6A),
            const Color(0xFF8E24AA),
            i / 3,
          )!.withValues(alpha: 0.35),
      );
    }
  }

  void _paintGenericArena(Canvas canvas, Size size, double block) {
    _fillBand(canvas, size, 0, 0.2, const Color(0xFF263238));
    _fillBand(canvas, size, 0.2, 0.55, const Color(0xFF37474F));
    _fillBand(canvas, size, 0.55, 0.7, _stone);
    _ditherGround(canvas, size, block, _stoneDark, _stone);
    for (var i = 0; i < 9; i++) {
      _pixelRect(
        canvas,
        size,
        block,
        0.04 + i * 0.115,
        0.38 - (i % 2) * 0.04,
        0.08,
        0.18,
        const Color(0xFF263238),
      );
    }
    _pixelRect(
      canvas,
      size,
      block,
      0.2,
      0.58,
      0.6,
      0.04,
      const Color(0xFF90A4AE),
    );
  }

  @override
  bool shouldRepaint(
    covariant _RetroPixelBossBattleBackgroundPainter oldDelegate,
  ) {
    return oldDelegate.type != type || oldDelegate.topViewPhase != topViewPhase;
  }
}
