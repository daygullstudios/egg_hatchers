import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/animal_sprite_theme.dart';
import 'animal_sprite_theme_scope.dart';

enum AnimalMotionState { idle, attack, hurt, victory }

class AnimalMotion extends StatefulWidget {
  const AnimalMotion({
    super.key,
    required this.state,
    required this.child,
    this.attackDirection = const Offset(0, -1),
    this.pixelated = false,
  });

  final AnimalMotionState state;
  final Widget child;
  final Offset attackDirection;
  final bool pixelated;

  @override
  State<AnimalMotion> createState() => _AnimalMotionState();
}

class _AnimalMotionState extends State<AnimalMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _startMotion();
  }

  @override
  void didUpdateWidget(AnimalMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) _startMotion();
  }

  void _startMotion() {
    switch (widget.state) {
      case AnimalMotionState.idle:
        _controller.duration = const Duration(milliseconds: 1700);
        _controller.repeat();
      case AnimalMotionState.attack:
        _controller.duration = const Duration(milliseconds: 240);
        _controller.forward(from: 0);
      case AnimalMotionState.hurt:
        _controller.duration = const Duration(milliseconds: 300);
        _controller.forward(from: 0);
      case AnimalMotionState.victory:
        _controller.duration = const Duration(milliseconds: 820);
        _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) return widget.child;
    final theme = AnimalSpriteThemeScope.of(context);
    final pixelated =
        widget.pixelated || theme.id == AnimalSpriteThemes.retroPixel.id;
    final realistic = theme.id == AnimalSpriteThemes.realistic.id;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final transform = _transformFor(
          _controller.value,
          realistic: realistic,
          pixelated: pixelated,
        );
        return Transform.translate(
          offset: transform.offset,
          child: Transform.rotate(
            angle: transform.rotation,
            child: Transform.scale(
              scaleX: transform.scaleX,
              scaleY: transform.scaleY,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        );
      },
    );
  }

  _MotionTransform _transformFor(
    double value, {
    required bool realistic,
    required bool pixelated,
  }) {
    var dx = 0.0;
    var dy = 0.0;
    var rotation = 0.0;
    var scaleX = 1.0;
    var scaleY = 1.0;
    final strength = realistic ? 0.72 : 1.0;

    switch (widget.state) {
      case AnimalMotionState.idle:
        final wave = math.sin(value * math.pi * 2);
        dy = -0.9 * strength * (wave + 1);
        scaleX = 1 - wave * 0.009 * strength;
        scaleY = 1 + wave * 0.014 * strength;
      case AnimalMotionState.attack:
        final lunge = math.sin(Curves.easeOut.transform(value) * math.pi);
        dx = widget.attackDirection.dx * 10 * lunge * strength;
        dy = widget.attackDirection.dy * 10 * lunge * strength;
        rotation = widget.attackDirection.dx * 0.055 * lunge;
        scaleX = 1 + 0.055 * lunge;
        scaleY = 1 - 0.025 * lunge;
      case AnimalMotionState.hurt:
        final fade = 1 - value;
        dx = math.sin(value * math.pi * 8) * 5 * fade * strength;
        rotation = math.sin(value * math.pi * 6) * 0.04 * fade;
        scaleX = 1 + 0.035 * fade;
        scaleY = 1 - 0.045 * fade;
      case AnimalMotionState.victory:
        final bounce = math.sin(value * math.pi * 2).abs();
        dy = -5.5 * bounce * strength;
        rotation = math.sin(value * math.pi * 2) * 0.045 * strength;
        scaleX = 1 + 0.035 * bounce;
        scaleY = 1 + 0.055 * bounce;
    }

    if (pixelated) {
      dx = dx.roundToDouble();
      dy = dy.roundToDouble();
      rotation = 0;
      scaleX = (scaleX * 16).round() / 16;
      scaleY = (scaleY * 16).round() / 16;
    }
    return _MotionTransform(
      offset: Offset(dx, dy),
      rotation: rotation,
      scaleX: scaleX,
      scaleY: scaleY,
    );
  }
}

class _MotionTransform {
  const _MotionTransform({
    required this.offset,
    required this.rotation,
    required this.scaleX,
    required this.scaleY,
  });

  final Offset offset;
  final double rotation;
  final double scaleX;
  final double scaleY;
}
