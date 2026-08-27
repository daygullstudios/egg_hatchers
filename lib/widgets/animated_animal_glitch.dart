import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Briefly displaces thin horizontal slices while leaving the base sprite clear.
class AnimatedAnimalGlitch extends StatefulWidget {
  const AnimatedAnimalGlitch({
    super.key,
    required this.child,
    required this.size,
  });

  final Widget child;
  final double size;

  @override
  State<AnimatedAnimalGlitch> createState() => _AnimatedAnimalGlitchState();
}

class _AnimatedAnimalGlitchState extends State<AnimatedAnimalGlitch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          final t = _controller.value;
          final upperPulse = _pulse(t, 0.13, 0.055);
          final middlePulse = _pulse(t, 0.46, 0.07);
          final lowerPulse = _pulse(t, 0.76, 0.06);
          final strongestPulse = math.max(
            upperPulse,
            math.max(middlePulse, lowerPulse),
          );

          return Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              Transform.translate(
                offset: Offset(widget.size * 0.008 * strongestPulse, 0),
                child: child,
              ),
              _slice(
                child!,
                top: 0.18,
                height: 0.12,
                pulse: upperPulse,
                direction: -1,
              ),
              _slice(
                child,
                top: 0.47,
                height: 0.09,
                pulse: middlePulse,
                direction: 1,
              ),
              _slice(
                child,
                top: 0.72,
                height: 0.11,
                pulse: lowerPulse,
                direction: -1,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _slice(
    Widget child, {
    required double top,
    required double height,
    required double pulse,
    required int direction,
  }) {
    return ExcludeSemantics(
      child: Opacity(
        opacity: (pulse * 0.78).clamp(0, 1),
        child: Transform.translate(
          offset: Offset(direction * widget.size * 0.065 * pulse, 0),
          child: ClipRect(
            clipper: _HorizontalSliceClipper(top: top, height: height),
            child: child,
          ),
        ),
      ),
    );
  }

  double _pulse(double t, double start, double width) {
    if (t < start || t > start + width) return 0;
    final localT = (t - start) / width;
    return math.sin(localT * math.pi);
  }
}

class _HorizontalSliceClipper extends CustomClipper<Rect> {
  const _HorizontalSliceClipper({required this.top, required this.height});

  final double top;
  final double height;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, size.height * top, size.width, size.height * height);

  @override
  bool shouldReclip(covariant _HorizontalSliceClipper oldClipper) =>
      oldClipper.top != top || oldClipper.height != height;
}
