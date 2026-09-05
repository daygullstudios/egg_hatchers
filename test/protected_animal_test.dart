import 'dart:convert';

import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/models/player_state.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('secret reward badge marks chosen animal as protected', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    game.devSetOwnedAnimalsForTesting(const [
      OwnedAnimal(animalId: 'chicken', quantity: 1),
    ]);
    game.devGrantSecretRewardBadge();

    final name = game.applySecretRewardBadge(
      animalId: 'chicken',
      mutationId: 'none',
      isProtected: false,
    );
    expect(name, isNotNull);

    final protected = game.ownedAnimals.where((owned) => owned.isProtected);
    expect(protected.length, 1);
    expect(protected.first.animalId, 'chicken');
    expect(protected.first.isSecretReward, isTrue);

    game.dispose();
  });

  test('protected animals cannot be sold', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    game.devSetOwnedAnimalsForTesting(const [
      OwnedAnimal(
        animalId: 'galaxy_dragon',
        quantity: 1,
        level: 2,
        mutationId: 'shadow',
        isProtected: true,
        isSecretReward: true,
      ),
      OwnedAnimal(
        animalId: 'chicken',
        quantity: 1,
        mutationId: 'none',
      ),
    ]);

    final coinsBefore = game.coins;
    expect(
      game.sellOwnedAnimal('galaxy_dragon', 'shadow', isProtected: true),
      isNull,
    );
    expect(game.ownedAnimals.length, 2);
    expect(game.coins, coinsBefore);

    final sold = game.sellOwnedAnimal('chicken', 'none');
    expect(sold, isNotNull);
    expect(game.ownedAnimals.length, 1);
    expect(game.ownedAnimals.first.isProtected, isTrue);

    game.dispose();
  });

  test('rebirth preserves protected animals only', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    game.devSetOwnedAnimalsForTesting(const [
      OwnedAnimal(
        animalId: 'alien_slime',
        quantity: 1,
        level: 3,
        mutationId: 'golden',
        isProtected: true,
        isSecretReward: true,
      ),
      OwnedAnimal(animalId: 'chicken', quantity: 5, mutationId: 'none'),
    ]);
    game.setLifetimeCoinsEarned(1000000);

    expect(game.performRebirth(), isTrue);
    expect(game.ownedAnimals.length, 1);
    expect(game.ownedAnimals.first.animalId, 'alien_slime');
    expect(game.ownedAnimals.first.mutationId, 'golden');
    expect(game.ownedAnimals.first.level, 3);
    expect(game.ownedAnimals.first.isProtected, isTrue);
    expect(game.ownedAnimals.first.isSecretReward, isTrue);
    expect(game.coins, 250);
    expect(game.lifetimeCoinsEarned, 0);
    expect(game.luckLevel, 1);

    game.dispose();
  });

  test('elite boss reward animals are marked elite and protected on grant', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    game.grantBossRewardAnimal('slime_king', mutationId: 'none');
    expect(game.ownedAnimals.single.isEliteReward, isTrue);
    expect(game.ownedAnimals.single.isProtected, isTrue);
    expect(game.ownedAnimals.single.isSecretReward, isFalse);
    expect(game.ownedAnimals.single.mutationId, 'none');

    game.grantBossRewardAnimal('slime_king', mutationId: 'none');
    expect(game.ownedAnimals.single.quantity, 2);
    expect(game.ownedAnimals.single.isEliteReward, isTrue);

    game.dispose();
  });

  test('elite boss reward rolls normal mutations and keeps elite flags', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    final grant = game.grantBossRewardAnimal(
      'slime_king',
      mutationId: 'golden',
    );
    expect(grant?.displayName, 'Golden Slime King');
    expect(game.ownedAnimals.single.mutationId, 'golden');
    expect(game.ownedAnimals.single.isEliteReward, isTrue);
    expect(game.ownedAnimals.single.isProtected, isTrue);

    game.dispose();
  });

  test('mutated elite rewards stack by mutation', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    game.grantBossRewardAnimal('egg_guardian', mutationId: 'rainbow');
    game.grantBossRewardAnimal('egg_guardian', mutationId: 'none');
    expect(game.ownedAnimals.length, 2);
    expect(
      game.ownedAnimals.every((owned) => owned.isEliteReward && owned.isProtected),
      isTrue,
    );

    game.dispose();
  });

  test('existing elite reward animals migrate to elite on load', () async {
    final preMigration = PlayerState.initial().copyWith(
      ownedAnimals: const [
        OwnedAnimal(animalId: 'shadow_phoenix', quantity: 1),
      ],
    );
    SharedPreferences.setMockInitialValues({
      'egg_hatchers_player_state': jsonEncode(preMigration.toJson()),
    });

    final game = GameService();
    await game.initialize();

    expect(game.ownedAnimals.single.isEliteReward, isTrue);
    expect(game.ownedAnimals.single.isProtected, isTrue);
    expect(game.ownedAnimals.single.isSecretReward, isFalse);

    game.dispose();
  });

  test('elite boss reward animals deserialize as elite', () {
    final restored = OwnedAnimal.fromJson({
      'animalId': 'egg_guardian',
      'quantity': 2,
      'mutationId': 'none',
    });
    expect(restored.isEliteReward, isTrue);
    expect(restored.isProtected, isTrue);
    expect(restored.isSecretReward, isFalse);
  });

  test('isProtected defaults false for older owned animal saves', () {
    final restored = OwnedAnimal.fromJson({
      'animalId': 'chicken',
      'quantity': 2,
      'level': 1,
      'mutationId': 'none',
    });
    expect(restored.isProtected, isFalse);
    expect(restored.isSecretReward, isFalse);
  });

  test('legacy protected animals default isSecretReward true', () {
    final restored = OwnedAnimal.fromJson({
      'animalId': 'void_mouse',
      'quantity': 1,
      'level': 1,
      'mutationId': 'none',
      'isProtected': true,
    });
    expect(restored.isSecretReward, isTrue);
  });

  test('isProtected round-trips through player state json', () {
    final state = PlayerState.initial().copyWith(
      ownedAnimals: const [
        OwnedAnimal(
          animalId: 'moon_cat',
          quantity: 1,
          mutationId: 'rainbow',
          isProtected: true,
          isSecretReward: true,
        ),
      ],
    );
    final restored = PlayerState.fromJson(state.toJson());
    expect(restored.ownedAnimals.first.isProtected, isTrue);
    expect(restored.ownedAnimals.first.isSecretReward, isTrue);
  });
}
