import 'dart:math' as math;

enum BossProjectileMotion { straight, drift, weave }

class BossAttackLane {
  const BossAttackLane({
    this.xOffset = 0,
    this.horizontalSpeed = 0,
    this.waveAmplitude = 0,
    this.wavePhase = 0,
  });

  final double xOffset;
  final double horizontalSpeed;
  final double waveAmplitude;
  final double wavePhase;

  BossProjectileMotion get motion {
    if (waveAmplitude != 0) return BossProjectileMotion.weave;
    if (horizontalSpeed != 0) return BossProjectileMotion.drift;
    return BossProjectileMotion.straight;
  }
}

class BossAttackPlan {
  const BossAttackPlan({
    required this.name,
    required this.warningDuration,
    required this.laneHalfWidth,
    required this.lanes,
    this.signature = false,
  });

  final String name;
  final double warningDuration;
  final double laneHalfWidth;
  final List<BossAttackLane> lanes;
  final bool signature;
}

/// Predictable attack formations layered over the existing difficulty tuning.
class BossAttackPatterns {
  BossAttackPatterns._();

  static BossAttackPlan forBoss({
    required String bossId,
    required int attackIndex,
  }) {
    return switch (bossId) {
      'slime_boss' => BossAttackPlan(
        name: 'Slime Drop',
        warningDuration: 0.9,
        laneHalfWidth: 18,
        lanes: [
          BossAttackLane(
            waveAmplitude: attackIndex.isEven ? 9 : -9,
            wavePhase: attackIndex * 0.8,
          ),
        ],
      ),
      'egg_golem' =>
        attackIndex % 4 == 3
            ? const BossAttackPlan(
                name: 'Splitting Stone',
                warningDuration: 0.95,
                laneHalfWidth: 19,
                signature: true,
                lanes: [
                  BossAttackLane(xOffset: -34, horizontalSpeed: -10),
                  BossAttackLane(xOffset: 34, horizontalSpeed: 10),
                ],
              )
            : const BossAttackPlan(
                name: 'Stone Drop',
                warningDuration: 0.9,
                laneHalfWidth: 20,
                lanes: [BossAttackLane()],
              ),
      'shadow_rooster' || 'night_rooster' || 'night_crow' =>
        attackIndex % 4 == 3
            ? const BossAttackPlan(
                name: 'Feather Fan',
                warningDuration: 0.72,
                laneHalfWidth: 16,
                signature: true,
                lanes: [
                  BossAttackLane(xOffset: -46, horizontalSpeed: -14),
                  BossAttackLane(),
                  BossAttackLane(xOffset: 46, horizontalSpeed: 14),
                ],
              )
            : BossAttackPlan(
                name: 'Shadow Feather',
                warningDuration: 0.76,
                laneHalfWidth: 16,
                lanes: [
                  BossAttackLane(
                    xOffset: attackIndex.isEven ? -22 : 22,
                    horizontalSpeed: attackIndex.isEven ? 12 : -12,
                  ),
                ],
              ),
      'slime_king' =>
        attackIndex % 3 == 2
            ? const BossAttackPlan(
                name: 'Royal Bounce',
                warningDuration: 0.82,
                laneHalfWidth: 18,
                signature: true,
                lanes: [
                  BossAttackLane(xOffset: -30, waveAmplitude: 13),
                  BossAttackLane(
                    xOffset: 30,
                    waveAmplitude: 13,
                    wavePhase: math.pi,
                  ),
                ],
              )
            : BossAttackPlan(
                name: 'Royal Slime',
                warningDuration: 0.86,
                laneHalfWidth: 18,
                lanes: [
                  BossAttackLane(
                    waveAmplitude: 15,
                    wavePhase: attackIndex * 1.3,
                  ),
                ],
              ),
      'egg_guardian' =>
        attackIndex % 4 == 3
            ? const BossAttackPlan(
                name: 'Guardian Shards',
                warningDuration: 1,
                laneHalfWidth: 16,
                signature: true,
                lanes: [
                  BossAttackLane(xOffset: -56),
                  BossAttackLane(),
                  BossAttackLane(xOffset: 56),
                ],
              )
            : const BossAttackPlan(
                name: 'Guardian Shard',
                warningDuration: 0.92,
                laneHalfWidth: 17,
                lanes: [BossAttackLane()],
              ),
      'shadow_phoenix' =>
        attackIndex % 4 == 3
            ? const BossAttackPlan(
                name: 'Flame Sweep',
                warningDuration: 0.66,
                laneHalfWidth: 17,
                signature: true,
                lanes: [
                  BossAttackLane(xOffset: -64, horizontalSpeed: 18),
                  BossAttackLane(horizontalSpeed: 18),
                  BossAttackLane(xOffset: 64, horizontalSpeed: 18),
                ],
              )
            : const BossAttackPlan(
                name: 'Phoenix Flame',
                warningDuration: 0.72,
                laneHalfWidth: 17,
                lanes: [BossAttackLane(waveAmplitude: 11)],
              ),
      'rotten_shell' =>
        attackIndex % 3 == 2
            ? const BossAttackPlan(
                name: 'Corrupted Split',
                warningDuration: 0.74,
                laneHalfWidth: 20,
                signature: true,
                lanes: [
                  BossAttackLane(xOffset: -50, waveAmplitude: 16),
                  BossAttackLane(
                    xOffset: 50,
                    waveAmplitude: 16,
                    wavePhase: math.pi,
                  ),
                ],
              )
            : BossAttackPlan(
                name: 'Rotten Pulse',
                warningDuration: 0.8,
                laneHalfWidth: 21,
                lanes: [
                  BossAttackLane(
                    waveAmplitude: 20,
                    wavePhase: attackIndex * 0.9,
                  ),
                ],
              ),
      _ => const BossAttackPlan(
        name: 'Incoming Attack',
        warningDuration: 0.85,
        laneHalfWidth: 18,
        lanes: [BossAttackLane()],
      ),
    };
  }
}
