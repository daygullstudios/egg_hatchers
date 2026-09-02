import 'dart:async';

import 'package:flutter/material.dart';

class BattleHealthBar extends StatefulWidget {
  const BattleHealthBar({
    super.key,
    required this.value,
    required this.identity,
    required this.height,
    required this.reducedEffects,
    required this.semanticLabel,
  });

  final double value;
  final Object identity;
  final double height;
  final bool reducedEffects;
  final String semanticLabel;

  @override
  State<BattleHealthBar> createState() => _BattleHealthBarState();
}

class _BattleHealthBarState extends State<BattleHealthBar>
    with SingleTickerProviderStateMixin {
  Timer? _trailTimer;
  late double _displayValue;
  late double _trailValue;
  late final AnimationController _criticalController;

  double get _value => widget.value.clamp(0.0, 1.0);
  bool get _isCritical => _value > 0 && _value <= 0.2;

  @override
  void initState() {
    super.initState();
    _displayValue = _value;
    _trailValue = _value;
    _criticalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
      lowerBound: 0,
      upperBound: 1,
    );
    _updateCriticalAnimation();
  }

  @override
  void didUpdateWidget(BattleHealthBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextValue = _value;
    if (oldWidget.identity != widget.identity) {
      _trailTimer?.cancel();
      _displayValue = nextValue;
      _trailValue = nextValue;
    } else if (nextValue < _displayValue) {
      _displayValue = nextValue;
      _trailTimer?.cancel();
      _trailTimer = Timer(
        Duration(milliseconds: widget.reducedEffects ? 80 : 330),
        () {
          if (!mounted) return;
          setState(() => _trailValue = nextValue);
        },
      );
    } else if (nextValue > _displayValue) {
      _trailTimer?.cancel();
      _displayValue = nextValue;
      _trailValue = nextValue;
    }
    _updateCriticalAnimation();
  }

  void _updateCriticalAnimation() {
    if (_isCritical && !widget.reducedEffects) {
      if (!_criticalController.isAnimating) {
        _criticalController.repeat(reverse: true);
      }
    } else {
      _criticalController.stop();
      _criticalController.value = 0;
    }
  }

  @override
  void dispose() {
    _trailTimer?.cancel();
    _criticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = widget.reducedEffects || disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 230);
    final trailDuration = widget.reducedEffects || disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 420);
    final healthColor = _value > 0.45
        ? const Color(0xFF66BB6A)
        : _value > 0.2
        ? const Color(0xFFFFB300)
        : const Color(0xFFEF5350);

    return Semantics(
      label: widget.semanticLabel,
      value: '${(_value * 100).round()} percent',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _criticalController,
          builder: (context, child) {
            final glow = _isCritical
                ? 0.18 + _criticalController.value * 0.28
                : 0.0;
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.height),
                boxShadow: glow <= 0
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(
                            0xFFEF5350,
                          ).withValues(alpha: glow),
                          blurRadius: 7,
                          spreadRadius: 1,
                        ),
                      ],
              ),
              child: child,
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.height),
            child: SizedBox(
              height: widget.height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Colors.white12),
                  TweenAnimationBuilder<double>(
                    key: ValueKey('battle-health-trail-${widget.identity}'),
                    tween: Tween(end: _trailValue),
                    duration: trailDuration,
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value,
                      child: const ColoredBox(color: Color(0xFFFFD180)),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    key: ValueKey('battle-health-current-${widget.identity}'),
                    tween: Tween(end: _displayValue),
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value,
                      child: ColoredBox(color: healthColor),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
