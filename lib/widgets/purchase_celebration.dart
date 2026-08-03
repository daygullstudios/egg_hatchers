import 'dart:math';

import 'package:flutter/material.dart';

/// A short, non-interactive shower of coins and bills after a purchase.
class PurchaseCelebration {
  PurchaseCelebration._();

  static OverlayEntry? _activeEntry;
  static var _requestId = 0;

  static void show(BuildContext context) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final requestId = ++_requestId;
    _activeEntry?.remove();
    _activeEntry = null;

    // Wait for purchase dialogs to enter the overlay, then rain above them.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (requestId != _requestId || !overlay.mounted) return;
      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => _MoneyRain(
          onComplete: () {
            if (entry.mounted) entry.remove();
            if (identical(_activeEntry, entry)) _activeEntry = null;
          },
        ),
      );
      _activeEntry = entry;
      overlay.insert(entry);
    });
  }
}

class _MoneyRain extends StatefulWidget {
  const _MoneyRain({required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<_MoneyRain> createState() => _MoneyRainState();
}

class _MoneyRainState extends State<_MoneyRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_MoneyParticle> _particles;

  @override
  void initState() {
    super.initState();
    final random = Random(7319);
    _particles = List.generate(46, (index) {
      return _MoneyParticle(
        x: random.nextDouble(),
        delay: random.nextDouble() * 0.34,
        fallRate: 0.82 + random.nextDouble() * 0.38,
        sway: 10 + random.nextDouble() * 32,
        phase: random.nextDouble() * pi * 2,
        spin: (random.nextDouble() * 2 - 1) * pi * 4,
        size: 13 + random.nextDouble() * 11,
        isBill: index % 5 == 0,
        colorIndex: index % 3,
      );
    });
    _controller =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1900),
          )
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) widget.onComplete();
          })
          ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      key: const ValueKey('purchase-money-rain'),
      child: IgnorePointer(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, child) => CustomPaint(
              painter: _MoneyRainPainter(
                progress: _controller.value,
                particles: _particles,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoneyParticle {
  const _MoneyParticle({
    required this.x,
    required this.delay,
    required this.fallRate,
    required this.sway,
    required this.phase,
    required this.spin,
    required this.size,
    required this.isBill,
    required this.colorIndex,
  });

  final double x;
  final double delay;
  final double fallRate;
  final double sway;
  final double phase;
  final double spin;
  final double size;
  final bool isBill;
  final int colorIndex;
}

class _MoneyRainPainter extends CustomPainter {
  const _MoneyRainPainter({required this.progress, required this.particles});

  final double progress;
  final List<_MoneyParticle> particles;

  static const _coinColors = [
    Color(0xFFFFD54F),
    Color(0xFFFFB300),
    Color(0xFFFFE082),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final local = ((progress - particle.delay) / (1 - particle.delay)).clamp(
        0.0,
        1.0,
      );
      if (local <= 0) continue;

      final travel = Curves.easeIn.transform(local);
      final y =
          -particle.size * 2 +
          (size.height + particle.size * 4) * travel * particle.fallRate;
      if (y > size.height + particle.size * 2) continue;
      final x =
          particle.x * size.width +
          sin(local * pi * 4 + particle.phase) * particle.sway;
      final opacity = local > 0.82 ? (1 - local) / 0.18 : 1.0;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.spin * local);
      if (particle.isBill) {
        _paintBill(canvas, particle, opacity);
      } else {
        _paintCoin(canvas, particle, opacity);
      }
      canvas.restore();
    }
  }

  void _paintCoin(Canvas canvas, _MoneyParticle particle, double opacity) {
    final radius = particle.size * 0.52;
    final color = _coinColors[particle.colorIndex];
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.16 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()..color = color.withValues(alpha: opacity),
    );
    canvas.drawCircle(
      Offset.zero,
      radius * 0.72,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = const Color(0xFFFF8F00).withValues(alpha: opacity),
    );
    canvas.drawLine(
      Offset(0, -radius * 0.42),
      Offset(0, radius * 0.42),
      Paint()
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFF8F00).withValues(alpha: opacity),
    );
  }

  void _paintBill(Canvas canvas, _MoneyParticle particle, double opacity) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: particle.size * 1.55,
        height: particle.size * 0.82,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = const Color(0xFF66BB6A).withValues(alpha: opacity),
    );
    canvas.drawRRect(
      rect.deflate(2.2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF1B5E20).withValues(alpha: opacity),
    );
    canvas.drawCircle(
      Offset.zero,
      particle.size * 0.18,
      Paint()..color = const Color(0xFFC8E6C9).withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(covariant _MoneyRainPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
