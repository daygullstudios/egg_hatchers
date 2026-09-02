import 'dart:math' as math;

import 'package:egg_hatchers/data/boss_data.dart';
import 'package:egg_hatchers/widgets/boss_battle_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every boss motion remains finite and inside a safe scale range', () {
    for (final boss in BossData.bosses) {
      for (final progress in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        final frames = [
          BossBattleMotion.frameFor(
            bossId: boss.id,
            idleTime: 0.3,
            chargeProgress: progress,
          ),
          BossBattleMotion.frameFor(
            bossId: boss.id,
            idleTime: 0.3,
            releaseProgress: progress,
            signatureAttack: true,
          ),
        ];

        for (final frame in frames) {
          expect(frame.offset.dx.isFinite, isTrue, reason: boss.id);
          expect(frame.offset.dy.isFinite, isTrue, reason: boss.id);
          expect(frame.rotation.isFinite, isTrue, reason: boss.id);
          expect(frame.scaleX, inInclusiveRange(0.6, 1.5));
          expect(frame.scaleY, inInclusiveRange(0.6, 1.5));
        }
      }
    }
  });

  test('release begins continuously from the fully charged pose', () {
    for (final boss in BossData.bosses) {
      final charged = BossBattleMotion.frameFor(
        bossId: boss.id,
        idleTime: 0.4,
        chargeProgress: 1,
      );
      final released = BossBattleMotion.frameFor(
        bossId: boss.id,
        idleTime: 0.4,
        releaseProgress: 0,
      );

      expect(released.offset.dx, closeTo(charged.offset.dx, 0.001));
      expect(released.offset.dy, closeTo(charged.offset.dy, 0.001));
      expect(released.scaleX, closeTo(charged.scaleX, 0.001));
      expect(released.scaleY, closeTo(charged.scaleY, 0.001));
      expect(released.rotation, closeTo(charged.rotation, 0.001));
    }
  });

  test('signature attacks move more strongly than regular attacks', () {
    final regular = BossBattleMotion.frameFor(
      bossId: 'shadow_phoenix',
      idleTime: 0,
      releaseProgress: 0.5,
    );
    final signature = BossBattleMotion.frameFor(
      bossId: 'shadow_phoenix',
      idleTime: 0,
      releaseProgress: 0.5,
      signatureAttack: true,
    );

    expect(signature.offset.distance, greaterThan(regular.offset.distance));
    expect(signature.rotation.abs(), greaterThan(regular.rotation.abs()));
  });

  test('reduced effects keeps the same motion with lower intensity', () {
    final full = BossBattleMotion.frameFor(
      bossId: 'slime_king',
      idleTime: 0.25,
      chargeProgress: 1,
    );
    final reduced = BossBattleMotion.frameFor(
      bossId: 'slime_king',
      idleTime: 0.25,
      chargeProgress: 1,
      reducedEffects: true,
    );

    final fullDistortion =
        full.offset.distance +
        (full.scaleX - 1).abs() +
        (full.scaleY - 1).abs() +
        full.rotation.abs();
    final reducedDistortion =
        reduced.offset.distance +
        (reduced.scaleX - 1).abs() +
        (reduced.scaleY - 1).abs() +
        reduced.rotation.abs();
    expect(reducedDistortion, lessThan(fullDistortion));
  });

  testWidgets('motion wrapper keeps its child visible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: BossBattleMotion(
            bossId: 'egg_guardian',
            idleTime: math.pi,
            chargeProgress: 0.8,
            releaseProgress: null,
            signatureAttack: false,
            reducedEffects: false,
            child: SizedBox(key: Key('boss'), width: 80, height: 80),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('boss')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
