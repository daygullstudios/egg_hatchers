import 'package:egg_hatchers/data/boss_data.dart';
import 'package:egg_hatchers/utils/boss_attack_patterns.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every boss has a valid repeating attack plan', () {
    for (final boss in BossData.bosses) {
      for (var attackIndex = 0; attackIndex < 8; attackIndex++) {
        final plan = BossAttackPatterns.forBoss(
          bossId: boss.id,
          attackIndex: attackIndex,
        );

        expect(plan.name, isNotEmpty, reason: boss.id);
        expect(plan.warningDuration, inInclusiveRange(0.6, 1.1));
        expect(plan.laneHalfWidth, greaterThan(0));
        expect(plan.lanes, isNotEmpty, reason: boss.id);
        for (final lane in plan.lanes) {
          expect(lane.xOffset.abs(), lessThanOrEqualTo(70));
        }
      }
    }
  });

  test('later bosses regularly use recognizable signature formations', () {
    expect(_plan('egg_golem', 3).lanes, hasLength(2));
    expect(_plan('shadow_rooster', 3).lanes, hasLength(3));
    expect(_plan('slime_king', 2).lanes, hasLength(2));
    expect(_plan('egg_guardian', 3).lanes, hasLength(3));
    expect(_plan('shadow_phoenix', 3).lanes, hasLength(3));
    expect(_plan('rotten_shell', 2).lanes, hasLength(2));

    for (final entry in {
      'egg_golem': 3,
      'shadow_rooster': 3,
      'slime_king': 2,
      'egg_guardian': 3,
      'shadow_phoenix': 3,
      'rotten_shell': 2,
    }.entries) {
      expect(_plan(entry.key, entry.value).signature, isTrue);
    }
  });

  test(
    'motion metadata distinguishes straight, drifting, and weaving lanes',
    () {
      expect(
        _plan('egg_golem', 0).lanes.single.motion,
        BossProjectileMotion.straight,
      );
      expect(
        _plan('shadow_rooster', 0).lanes.single.motion,
        BossProjectileMotion.drift,
      );
      expect(
        _plan('rotten_shell', 0).lanes.single.motion,
        BossProjectileMotion.weave,
      );
    },
  );
}

BossAttackPlan _plan(String bossId, int attackIndex) {
  return BossAttackPatterns.forBoss(bossId: bossId, attackIndex: attackIndex);
}
