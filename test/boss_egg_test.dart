import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/utils/luck_logic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('boss mutation not rollable before unlock', () {
    for (var level = 1; level <= LuckLogic.maxLevel; level++) {
      final weights = LuckLogic.mutationWeights(level);
      expect(weights.containsKey('boss'), isFalse);
      expect(
        LuckLogic.mutationPercentages(
          level,
        ).values.fold<double>(0, (a, b) => a + b),
        closeTo(100.0, 0.001),
      );
    }
  });

  test('boss mutation chance after unlock totals 100 percent', () {
    for (var level = 1; level <= LuckLogic.maxLevel; level++) {
      final percentages = LuckLogic.mutationPercentages(
        level,
        bossMutationUnlocked: true,
      );
      final sum = percentages.values.fold<double>(0, (total, p) => total + p);
      expect(sum, closeTo(100.0, 0.001));
      expect(percentages['boss']!, greaterThan(0));
      expect(LuckLogic.totalWeight(level, bossMutationUnlocked: true), 10000);
    }

    final level1 = LuckLogic.mutationPercentages(1, bossMutationUnlocked: true);
    expect(level1['none'], closeTo(69.5, 0.01));
    expect(level1['boss'], closeTo(0.5, 0.01));
  });

  test('boss egg costs battle tokens not coins', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    final bossEgg = GameData.battleEggs.first;
    expect(bossEgg.cost, 60);
    expect(bossEgg.usesBattleTokens, isTrue);

    expect(game.isEggUnlocked(bossEgg), isFalse);

    game.devSetOwnedAnimalsForTesting([
      const OwnedAnimal(animalId: 'chicken', quantity: 1),
    ]);
    expect(game.isEggUnlocked(bossEgg), isTrue);

    final coinsBefore = game.coins;
    game.devAddBattleTokens(60);
    expect(game.canBuyEgg(bossEgg), isTrue);

    game.buyEgg(bossEgg);
    expect(game.coins, coinsBefore);
    expect(game.battleTokens, 0);

    game.dispose();
  });

  test('unlock and apply boss mutation use battle tokens', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    game.devAddBattleTokens(150);
    game.devSetOwnedAnimalsForTesting([
      const OwnedAnimal(animalId: 'chicken', quantity: 2, level: 3),
    ]);

    expect(game.unlockBossMutation(), isTrue);
    expect(game.bossMutationUnlocked, isTrue);
    expect(game.battleTokens, 110);

    expect(
      game.applyBossMutation(
        const OwnedAnimal(animalId: 'chicken', quantity: 2, level: 3),
      ),
      isTrue,
    );
    expect(game.battleTokens, 10);

    final chickenStacks = game.ownedAnimals
        .where((owned) => owned.animalId == 'chicken')
        .toList();
    expect(chickenStacks.length, 2);
    final normal = chickenStacks.firstWhere((s) => s.mutationId == 'none');
    final boss = chickenStacks.firstWhere((s) => s.mutationId == 'boss');
    expect(normal.quantity, 1);
    expect(normal.level, 3);
    expect(boss.quantity, 1);
    expect(boss.level, 3);

    game.dispose();
  });

  test('boss mutation unlock persists after rebirth', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    game.setLifetimeCoinsEarned(1000000);
    game.devAddBattleTokens(40);
    game.devSetOwnedAnimalsForTesting([
      const OwnedAnimal(animalId: 'chicken', quantity: 1, isProtected: true),
    ]);
    game.unlockBossMutation();
    game.performRebirth();

    expect(game.bossMutationUnlocked, isTrue);
    expect(game.ownedAnimals.length, 1);
    expect(game.ownedAnimals.first.isProtected, isTrue);

    game.dispose();
  });

  test('boss egg pets stay below void egg peak income', () {
    final nightRooster = GameData.animalById('night_rooster')!;
    final nebulaHydra = GameData.animalById('nebula_hydra')!;
    expect(nightRooster.coinsPerSecond, lessThan(nebulaHydra.coinsPerSecond));
    expect(nightRooster.coinsPerSecond, 450000);
  });
}
