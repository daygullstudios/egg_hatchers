import 'package:egg_hatchers/data/arena_ability_data.dart';
import 'package:egg_hatchers/data/boss_data.dart';
import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/models/boss_battle.dart';
import 'package:egg_hatchers/utils/boss_battle_logic.dart';
import 'package:egg_hatchers/utils/rotten_shell_final_battle_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('boss ladder remains tied to the reviewed candidate values', () {
    const expected =
        <
          String,
          ({
            int lives,
            int interval,
            double speed,
            double movement,
            int coins,
            int tokens,
          })
        >{
          'slime_boss': (
            lives: 1,
            interval: 1200,
            speed: 120,
            movement: 45,
            coins: 2500,
            tokens: 1,
          ),
          'egg_golem': (
            lives: 2,
            interval: 950,
            speed: 180,
            movement: 70,
            coins: 25000,
            tokens: 3,
          ),
          'shadow_rooster': (
            lives: 3,
            interval: 750,
            speed: 260,
            movement: 95,
            coins: 250000,
            tokens: 8,
          ),
          'slime_king': (
            lives: 3,
            interval: 700,
            speed: 280,
            movement: 88,
            coins: 500000,
            tokens: 10,
          ),
          'egg_guardian': (
            lives: 4,
            interval: 620,
            speed: 310,
            movement: 102,
            coins: 750000,
            tokens: 12,
          ),
          'shadow_phoenix': (
            lives: 5,
            interval: 550,
            speed: 340,
            movement: 115,
            coins: 1000000,
            tokens: 15,
          ),
          'rotten_shell': (
            lives: 7,
            interval: 480,
            speed: 360,
            movement: 122,
            coins: 2000000,
            tokens: 20,
          ),
        };

    expect(
      BossData.bosses.map((boss) => boss.id).toSet(),
      expected.keys.toSet(),
    );
    for (final boss in BossData.bosses) {
      final values = expected[boss.id]!;
      expect(BossBattleLogic.manualBossLives(boss), values.lives);
      expect(boss.projectileIntervalMs, values.interval);
      expect(boss.projectileSpeed, values.speed);
      expect(boss.manualBossMoveSpeed, values.movement);
      expect(boss.coinReward, values.coins);
      expect(boss.battleTokenReward, values.tokens);
    }
  });

  test('manual difficulty tiers and shields increase predictably', () {
    final slime = BossData.bossById('slime_boss')!;
    final slimeKing = BossData.bossById('slime_king')!;

    expect(BossBattleLogic.manualRequiredMisses(0, boss: slime), 5);
    expect(BossBattleLogic.manualRequiredMisses(1, boss: slime), 6);
    expect(
      BossBattleLogic.manualRequiredMisses(
        0,
        mode: ManualBattleMode.hard,
        boss: slime,
      ),
      8,
    );
    expect(
      BossBattleLogic.manualRequiredMisses(
        0,
        mode: ManualBattleMode.nightmare,
        boss: slime,
      ),
      10,
    );
    expect(BossBattleLogic.manualRequiredMisses(0, boss: slimeKing), 9);
    expect(BossBattleLogic.manualRequiredMisses(1, boss: slimeKing), 11);

    expect(BossBattleLogic.manualRewardMultiplier(ManualBattleMode.normal), 1);
    expect(BossBattleLogic.manualRewardMultiplier(ManualBattleMode.hard), 2);
    expect(
      BossBattleLogic.manualRewardMultiplier(ManualBattleMode.nightmare),
      3,
    );
  });

  test('every animal has a complete affordable ability ladder', () {
    for (final animal in GameData.animals) {
      final abilities = ArenaAbilityData.forAnimal(animal.id);
      expect(abilities, hasLength(3), reason: animal.id);
      expect(abilities.map((ability) => ability.energyCost).toList(), [
        2,
        4,
        7,
      ], reason: animal.id);
    }
  });

  test('Rotten Shell final battle timing and energy area are bounded', () {
    expect(
      RottenShellFinalBattleLogic.energyMoveInterval,
      const Duration(milliseconds: 1500),
    );
    expect(
      RottenShellFinalBattleLogic.bossAttackInterval,
      const Duration(milliseconds: 1850),
    );
    expect(RottenShellFinalBattleLogic.goldenEnergyOneIn, 8);
    expect(RottenShellFinalBattleLogic.energyCenterMin, 0.35);
    expect(RottenShellFinalBattleLogic.energyCenterSpan, 0.30);
    expect(
      RottenShellFinalBattleLogic.energyCenterMin +
          RottenShellFinalBattleLogic.energyCenterSpan,
      closeTo(0.65, 0.000001),
    );
  });
}
