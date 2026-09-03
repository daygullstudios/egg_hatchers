import 'package:egg_hatchers/data/boss_data.dart';
import 'package:egg_hatchers/models/boss_battle.dart';
import 'package:egg_hatchers/models/player_state.dart';
import 'package:egg_hatchers/utils/boss_battle_logic.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mobile assist applies only to native iOS and Android', () {
    expect(
      BossBattleLogic.isMobileAssistEnabled(
        isWebOverride: false,
        platformOverride: TargetPlatform.iOS,
      ),
      isTrue,
    );
    expect(
      BossBattleLogic.isMobileAssistEnabled(
        isWebOverride: false,
        platformOverride: TargetPlatform.android,
      ),
      isTrue,
    );
    expect(
      BossBattleLogic.isMobileAssistEnabled(
        isWebOverride: true,
        platformOverride: TargetPlatform.iOS,
      ),
      isFalse,
    );
    expect(
      BossBattleLogic.isMobileAssistEnabled(
        isWebOverride: false,
        platformOverride: TargetPlatform.macOS,
      ),
      isFalse,
    );
  });

  test('mobile assist speeds touch movement and slows boss projectiles', () {
    expect(
      BossBattleLogic.manualTouchMoveSpeed(
        BossBattleLogic.manualPlayerMoveSpeed,
        mobileAssistEnabled: true,
      ),
      525,
    );
    expect(
      BossBattleLogic.manualTouchMoveSpeed(
        BossBattleLogic.manualPlayerMoveSpeed,
        mobileAssistEnabled: false,
      ),
      350,
    );
    expect(
      BossBattleLogic.manualPlatformProjectileSpeedScale(
        mobileAssistEnabled: true,
      ),
      0.88,
    );
    expect(
      BossBattleLogic.manualPlatformProjectileSpeedScale(
        mobileAssistEnabled: false,
      ),
      1.0,
    );
  });

  test('elite boss unlock requires three nightmare wins on prerequisite', () {
    final slimeKing = BossData.bossById('slime_king')!;
    final empty = PlayerState.initial();
    expect(BossBattleLogic.isEliteBossUnlocked(slimeKing, empty), isFalse);

    final unlocked = empty.copyWith(nightmareWins: const {'slime_boss': 3});
    expect(BossBattleLogic.isEliteBossUnlocked(slimeKing, unlocked), isTrue);
  });

  test('elite boss lives', () {
    expect(
      BossBattleLogic.manualBossLives(BossData.bossById('slime_king')!),
      3,
    );
    expect(
      BossBattleLogic.manualBossLives(BossData.bossById('egg_guardian')!),
      4,
    );
    expect(
      BossBattleLogic.manualBossLives(BossData.bossById('shadow_phoenix')!),
      5,
    );
  });

  test(
    'manual boss projectile damage uses half recommended power minimum 10',
    () {
      final slime = BossData.bossById('slime_boss')!;
      expect(BossBattleLogic.manualBossProjectileDamage(slime), 50);

      final golem = BossData.bossById('egg_golem')!;
      expect(BossBattleLogic.manualBossProjectileDamage(golem), 750);
    },
  );

  test('manual egg damage uses battle power divided by 8 minimum 10', () {
    expect(BossBattleLogic.manualEggDamage(80), 10);
    expect(BossBattleLogic.manualEggDamage(800), 100);
    expect(BossBattleLogic.manualEggDamage(15000), 1875);
  });

  test('manual boss lives vary by boss id', () {
    expect(
      BossBattleLogic.manualBossLives(BossData.bossById('slime_boss')!),
      1,
    );
    expect(BossBattleLogic.manualBossLives(BossData.bossById('egg_golem')!), 2);
    expect(
      BossBattleLogic.manualBossLives(BossData.bossById('shadow_rooster')!),
      3,
    );
  });

  test('boss music advances once for every lost boss life', () {
    expect(BossBattleLogic.manualMusicStage(livesRemaining: 5, maxLives: 5), 0);
    expect(BossBattleLogic.manualMusicStage(livesRemaining: 4, maxLives: 5), 1);
    expect(BossBattleLogic.manualMusicStage(livesRemaining: 1, maxLives: 5), 4);
  });

  test('boss music stage safely clamps old or invalid battle state', () {
    expect(BossBattleLogic.manualMusicStage(livesRemaining: 9, maxLives: 5), 0);
    expect(
      BossBattleLogic.manualMusicStage(livesRemaining: -2, maxLives: 5),
      5,
    );
    expect(BossBattleLogic.manualMusicStage(livesRemaining: 0, maxLives: 0), 0);
  });

  test('rage mode applies only to multi-life bosses on last life', () {
    final slime = BossData.bossById('slime_boss')!;
    final golem = BossData.bossById('egg_golem')!;

    expect(
      BossBattleLogic.showManualLastLifeGlow(
        slime,
        livesRemaining: 1,
        maxLives: 1,
      ),
      isFalse,
    );
    expect(
      BossBattleLogic.showManualLastLifeGlow(
        golem,
        livesRemaining: 1,
        maxLives: 2,
      ),
      isTrue,
    );
    expect(
      BossBattleLogic.rageModeSpeedScale(
        boss: golem,
        livesRemaining: 1,
        maxLives: 2,
        rageModeActive: true,
      ),
      BossBattleLogic.manualRageModeSpeedMultiplier,
    );
    expect(
      BossBattleLogic.rageModeSpeedScale(
        boss: slime,
        livesRemaining: 1,
        maxLives: 1,
        rageModeActive: true,
      ),
      1.0,
    );
  });

  test('hard phase unlock requires five boss wins', () {
    expect(BossBattleLogic.isHardPhaseUnlocked(0), isFalse);
    expect(BossBattleLogic.isHardPhaseUnlocked(4), isFalse);
    expect(BossBattleLogic.isHardPhaseUnlocked(5), isTrue);
  });

  test('nightmare unlock requires seven hard phase wins', () {
    expect(BossBattleLogic.isNightmareUnlocked(0), isFalse);
    expect(BossBattleLogic.isNightmareUnlocked(6), isFalse);
    expect(BossBattleLogic.isNightmareUnlocked(7), isTrue);
  });

  test('hard phase shield misses start at 8 increase by 2 capped at 16', () {
    expect(
      BossBattleLogic.manualRequiredMisses(0, mode: ManualBattleMode.hard),
      8,
    );
    expect(
      BossBattleLogic.manualRequiredMisses(1, mode: ManualBattleMode.hard),
      10,
    );
    expect(
      BossBattleLogic.manualRequiredMisses(4, mode: ManualBattleMode.hard),
      16,
    );
    expect(
      BossBattleLogic.manualRequiredMisses(20, mode: ManualBattleMode.hard),
      16,
    );
  });

  test('nightmare shield misses start at 10 increase by 2 capped at 20', () {
    expect(
      BossBattleLogic.manualRequiredMisses(0, mode: ManualBattleMode.nightmare),
      10,
    );
    expect(
      BossBattleLogic.manualRequiredMisses(5, mode: ManualBattleMode.nightmare),
      20,
    );
  });

  test('hard phase projectile speed starts 40 percent faster', () {
    expect(
      BossBattleLogic.manualProjectileSpeedMultiplier(
        elapsedSeconds: 0,
        bossHitCount: 0,
        mode: ManualBattleMode.hard,
      ),
      1.40,
    );
  });

  test('nightmare projectile speed starts 75 percent faster', () {
    expect(
      BossBattleLogic.manualProjectileSpeedMultiplier(
        elapsedSeconds: 0,
        bossHitCount: 0,
        mode: ManualBattleMode.nightmare,
      ),
      1.75,
    );
  });

  test('hard phase firing interval is 65 percent of normal', () {
    final slime = BossData.bossById('slime_boss')!;
    expect(
      BossBattleLogic.manualProjectileIntervalMs(
        slime,
        0,
        mode: ManualBattleMode.hard,
      ),
      (slime.projectileIntervalMs * 0.65).round(),
    );
  });

  test('nightmare firing interval respects lower minimum cap', () {
    final slime = BossData.bossById('slime_boss')!;
    expect(
      BossBattleLogic.manualProjectileIntervalMs(
        slime,
        100,
        mode: ManualBattleMode.nightmare,
      ),
      BossBattleLogic.nightmareMinProjectileIntervalMs,
    );
  });

  test('reward multipliers by manual battle mode', () {
    expect(BossBattleLogic.manualRewardMultiplier(ManualBattleMode.normal), 1);
    expect(BossBattleLogic.manualRewardMultiplier(ManualBattleMode.hard), 2);
    expect(
      BossBattleLogic.manualRewardMultiplier(ManualBattleMode.nightmare),
      3,
    );
  });

  test('manual shield misses scale with successful egg hits capped at 12', () {
    expect(BossBattleLogic.manualRequiredMisses(0), 5);
    expect(BossBattleLogic.manualRequiredMisses(1), 6);
    expect(BossBattleLogic.manualRequiredMisses(3), 8);
    expect(BossBattleLogic.manualRequiredMisses(7), 12);
    expect(BossBattleLogic.manualRequiredMisses(20), 12);
  });

  test('manual projectile speed multiplier scales with time and hits', () {
    expect(
      BossBattleLogic.manualProjectileSpeedMultiplier(
        elapsedSeconds: 0,
        bossHitCount: 0,
      ),
      1.0,
    );
    expect(
      BossBattleLogic.manualProjectileSpeedMultiplier(
        elapsedSeconds: 15,
        bossHitCount: 0,
      ),
      1.5,
    );
    expect(
      BossBattleLogic.manualProjectileSpeedMultiplier(
        elapsedSeconds: 0,
        bossHitCount: 2,
      ),
      closeTo(1.5, 0.001),
    );
  });

  test('manual boss move speed scales with hits capped at 2.5x', () {
    final slime = BossData.bossById('slime_boss')!;
    expect(BossBattleLogic.manualBossMoveSpeed(slime, 0), 45);
    expect(BossBattleLogic.manualBossMoveSpeed(slime, 2), closeTo(58.5, 0.001));
    expect(
      BossBattleLogic.manualBossMoveSpeed(slime, 20),
      closeTo(45 * 2.5, 0.001),
    );
  });

  test('manual projectile interval speeds up with hits down to minimum', () {
    final slime = BossData.bossById('slime_boss')!;
    expect(BossBattleLogic.manualProjectileIntervalMs(slime, 0), 1200);
    expect(
      BossBattleLogic.manualProjectileIntervalMs(slime, 3),
      lessThan(1200),
    );
    expect(
      BossBattleLogic.manualProjectileIntervalMs(slime, 100),
      BossBattleLogic.manualMinProjectileIntervalMs,
    );
  });

  test('manual battle uses three player lives', () {
    expect(BossBattleLogic.manualBattleLives, 3);
  });

  test(
    'manual boss aim target predicts player velocity with per-boss error',
    () {
      final slime = BossData.bossById('slime_boss')!;
      final rooster = BossData.bossById('shadow_rooster')!;

      final slimeTarget = BossBattleLogic.manualBossAimTarget(
        boss: slime,
        playerX: 160,
        playerVelocityX: 8,
        minX: 40,
        maxX: 280,
        aimError: 0,
      );
      final roosterTarget = BossBattleLogic.manualBossAimTarget(
        boss: rooster,
        playerX: 160,
        playerVelocityX: 8,
        minX: 40,
        maxX: 280,
        aimError: 0,
      );

      expect(slimeTarget, lessThan(roosterTarget));
      expect(slime.manualAimErrorMax, greaterThan(rooster.manualAimErrorMax));
      expect(
        slime.manualPredictionStrength,
        lessThan(rooster.manualPredictionStrength),
      );
    },
  );

  test('boss definitions define manual aim tuning', () {
    for (final boss in BossData.bosses) {
      expect(boss.manualAimAccuracy, inInclusiveRange(0.0, 1.0));
      expect(boss.manualPredictionStrength, greaterThan(0));
      expect(boss.manualAimErrorMax, greaterThan(0));
      expect(boss.manualAimRecalcMs, inInclusiveRange(200, 600));
    }
  });

  test('boss definitions define manual projectile and movement tuning', () {
    for (final boss in BossData.bosses) {
      expect(boss.projectileIntervalMs, greaterThan(0));
      expect(boss.projectileSpeed, greaterThan(0));
      expect(boss.manualBossMoveSpeed, greaterThan(0));
    }

    expect(BossData.bossById('slime_boss')!.manualBossMoveSpeed, 45);
    expect(BossData.bossById('egg_golem')!.manualBossMoveSpeed, 70);
    expect(BossData.bossById('shadow_rooster')!.manualBossMoveSpeed, 95);
  });
}
