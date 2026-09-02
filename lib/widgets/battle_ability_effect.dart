import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/arena.dart';
import '../utils/arena_ability_visuals.dart';

class BattleAbilityEffect extends StatefulWidget {
  const BattleAbilityEffect({
    super.key,
    required this.trigger,
    required this.animalId,
    required this.mutationId,
    required this.ability,
    required this.playerAttacks,
    required this.reducedEffects,
  });

  final int trigger;
  final String animalId;
  final String mutationId;
  final ArenaAbility? ability;
  final bool playerAttacks;
  final bool reducedEffects;

  @override
  State<BattleAbilityEffect> createState() => _BattleAbilityEffectState();
}

class _BattleAbilityEffectState extends State<BattleAbilityEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1,
  );

  @override
  void didUpdateWidget(BattleAbilityEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger &&
        widget.trigger > 0 &&
        widget.ability != null) {
      final signature = widget.ability!.energyCost >= 7;
      _controller.duration = Duration(
        milliseconds: widget.reducedEffects
            ? 260
            : signature
            ? 720
            : 560,
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
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final ability = widget.ability;
            if (ability == null || _controller.value >= 1) {
              return const SizedBox.expand();
            }
            final identity = ArenaAbilityVisuals.forAnimal(
              animalId: widget.animalId,
              mutationId: widget.mutationId,
            );
            return CustomPaint(
              key: const ValueKey('battle-ability-effect'),
              painter: _BattleAbilityEffectPainter(
                progress: _controller.value,
                identity: identity,
                effect: ability.effect,
                signature: ability.energyCost >= 7,
                playerAttacks: widget.playerAttacks,
                reducedEffects: widget.reducedEffects,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BattleAbilityEffectPainter extends CustomPainter {
  const _BattleAbilityEffectPainter({
    required this.progress,
    required this.identity,
    required this.effect,
    required this.signature,
    required this.playerAttacks,
    required this.reducedEffects,
  });

  final double progress;
  final ArenaAbilityVisualIdentity identity;
  final ArenaAbilityEffect effect;
  final bool signature;
  final bool playerAttacks;
  final bool reducedEffects;

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(
      size.width * 0.5,
      size.height * (playerAttacks ? 0.73 : 0.27),
    );
    final target = Offset(
      size.width * 0.5,
      size.height * (playerAttacks ? 0.27 : 0.73),
    );
    final travelStart = effect == ArenaAbilityEffect.drain ? target : start;
    final travelTarget = effect == ArenaAbilityEffect.drain ? start : target;
    final travel = Curves.easeInOutCubic.transform(
      (progress / 0.72).clamp(0.0, 1.0),
    );
    final current = Offset.lerp(travelStart, travelTarget, travel)!;
    final fade = (1 - Curves.easeIn.transform(progress)).clamp(0.0, 1.0);
    final width = signature ? 7.0 : 4.5;

    final trail = Paint()
      ..shader = LinearGradient(
        colors: [
          identity.secondary.withValues(alpha: 0.05),
          identity.primary.withValues(alpha: 0.85 * fade),
        ],
      ).createShader(Rect.fromPoints(travelStart, current))
      ..strokeWidth = reducedEffects ? width * 0.55 : width
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(travelStart, current, trail);

    if (!reducedEffects) {
      final particles = signature ? 7 : 4;
      for (var i = 0; i < particles; i++) {
        final lag = (travel - i * 0.055).clamp(0.0, 1.0);
        final point = Offset.lerp(travelStart, travelTarget, lag)!;
        final side = math.sin((progress * 18 + i * 2.4) * math.pi) * (4 + i);
        canvas.drawCircle(
          point + Offset(side, 0),
          signature ? 2.7 : 1.8,
          Paint()
            ..color = (i.isEven ? identity.primary : identity.secondary)
                .withValues(alpha: fade * (0.75 - i * 0.06)),
        );
      }
    }

    _drawMotif(canvas, current, 7 + (signature ? 4 : 0), fade);
    _drawSupportEffect(canvas, start, target, fade);
  }

  void _drawSupportEffect(
    Canvas canvas,
    Offset start,
    Offset target,
    double fade,
  ) {
    if (effect == ArenaAbilityEffect.damage) return;
    final center = effect == ArenaAbilityEffect.drain ? target : start;
    final ringProgress = Curves.easeOut.transform(progress);
    final ring = Paint()
      ..color = identity.primary.withValues(alpha: fade * 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = signature ? 4 : 3;
    canvas.drawCircle(center, 18 + ringProgress * (signature ? 50 : 34), ring);

    if (effect == ArenaAbilityEffect.heal) {
      final glyph = Paint()
        ..color = identity.secondary.withValues(alpha: fade)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        center + const Offset(-9, 0),
        center + const Offset(9, 0),
        glyph,
      );
      canvas.drawLine(
        center + const Offset(0, -9),
        center + const Offset(0, 9),
        glyph,
      );
    } else if (effect == ArenaAbilityEffect.shield) {
      final shield = Path()
        ..moveTo(center.dx, center.dy - 15)
        ..lineTo(center.dx + 13, center.dy - 8)
        ..lineTo(center.dx + 9, center.dy + 11)
        ..lineTo(center.dx, center.dy + 17)
        ..lineTo(center.dx - 9, center.dy + 11)
        ..lineTo(center.dx - 13, center.dy - 8)
        ..close();
      canvas.drawPath(shield, ring);
    }
  }

  void _drawMotif(Canvas canvas, Offset center, double radius, double alpha) {
    final paint = Paint()
      ..color = identity.primary.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    switch (identity.motif) {
      case ArenaAbilityMotif.feather:
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(-0.6);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: radius,
            height: radius * 2.4,
          ),
          paint,
        );
        canvas.restore();
      case ArenaAbilityMotif.flame:
        final flame = Path()
          ..moveTo(center.dx, center.dy - radius * 1.5)
          ..quadraticBezierTo(
            center.dx + radius * 1.4,
            center.dy,
            center.dx,
            center.dy + radius,
          )
          ..quadraticBezierTo(
            center.dx - radius * 1.1,
            center.dy,
            center.dx,
            center.dy - radius * 1.5,
          );
        canvas.drawPath(flame, paint);
      case ArenaAbilityMotif.water:
        canvas.drawCircle(center, radius, paint);
        canvas.drawCircle(
          center + Offset(radius, -radius),
          radius * 0.4,
          Paint()..color = identity.secondary.withValues(alpha: alpha),
        );
      case ArenaAbilityMotif.nature:
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(0.7);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: radius * 1.2,
            height: radius * 2,
          ),
          paint,
        );
        canvas.restore();
      case ArenaAbilityMotif.stone:
        final shard = Path()
          ..moveTo(center.dx, center.dy - radius * 1.4)
          ..lineTo(center.dx + radius, center.dy)
          ..lineTo(center.dx, center.dy + radius * 1.4)
          ..lineTo(center.dx - radius, center.dy)
          ..close();
        canvas.drawPath(shard, paint);
      case ArenaAbilityMotif.cosmic:
        final star = Path();
        for (var i = 0; i < 10; i++) {
          final r = i.isEven ? radius * 1.5 : radius * 0.65;
          final angle = -math.pi / 2 + i * math.pi / 5;
          final point =
              center + Offset(math.cos(angle) * r, math.sin(angle) * r);
          if (i == 0) {
            star.moveTo(point.dx, point.dy);
          } else {
            star.lineTo(point.dx, point.dy);
          }
        }
        star.close();
        canvas.drawPath(star, paint);
      case ArenaAbilityMotif.shadow:
        canvas.drawCircle(center, radius * 1.25, paint);
        canvas.drawCircle(
          center + Offset(radius * 0.55, -radius * 0.25),
          radius,
          Paint()..color = identity.secondary.withValues(alpha: alpha * 0.85),
        );
      case ArenaAbilityMotif.slime:
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: radius * 2.3,
            height: radius * 1.7,
          ),
          paint,
        );
      case ArenaAbilityMotif.glitch:
        canvas.drawRect(
          Rect.fromCenter(
            center: center,
            width: radius * 2.4,
            height: radius * 0.8,
          ),
          paint,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: center + Offset(-radius * 0.7, radius),
            width: radius * 1.5,
            height: radius * 0.55,
          ),
          Paint()..color = identity.secondary.withValues(alpha: alpha),
        );
      case ArenaAbilityMotif.neutral:
        canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BattleAbilityEffectPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.identity != identity ||
        oldDelegate.effect != effect ||
        oldDelegate.signature != signature ||
        oldDelegate.playerAttacks != playerAttacks ||
        oldDelegate.reducedEffects != reducedEffects;
  }
}
