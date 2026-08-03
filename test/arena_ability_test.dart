import 'dart:math';

import 'package:egg_hatchers/data/arena_ability_data.dart';
import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/models/arena.dart';
import 'package:egg_hatchers/utils/arena_combat_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every animal has three uniquely named arena abilities', () {
    final allNames = <String>{};

    for (final animal in GameData.animals) {
      expect(ArenaAbilityData.hasLoadout(animal.id), isTrue, reason: animal.id);
      final abilities = ArenaAbilityData.forAnimal(animal.id);
      expect(abilities, hasLength(3), reason: animal.id);
      expect(
        abilities.map((ability) => ability.energyCost),
        orderedEquals([2, 4, 7]),
        reason: animal.id,
      );
      for (final ability in abilities) {
        expect(allNames.add(ability.name), isTrue, reason: ability.name);
      }
    }
  });

  test('energy circles always pause before the next spawn', () {
    final random = Random(9);
    for (var i = 0; i < 100; i++) {
      final delay = ArenaCombatLogic.nextCircleDelay(random);
      expect(delay, greaterThanOrEqualTo(ArenaCombatLogic.minCircleDelay));
      expect(delay, lessThanOrEqualTo(ArenaCombatLogic.maxCircleDelay));
      expect(delay, greaterThan(Duration.zero));
    }
  });

  test('bot only chooses abilities it can afford', () {
    final abilities = ArenaAbilityData.forAnimal('chicken');
    final random = Random(4);

    expect(
      ArenaCombatLogic.chooseBotAbility(
        abilities: abilities,
        energy: 1,
        healthFraction: 1,
        random: random,
      ),
      isNull,
    );

    for (var i = 0; i < 50; i++) {
      final ability = ArenaCombatLogic.chooseBotAbility(
        abilities: abilities,
        energy: 4,
        healthFraction: 0.8,
        random: random,
      );
      expect(ability, isNotNull);
      expect(ability!.energyCost, lessThanOrEqualTo(4));
    }
  });

  test('bot titles produce distinct combat personalities', () {
    expect(
      ArenaCombatLogic.botStyleForTitle('Nest Defender'),
      ArenaBotStyle.defensive,
    );
    expect(
      ArenaCombatLogic.botStyleForTitle('Mutation Hunter'),
      ArenaBotStyle.aggressive,
    );
    expect(
      ArenaCombatLogic.botStyleForTitle('Egg Tactician'),
      ArenaBotStyle.saver,
    );
  });

  test('stronger abilities deal more damage without random variance', () {
    const fighter = ArenaFighter(
      animalId: 'chicken',
      mutationId: 'none',
      level: 10,
      power: 100,
    );
    final abilities = ArenaAbilityData.forAnimal('chicken');
    final quick = ArenaCombatLogic.attackDamage(
      attacker: fighter,
      defender: fighter,
      ability: abilities.first,
      random: Random(2),
    );
    final signature = ArenaCombatLogic.attackDamage(
      attacker: fighter,
      defender: fighter,
      ability: abilities.last,
      random: Random(2),
    );

    expect(signature, greaterThan(quick * 2));
  });

  test('skill grade rewards accuracy, combos, health, and winning', () {
    final strongGrade = ArenaCombatLogic.skillGrade(
      won: true,
      hits: 10,
      misses: 0,
      bestCombo: 10,
      remainingHealth: 100,
      maxHealth: 100,
    );
    final weakGrade = ArenaCombatLogic.skillGrade(
      won: false,
      hits: 2,
      misses: 8,
      bestCombo: 1,
      remainingHealth: 0,
      maxHealth: 100,
    );

    expect(strongGrade, 'S');
    expect(weakGrade, 'D');
  });
}
