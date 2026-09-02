import 'package:flutter/material.dart';

import 'battle_impact_overlay.dart';

class BattleHitFeedback extends StatefulWidget {
  const BattleHitFeedback({
    super.key,
    required this.trigger,
    required this.alignment,
    required this.damage,
    required this.color,
    required this.reducedEffects,
  });

  final int trigger;
  final Alignment alignment;
  final int damage;
  final Color color;
  final bool reducedEffects;

  @override
  State<BattleHitFeedback> createState() => _BattleHitFeedbackState();
}

class _BattleHitFeedbackState extends State<BattleHitFeedback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(BattleHitFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) {
      final disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      _controller.duration = Duration(
        milliseconds: widget.reducedEffects || disableAnimations ? 180 : 460,
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.value >= 1) return const SizedBox.expand();
          final progress = Curves.easeOut.transform(_controller.value);
          final fade = (1 - progress).clamp(0.0, 1.0);
          return LayoutBuilder(
            builder: (context, constraints) {
              final position = Offset(
                (widget.alignment.x + 1) * constraints.maxWidth / 2,
                (widget.alignment.y + 1) * constraints.maxHeight / 2,
              );
              return Stack(
                key: const ValueKey('battle-hit-feedback'),
                fit: StackFit.expand,
                children: [
                  BattleImpactOverlay(
                    position: position,
                    progress: progress,
                    color: widget.color,
                    intensity: widget.damage > 0 ? 0.9 : 0.55,
                    reducedEffects: widget.reducedEffects,
                  ),
                  Align(
                    alignment: widget.alignment,
                    child: Transform.translate(
                      offset: Offset(0, -18 - 28 * progress),
                      child: Opacity(
                        opacity: fade,
                        child: Text(
                          widget.damage > 0 ? '-${widget.damage}' : 'BLOCKED',
                          style: TextStyle(
                            color: widget.damage > 0
                                ? Colors.white
                                : const Color(0xFFB3E5FC),
                            fontSize: widget.reducedEffects ? 16 : 20,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: widget.color,
                                blurRadius: widget.reducedEffects ? 2 : 9,
                              ),
                              const Shadow(
                                color: Colors.black87,
                                offset: Offset(0, 2),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
