import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/arena.dart';

class BattleAbilityButton extends StatefulWidget {
  const BattleAbilityButton({
    super.key,
    required this.ability,
    required this.available,
    required this.reducedEffects,
    required this.onPressed,
    this.compact = false,
    this.accentColor,
  });

  final ArenaAbility ability;
  final bool available;
  final bool reducedEffects;
  final VoidCallback onPressed;
  final bool compact;
  final Color? accentColor;

  @override
  State<BattleAbilityButton> createState() => _BattleAbilityButtonState();
}

class _BattleAbilityButtonState extends State<BattleAbilityButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _readyController;

  @override
  void initState() {
    super.initState();
    _readyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(BattleAbilityButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.available && widget.available && !widget.reducedEffects) {
      _readyController.forward(from: 0);
    } else if (widget.reducedEffects) {
      _readyController.value = 1;
    }
  }

  @override
  void dispose() {
    _readyController.dispose();
    super.dispose();
  }

  IconData get _effectIcon => switch (widget.ability.effect) {
    ArenaAbilityEffect.damage => Icons.flash_on,
    ArenaAbilityEffect.shield => Icons.shield,
    ArenaAbilityEffect.heal => Icons.favorite,
    ArenaAbilityEffect.drain => Icons.sync_alt,
  };

  String get _effectName => switch (widget.ability.effect) {
    ArenaAbilityEffect.damage => 'damage',
    ArenaAbilityEffect.shield => 'shield',
    ArenaAbilityEffect.heal => 'healing',
    ArenaAbilityEffect.drain => 'energy drain',
  };

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? const Color(0xFFFFD54F);
    return Semantics(
      button: true,
      enabled: widget.available,
      label:
          '${widget.ability.name}, $_effectName ability, costs ${widget.ability.energyCost} energy, ${widget.available ? 'ready' : 'not ready'}',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _readyController,
          builder: (context, child) {
            final pulse = widget.available
                ? math.sin(_readyController.value * math.pi)
                : 0.0;
            return Transform.scale(
              scale: 1 + pulse * 0.045,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: pulse <= 0
                      ? null
                      : [
                          BoxShadow(
                            color: accent.withValues(alpha: pulse * 0.6),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                ),
                child: child,
              ),
            );
          },
          child: SizedBox(
            height: widget.compact ? 50 : 54,
            child: FilledButton(
              onPressed: widget.available ? widget.onPressed : null,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.compact ? 4 : 5,
                  vertical: 4,
                ),
                backgroundColor: Color.lerp(
                  const Color(0xFF10252A),
                  accent,
                  widget.ability.energyCost >= 7 ? 0.5 : 0.34,
                ),
                disabledBackgroundColor: Colors.white10,
                side: BorderSide(
                  color: widget.available
                      ? accent.withValues(alpha: 0.62)
                      : Colors.transparent,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.ability.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.available ? Colors.white : Colors.white38,
                      fontSize: widget.compact ? 9 : 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _effectIcon,
                        size: widget.compact ? 8 : 9,
                        color: widget.available ? accent : Colors.white24,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${widget.ability.energyCost} ENERGY',
                        style: TextStyle(
                          color: widget.available ? accent : Colors.white24,
                          fontSize: widget.compact ? 7 : 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
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
