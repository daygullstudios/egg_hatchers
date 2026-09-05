import 'dart:math';

import 'package:flutter/material.dart';

/// Post-Rotten Shell reveal for the DayGull Egg.
class DayGullUnlockCinematic extends StatefulWidget {
  const DayGullUnlockCinematic({super.key});

  static const duration = Duration(milliseconds: 4300);

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black,
      builder: (_) => const DayGullUnlockCinematic(),
    );
  }

  @override
  State<DayGullUnlockCinematic> createState() => _DayGullUnlockCinematicState();
}

class _DayGullUnlockCinematicState extends State<DayGullUnlockCinematic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  var _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: DayGullUnlockCinematic.duration,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    if (_completed) return;
    _completed = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final screen = MediaQuery.sizeOf(context);
            final bgT = _segment(t, 0.0, 0.34, Curves.easeOutCubic);
            final titleT = _segment(t, 0.24, 0.58, Curves.easeOutBack);
            final subtitleT = _segment(t, 0.48, 0.78, Curves.easeOutCubic);
            final doneT = _segment(t, 0.86, 1.0, Curves.easeOut);

            return Stack(
              fit: StackFit.expand,
              children: [
                Transform.translate(
                  offset: Offset((1 - bgT) * screen.width, 0),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF020816),
                          Color(0xFF061A3F),
                          Color(0xFF02040E),
                        ],
                      ),
                    ),
                    child: CustomPaint(
                      painter: _DayGullGlitchPainter(t),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.10),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _GlitchText(
                          text: 'Break The Rules',
                          progress: t,
                          slideProgress: titleT,
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 18),
                        _GlitchText(
                          text: 'Extend The Game',
                          progress: t + 0.23,
                          slideProgress: subtitleT,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFDDEBFF),
                        ),
                        const SizedBox(height: 72),
                        Opacity(
                          opacity: doneT,
                          child: FilledButton.icon(
                            onPressed: doneT >= 1 ? _finish : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF6C3BFF),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text(
                              'Continue',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static double _segment(
    double t,
    double start,
    double end, [
    Curve curve = Curves.linear,
  ]) {
    if (t <= start) return 0;
    if (t >= end) return 1;
    return curve.transform((t - start) / (end - start));
  }
}

class _GlitchText extends StatelessWidget {
  const _GlitchText({
    required this.text,
    required this.progress,
    required this.slideProgress,
    required this.fontSize,
    required this.fontWeight,
    required this.color,
  });

  final String text;
  final double progress;
  final double slideProgress;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final shake = sin(progress * pi * 34);
    final pulse = (sin(progress * pi * 18) + 1) / 2;
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: 0,
      height: 1,
      color: color,
      shadows: const [
        Shadow(color: Color(0xFF4AD7FF), blurRadius: 14),
        Shadow(color: Color(0xFF9D4DFF), blurRadius: 18),
      ],
    );

    return Transform.translate(
      offset: Offset((1 - slideProgress) * -46 + shake * 2.4, 0),
      child: Opacity(
        opacity: slideProgress.clamp(0.0, 1.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(4 + shake * 3, -1),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: textStyle.copyWith(
                    color: const Color(
                      0xFF58E5FF,
                    ).withValues(alpha: 0.58 + pulse * 0.24),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(-5 - shake * 2, 2),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: textStyle.copyWith(
                    color: const Color(
                      0xFFB14BFF,
                    ).withValues(alpha: 0.52 + (1 - pulse) * 0.28),
                  ),
                ),
              ),
              Text(text, textAlign: TextAlign.center, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayGullGlitchPainter extends CustomPainter {
  const _DayGullGlitchPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final cyan = Paint()
      ..color = const Color(0xFF5CE8FF).withValues(alpha: 0.36)
      ..style = PaintingStyle.fill;
    final purple = Paint()
      ..color = const Color(0xFFA44DFF).withValues(alpha: 0.34)
      ..style = PaintingStyle.fill;
    final dim = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i < 18; i++) {
      final y = (size.height * ((i * 0.077 + progress * 0.45) % 1.0));
      final width = size.width * (0.12 + ((i * 37) % 9) / 20);
      final x =
          size.width * ((sin(progress * 8 + i * 1.7) + 1) / 2) - width / 2;
      final height = 2.0 + (i % 4);
      canvas.drawRect(
        Rect.fromLTWH(x, y, width, height),
        i.isEven ? cyan : purple,
      );
    }

    for (var i = 0; i < 8; i++) {
      final y = size.height * (0.12 + i * 0.105);
      final wobble = sin(progress * pi * 6 + i) * 16;
      canvas.drawLine(
        Offset(0, y + wobble),
        Offset(size.width, y - wobble),
        dim,
      );
    }

    final tear = Paint()
      ..color = const Color(0xFF020816).withValues(alpha: 0.36)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 5; i++) {
      final y = size.height * ((progress * 0.7 + i * 0.19) % 1.0);
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 8 + i * 2), tear);
    }
  }

  @override
  bool shouldRepaint(covariant _DayGullGlitchPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
