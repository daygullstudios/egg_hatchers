import 'dart:math';

import '../data/game_data.dart';
import '../models/arena.dart';
import '../models/mutation.dart';
import '../models/owned_animal.dart';
import 'battle_power_logic.dart';

class ArenaLogic {
  ArenaLogic._();

  static const teamSize = 3;
  static const startingRating = 1000;

  static const _botNames = [
    'Nova',
    'Milo',
    'Juniper',
    'Pixel',
    'Riley',
    'Sunny',
    'Skye',
    'Ember',
    'Atlas',
    'Luna',
    'Kai',
    'Remy',
  ];

  static const _botTitles = [
    'Nest Defender',
    'Shell Strategist',
    'Mutation Hunter',
    'Hatchery Hero',
    'Arena Regular',
    'Egg Tactician',
  ];

  static String ownedKey(OwnedAnimal owned) =>
      '${owned.animalId}:${owned.mutationId}';

  static ArenaFighter fighterFromOwned(OwnedAnimal owned) => ArenaFighter(
    animalId: owned.animalId,
    mutationId: owned.mutationId,
    level: owned.level,
    power: BattlePowerLogic.battlePowerForOwnedAnimal(owned),
  );

  static List<OwnedAnimal> recommendedTeam(List<OwnedAnimal> owned) {
    final sorted = [...owned]
      ..sort(
        (a, b) => BattlePowerLogic.battlePowerForOwnedAnimal(
          b,
        ).compareTo(BattlePowerLogic.battlePowerForOwnedAnimal(a)),
      );
    return sorted.take(teamSize).toList();
  }

  static ArenaOpponent generateOpponent({
    required List<ArenaFighter> playerTeam,
    required int playerRating,
    required Random random,
    int? ratingOffset,
    Set<String> excludedNames = const {},
  }) {
    final targetTotal = max(
      teamSize,
      playerTeam.fold<int>(0, (sum, fighter) => sum + fighter.power),
    );
    final ratingDrift = ratingOffset ?? random.nextInt(121) - 60;
    final opponentRating = max(100, playerRating + ratingDrift);
    final strengthFactor =
        (0.90 + random.nextDouble() * 0.20) *
        (1 + (opponentRating - playerRating) / 1800);
    final targetPerFighter = max(
      1,
      (targetTotal * strengthFactor / teamSize).round(),
    ).toInt();
    final fighters = <ArenaFighter>[];

    for (var i = 0; i < teamSize; i++) {
      final variation = 0.78 + random.nextDouble() * 0.44;
      final targetPower = max(1, (targetPerFighter * variation).round());
      final mutation = _rollBotMutation(random, opponentRating);
      final affordableAnimals = GameData.animals.where((animal) {
        final base = animal.coinsPerSecond * mutation.incomeMultiplier;
        return base <= max(1, targetPower * 1.35);
      }).toList();
      final pool = affordableAnimals.isEmpty
          ? ([...GameData.animals]
              ..sort((a, b) => a.coinsPerSecond.compareTo(b.coinsPerSecond)))
          : affordableAnimals;
      final animal = affordableAnimals.isEmpty
          ? pool.first
          : pool[random.nextInt(pool.length)];
      final basePower = max(
        1,
        animal.coinsPerSecond * mutation.incomeMultiplier,
      );
      final level = max(1, (targetPower / basePower).round());
      fighters.add(
        ArenaFighter(
          animalId: animal.id,
          mutationId: mutation.id,
          level: level,
          power: basePower * level,
        ),
      );
    }

    final availableNames = _botNames
        .where((name) => !excludedNames.contains(name))
        .toList();
    final names = availableNames.isEmpty ? _botNames : availableNames;
    return ArenaOpponent(
      name: names[random.nextInt(names.length)],
      title: _botTitles[random.nextInt(_botTitles.length)],
      rating: opponentRating,
      team: fighters,
      seed: random.nextInt(1 << 31),
    );
  }

  static List<ArenaOpponent> generateOpponentRoster({
    required List<ArenaFighter> playerTeam,
    required int playerRating,
    required Random random,
    int count = 8,
  }) {
    final offsets = <int>[-120, -85, -50, -20, 20, 50, 85, 120]
      ..shuffle(random);
    final usedNames = <String>{};
    final opponents = <ArenaOpponent>[];
    for (var i = 0; i < count.clamp(1, _botNames.length); i++) {
      final offset = i < offsets.length
          ? offsets[i]
          : random.nextInt(241) - 120;
      final opponent = generateOpponent(
        playerTeam: playerTeam,
        playerRating: playerRating,
        random: random,
        ratingOffset: offset,
        excludedNames: usedNames,
      );
      usedNames.add(opponent.name);
      opponents.add(opponent);
    }
    opponents.sort((a, b) => a.rating.compareTo(b.rating));
    return opponents;
  }

  static ArenaBattleSimulation simulate({
    required List<ArenaFighter> playerTeam,
    required ArenaOpponent opponent,
  }) {
    final random = Random(opponent.seed);
    final playerHealth = playerTeam
        .map((fighter) => fighter.maxHealth)
        .toList();
    final botHealth = opponent.team
        .map((fighter) => fighter.maxHealth)
        .toList();
    final steps = <ArenaBattleStep>[];
    var playerIndex = 0;
    var botIndex = 0;
    var playerTurn = random.nextBool();

    while (playerIndex < playerTeam.length && botIndex < opponent.team.length) {
      final attacker = playerTurn
          ? playerTeam[playerIndex]
          : opponent.team[botIndex];
      final defender = playerTurn
          ? opponent.team[botIndex]
          : playerTeam[playerIndex];
      final variance = 0.84 + random.nextDouble() * 0.32;
      final matchup = (attacker.power / max(1, defender.power)).clamp(
        0.55,
        1.65,
      );
      final damage = max(
        1,
        (attacker.attack * variance * sqrt(matchup)).round(),
      );

      if (playerTurn) {
        botHealth[botIndex] = max(0, botHealth[botIndex] - damage);
        final defeated = botHealth[botIndex] == 0;
        steps.add(
          ArenaBattleStep(
            playerAttacks: true,
            attackerIndex: playerIndex,
            targetIndex: botIndex,
            damage: damage,
            targetHealthAfter: botHealth[botIndex],
            targetDefeated: defeated,
          ),
        );
        if (defeated) botIndex++;
      } else {
        playerHealth[playerIndex] = max(0, playerHealth[playerIndex] - damage);
        final defeated = playerHealth[playerIndex] == 0;
        steps.add(
          ArenaBattleStep(
            playerAttacks: false,
            attackerIndex: botIndex,
            targetIndex: playerIndex,
            damage: damage,
            targetHealthAfter: playerHealth[playerIndex],
            targetDefeated: defeated,
          ),
        );
        if (defeated) playerIndex++;
      }
      playerTurn = !playerTurn;
    }

    return ArenaBattleSimulation(
      playerTeam: playerTeam,
      opponent: opponent,
      steps: steps,
      playerWon: botIndex >= opponent.team.length,
    );
  }

  static ArenaReward rewardFor({
    required bool won,
    required int playerRating,
    required int opponentRating,
    required int opponentPower,
    required int currentStreak,
  }) {
    final difference = opponentRating - playerRating;
    if (!won) {
      return ArenaReward(
        ratingChange: -(12 - difference ~/ 25).clamp(6, 18),
        coins: 0,
        battleTokens: 0,
      );
    }
    final ratingGain = (18 + difference ~/ 25).clamp(12, 28);
    final streak = currentStreak + 1;
    final coins =
        max(100, opponentPower ~/ 12) * (100 + min(30, streak * 3)) ~/ 100;
    final tokens =
        1 + (opponentRating >= 1250 ? 1 : 0) + (streak % 5 == 0 ? 1 : 0);
    return ArenaReward(
      ratingChange: ratingGain,
      coins: coins,
      battleTokens: tokens,
    );
  }

  static String divisionFor(int rating) {
    if (rating >= 1800) return 'Celestial';
    if (rating >= 1500) return 'Mythic';
    if (rating >= 1250) return 'Diamond';
    if (rating >= 1050) return 'Gold';
    if (rating >= 850) return 'Silver';
    return 'Bronze';
  }

  static Mutation _rollBotMutation(Random random, int rating) {
    final roll = random.nextInt(100);
    final id = rating >= 1600 && roll < 4
        ? 'boss'
        : rating >= 1250 && roll < 13
        ? 'shadow'
        : roll < 28
        ? 'rainbow'
        : roll < 55
        ? 'golden'
        : 'none';
    return GameData.mutationById(id)!;
  }
}
