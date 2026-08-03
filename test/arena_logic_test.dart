import 'dart:math';

import 'package:egg_hatchers/models/arena.dart';
import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/utils/arena_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArenaLogic', () {
    test('recommends the three strongest owned animal stacks', () {
      final owned = [
        const OwnedAnimal(animalId: 'chicken', quantity: 1, level: 1),
        const OwnedAnimal(animalId: 'mouse', quantity: 1, level: 5),
        const OwnedAnimal(
          animalId: 'rabbit',
          quantity: 1,
          level: 2,
          mutationId: 'golden',
        ),
        const OwnedAnimal(animalId: 'fox', quantity: 1, level: 1),
      ];

      final team = ArenaLogic.recommendedTeam(owned);

      expect(team, hasLength(3));
      expect(team.map((item) => item.animalId), containsAll(['fox', 'rabbit']));
      expect(team.map(ArenaLogic.ownedKey).toSet(), hasLength(3));
    });

    test('seeded bot team is complete, valid, and near player power', () {
      const team = [
        ArenaFighter(
          animalId: 'fox',
          mutationId: 'none',
          level: 10,
          power: 250,
        ),
        ArenaFighter(
          animalId: 'bear',
          mutationId: 'golden',
          level: 5,
          power: 500,
        ),
        ArenaFighter(
          animalId: 'tiger',
          mutationId: 'none',
          level: 5,
          power: 750,
        ),
      ];

      final opponent = ArenaLogic.generateOpponent(
        playerTeam: team,
        playerRating: 1000,
        random: Random(42),
      );

      expect(opponent.team, hasLength(ArenaLogic.teamSize));
      expect(opponent.team.every((fighter) => fighter.level >= 1), isTrue);
      expect(opponent.team.every((fighter) => fighter.power >= 1), isTrue);
      expect(opponent.totalPower, inInclusiveRange(650, 2600));
      expect(opponent.rating, inInclusiveRange(940, 1060));
    });

    test('same opponent seed always produces the same battle', () {
      const playerTeam = [
        ArenaFighter(
          animalId: 'chicken',
          mutationId: 'none',
          level: 12,
          power: 12,
        ),
      ];
      const opponent = ArenaOpponent(
        name: 'Nova',
        title: 'Arena Regular',
        rating: 1000,
        seed: 77,
        team: [
          ArenaFighter(
            animalId: 'mouse',
            mutationId: 'none',
            level: 10,
            power: 20,
          ),
        ],
      );

      final first = ArenaLogic.simulate(
        playerTeam: playerTeam,
        opponent: opponent,
      );
      final second = ArenaLogic.simulate(
        playerTeam: playerTeam,
        opponent: opponent,
      );

      expect(first.playerWon, second.playerWon);
      expect(first.steps.length, second.steps.length);
      expect(
        first.steps.map((step) => step.damage),
        second.steps.map((step) => step.damage),
      );
      expect(first.steps.last.targetDefeated, isTrue);
    });

    test('win rewards and loss rating changes favor tougher opponents', () {
      final win = ArenaLogic.rewardFor(
        won: true,
        playerRating: 1000,
        opponentRating: 1100,
        opponentPower: 1200,
        currentStreak: 4,
      );
      final toughLoss = ArenaLogic.rewardFor(
        won: false,
        playerRating: 1000,
        opponentRating: 1100,
        opponentPower: 1200,
        currentStreak: 0,
      );
      final easyLoss = ArenaLogic.rewardFor(
        won: false,
        playerRating: 1000,
        opponentRating: 900,
        opponentPower: 1200,
        currentStreak: 0,
      );

      expect(win.ratingChange, greaterThan(18));
      expect(win.coins, greaterThan(0));
      expect(win.battleTokens, 2);
      expect(
        toughLoss.ratingChange.abs(),
        lessThan(easyLoss.ratingChange.abs()),
      );
    });

    test('division labels progress with rating', () {
      expect(ArenaLogic.divisionFor(700), 'Bronze');
      expect(ArenaLogic.divisionFor(1000), 'Silver');
      expect(ArenaLogic.divisionFor(1300), 'Diamond');
      expect(ArenaLogic.divisionFor(1900), 'Celestial');
    });
  });
}
