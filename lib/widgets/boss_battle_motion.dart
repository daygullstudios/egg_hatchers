import 'dart:math' as math;

import 'package:flutter/material.dart';

class BossMotionFrame {
  const BossMotionFrame({
    this.offset = Offset.zero,
    this.scaleX = 1,
    this.scaleY = 1,
    this.rotation = 0,
  });

  final Offset offset;
  final double scaleX;
  final double scaleY;
  final double rotation;
}

/// Gives each boss a readable idle, charge, and attack-release silhouette.
class BossBattleMotion extends StatelessWidget {
  const BossBattleMotion({
    super.key,
    required this.bossId,
    required this.idleTime,
    required this.chargeProgress,
    required this.releaseProgress,
    required this.signatureAttack,
    required this.reducedEffects,
    required this.child,
  });

  final String bossId;
  final double idleTime;
  final double? chargeProgress;
  final double? releaseProgress;
  final bool signatureAttack;
  final bool reducedEffects;
  final Widget child;

  static BossMotionFrame frameFor({
    required String bossId,
    required double idleTime,
    double? chargeProgress,
    double? releaseProgress,
    bool signatureAttack = false,
    bool reducedEffects = false,
  }) {
    final effectScale = reducedEffects ? 0.42 : 1.0;
    final signatureScale = signatureAttack ? 1.3 : 1.0;
    final strength = effectScale * signatureScale;
    final idle = _idleFrame(bossId, idleTime, effectScale);
    final action = releaseProgress != null
        ? _releaseFrame(bossId, releaseProgress, strength)
        : _chargeFrame(bossId, chargeProgress ?? 0, strength);

    return BossMotionFrame(
      offset: idle.offset + action.offset,
      scaleX: idle.scaleX * action.scaleX,
      scaleY: idle.scaleY * action.scaleY,
      rotation: idle.rotation + action.rotation,
    );
  }

  static BossMotionFrame _idleFrame(
    String bossId,
    double time,
    double strength,
  ) {
    final wave = math.sin(time * math.pi * 2);
    return switch (bossId) {
      'slime_boss' || 'slime_king' => BossMotionFrame(
        offset: Offset(0, wave * 1.6 * strength),
        scaleX: 1 + wave * 0.018 * strength,
        scaleY: 1 - wave * 0.018 * strength,
      ),
      'shadow_rooster' => BossMotionFrame(
        offset: Offset(wave * 1.2 * strength, 0),
        rotation: wave * 0.025 * strength,
      ),
      'shadow_phoenix' => BossMotionFrame(
        offset: Offset(0, wave * 2.2 * strength),
        rotation: wave * 0.018 * strength,
      ),
      'rotten_shell' => BossMotionFrame(
        offset: Offset(
          math.sin(time * 31) * 0.8 * strength,
          math.sin(time * 23) * 0.5 * strength,
        ),
        rotation: math.sin(time * 17) * 0.012 * strength,
      ),
      _ => BossMotionFrame(
        offset: Offset(0, wave * 0.7 * strength),
        rotation: wave * 0.008 * strength,
      ),
    };
  }

  static BossMotionFrame _chargeFrame(
    String bossId,
    double progress,
    double strength,
  ) {
    final t = Curves.easeInCubic.transform(progress.clamp(0.0, 1.0));
    return switch (bossId) {
      'slime_boss' => BossMotionFrame(
        offset: Offset(0, 5 * t * strength),
        scaleX: 1 + 0.12 * t * strength,
        scaleY: 1 - 0.13 * t * strength,
      ),
      'egg_golem' => BossMotionFrame(
        offset: Offset(-3 * t * strength, -4 * t * strength),
        rotation: -0.07 * t * strength,
      ),
      'shadow_rooster' => BossMotionFrame(
        offset: Offset(math.sin(t * math.pi * 5) * 4 * strength, 0),
        rotation: math.sin(t * math.pi * 4) * 0.09 * strength,
      ),
      'slime_king' => BossMotionFrame(
        offset: Offset(0, 6 * t * strength),
        scaleX: 1 + 0.15 * t * strength,
        scaleY: 1 - 0.15 * t * strength,
        rotation: math.sin(t * math.pi * 3) * 0.035 * strength,
      ),
      'egg_guardian' => BossMotionFrame(
        offset: Offset(0, 2 * t * strength),
        scaleX: 1 + 0.08 * t * strength,
        scaleY: 1 + 0.04 * t * strength,
      ),
      'shadow_phoenix' => BossMotionFrame(
        offset: Offset(-8 * t * strength, -5 * t * strength),
        scaleX: 1 + 0.07 * t * strength,
        scaleY: 1 + 0.07 * t * strength,
        rotation: -0.13 * t * strength,
      ),
      'rotten_shell' => BossMotionFrame(
        offset: Offset(
          math.sin(t * 48) * 4 * t * strength,
          math.sin(t * 37) * 2 * t * strength,
        ),
        scaleX: 1 + math.sin(t * 28) * 0.05 * t * strength,
        scaleY: 1 - math.sin(t * 28) * 0.05 * t * strength,
        rotation: math.sin(t * 39) * 0.05 * t * strength,
      ),
      _ => BossMotionFrame(offset: Offset(0, 2 * t * strength)),
    };
  }

  static BossMotionFrame _releaseFrame(
    String bossId,
    double progress,
    double strength,
  ) {
    final t = progress.clamp(0.0, 1.0);
    final impulse = math.sin(t * math.pi) * strength;
    final recoil = switch (bossId) {
      'slime_boss' => BossMotionFrame(
        offset: Offset(0, -12 * impulse),
        scaleX: 1 - 0.14 * impulse,
        scaleY: 1 + 0.2 * impulse,
      ),
      'egg_golem' => BossMotionFrame(
        offset: Offset(5 * impulse, 7 * impulse),
        rotation: 0.11 * impulse,
      ),
      'shadow_rooster' => BossMotionFrame(
        offset: Offset(9 * impulse, -3 * impulse),
        rotation: 0.18 * impulse,
      ),
      'slime_king' => BossMotionFrame(
        offset: Offset(0, -15 * impulse),
        scaleX: 1 - 0.18 * impulse,
        scaleY: 1 + 0.24 * impulse,
      ),
      'egg_guardian' => BossMotionFrame(
        offset: Offset(0, 8 * impulse),
        scaleX: 1 + 0.13 * impulse,
        scaleY: 1 - 0.08 * impulse,
      ),
      'shadow_phoenix' => BossMotionFrame(
        offset: Offset(13 * impulse, -7 * impulse),
        scaleX: 1 + 0.12 * impulse,
        scaleY: 1 - 0.05 * impulse,
        rotation: 0.22 * impulse,
      ),
      'rotten_shell' => BossMotionFrame(
        offset: Offset(math.sin(t * 54) * 8 * (1 - t) * strength, 5 * impulse),
        scaleX: 1 + 0.12 * impulse,
        scaleY: 1 - 0.1 * impulse,
        rotation: math.sin(t * 45) * 0.09 * (1 - t) * strength,
      ),
      _ => BossMotionFrame(offset: Offset(0, -7 * impulse)),
    };
    final charge = _chargeFrame(bossId, 1, strength);
    final carry = 1 - Curves.easeOutCubic.transform(t);
    return BossMotionFrame(
      offset: charge.offset * carry + recoil.offset,
      scaleX: 1 + (charge.scaleX - 1) * carry + (recoil.scaleX - 1),
      scaleY: 1 + (charge.scaleY - 1) * carry + (recoil.scaleY - 1),
      rotation: charge.rotation * carry + recoil.rotation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final frame = frameFor(
      bossId: bossId,
      idleTime: idleTime,
      chargeProgress: chargeProgress,
      releaseProgress: releaseProgress,
      signatureAttack: signatureAttack,
      reducedEffects: reducedEffects,
    );

    return Transform.translate(
      offset: frame.offset,
      child: Transform.rotate(
        angle: frame.rotation,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(frame.scaleX, frame.scaleY, 1),
          child: child,
        ),
      ),
    );
  }
}
