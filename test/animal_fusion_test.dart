import 'dart:math';

import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/utils/animal_fusion_logic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnimalFusionLogic', () {
    test('rollFusion fails 20% of the time', () {
      expect(
        AnimalFusionLogic.rollFusion('none', _valuesRandom([0.85])).succeeded,
        isFalse,
      );
    });

    test('rollFusion succeeds and upgrades one step by default', () {
      final roll = AnimalFusionLogic.rollFusion(
        'none',
        _valuesRandom([0.5, 0.5]),
      );
      expect(roll.succeeded, isTrue);
      expect(roll.resultMutationId, 'golden');
      expect(roll.wasLucky, isFalse);
    });

    test('rollFusion can lucky jump two steps on success', () {
      final roll = AnimalFusionLogic.rollFusion(
        'none',
        _valuesRandom([0.5, 0.05]),
      );
      expect(roll.succeeded, isTrue);
      expect(roll.resultMutationId, 'rainbow');
      expect(roll.wasLucky, isTrue);
    });

    test('rainbow success still caps at shadow', () {
      final roll = AnimalFusionLogic.rollFusion(
        'rainbow',
        _valuesRandom([0.5, 0.05]),
      );
      expect(roll.resultMutationId, 'shadow');
      expect(roll.wasLucky, isFalse);
    });

    test('protected and boss stacks cannot fuse', () {
      const protectedStack = OwnedAnimal(
        animalId: 'chicken',
        quantity: 5,
        mutationId: 'none',
        isProtected: true,
        isSecretReward: true,
      );
      expect(
        AnimalFusionLogic.canFuseStack(protectedStack, inBattle: false),
        isFalse,
      );

      const bossStack = OwnedAnimal(
        animalId: 'chicken',
        quantity: 5,
        mutationId: 'boss',
      );
      expect(
        AnimalFusionLogic.canFuseStack(bossStack, inBattle: false),
        isFalse,
      );

      const shadowStack = OwnedAnimal(
        animalId: 'chicken',
        quantity: 5,
        mutationId: 'shadow',
      );
      expect(
        AnimalFusionLogic.canFuseStack(shadowStack, inBattle: false),
        isFalse,
      );
    });

    test('need 2 animals to fuse', () {
      const stack = OwnedAnimal(
        animalId: 'chicken',
        quantity: 1,
        mutationId: 'none',
      );
      expect(
        AnimalFusionLogic.blockReasonText(stack, inBattle: false),
        'Need 2',
      );
    });
  });

  group('GameService fuseAnimals', () {
    late GameService game;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      game = GameService();
      await game.initialize();
      game.devSetOwnedAnimalsForTesting(const [
        OwnedAnimal(animalId: 'chicken', quantity: 2, mutationId: 'none'),
      ]);
    });

    tearDown(() {
      game.dispose();
    });

    test(
      'consumes 2 normal chickens and creates golden chicken on success',
      () {
        final source = game.ownedAnimals.first;
        final outcome = game.fuseAnimals(
          source,
          random: _valuesRandom([0.5, 0.5]),
        );

        expect(outcome, isNotNull);
        expect(outcome!.succeeded, isTrue);
        expect(outcome.resultMutationId, 'golden');
        expect(outcome.wasLucky, isFalse);
        expect(game.ownedAnimals, hasLength(1));
        expect(game.ownedAnimals.first.mutationId, 'golden');
        expect(game.ownedAnimals.first.quantity, 1);
        expect(game.questProgress.totalFusionAttempts, 1);
        expect(game.questProgress.totalSuccessfulFusions, 1);
      },
    );

    for (final scenario in [
      ('golden', [0.5, 0.5]),
      ('rainbow', [0.5, 0.05]),
      (null, [0.9]),
    ]) {
      test('income preview matches ${scenario.$1 ?? 'failure'} outcome', () {
        game.devSetOwnedAnimalsForTesting(const [
          OwnedAnimal(
            animalId: 'chicken',
            quantity: 3,
            level: 8,
            mutationId: 'none',
            sourceEggId: 'basic',
          ),
          OwnedAnimal(
            animalId: 'chicken',
            quantity: 2,
            level: 4,
            mutationId: 'golden',
            sourceEggId: 'farm',
          ),
        ]);
        final before = game.coinsPerSecond;
        final source = game.ownedAnimals.first;
        final preview = game.fusionIncomeChange(source, scenario.$1);
        expect(game.coinsPerSecond, before);
        expect(game.ownedAnimals.first.quantity, 3);
        expect(game.questProgress.totalFusionAttempts, 0);
        game.fuseAnimals(source, random: _valuesRandom(scenario.$2));
        expect(preview, game.coinsPerSecond - before);
      });
    }

    test('income preview refuses invalid results and protected sources', () {
      expect(game.fusionIncomeChange(game.ownedAnimals.first, 'boss'), isNull);
      game.devSetOwnedAnimalsForTesting(const [
        OwnedAnimal(animalId: 'chicken', quantity: 2, isProtected: true),
      ]);
      expect(
        game.fusionIncomeChange(game.ownedAnimals.first, 'golden'),
        isNull,
      );
    });

    test('failure removes both chickens with no output', () {
      final outcome = game.fuseAnimals(
        game.ownedAnimals.first,
        random: _valuesRandom([0.9]),
      );

      expect(outcome?.succeeded, isFalse);
      expect(game.ownedAnimals, isEmpty);
      expect(game.questProgress.totalFailedFusions, 1);
      expect(game.questProgress.totalSuccessfulFusions, 0);
    });

    test('lucky fusion creates rainbow from 2 normal', () {
      final outcome = game.fuseAnimals(
        game.ownedAnimals.first,
        random: _valuesRandom([0.5, 0.05]),
      );

      expect(outcome?.resultMutationId, 'rainbow');
      expect(outcome?.wasLucky, isTrue);
      expect(game.questProgress.totalLuckyFusions, 1);
    });

    test('merges into existing output stack', () {
      game.devSetOwnedAnimalsForTesting(const [
        OwnedAnimal(animalId: 'chicken', quantity: 2, mutationId: 'none'),
        OwnedAnimal(animalId: 'chicken', quantity: 2, mutationId: 'golden'),
      ]);

      game.fuseAnimals(
        game.ownedAnimals.first,
        random: _valuesRandom([0.5, 0.5]),
      );

      final golden = game.ownedAnimal('chicken', mutationId: 'golden');
      expect(golden?.quantity, 3);
    });
  });
}

Random _valuesRandom(List<double> values) => _SeededRandom(values);

class _SeededRandom implements Random {
  _SeededRandom(this._values);

  final List<double> _values;
  var _index = 0;

  @override
  int nextInt(int max) => (nextDouble() * max).floor();

  @override
  double nextDouble() {
    if (_index >= _values.length) return 0.5;
    return _values[_index++];
  }

  @override
  bool nextBool() => nextDouble() < 0.5;
}
