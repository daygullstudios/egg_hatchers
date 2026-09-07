import 'dart:convert';
import 'dart:io';

import 'package:egg_hatchers/data/arena_ability_data.dart';
import 'package:egg_hatchers/data/game_data.dart';

/// Generates the authoritative Cloudflare battle catalog from Flutter's game
/// data. Run this after changing an animal, mutation, or arena ability.
void main() {
  const outputPath = 'cloudflare/multiplayer/src/game_catalog.generated.ts';
  final encoder = const JsonEncoder.withIndent('  ');
  final animals = {
    for (final animal in GameData.animals)
      animal.id: {
        'coinsPerSecond': animal.coinsPerSecond,
        'abilities': ArenaAbilityData.forAnimal(animal.id)
            .map(
              (ability) => {
                'name': ability.name,
                'energyCost': ability.energyCost,
                'damageScale': ability.damageScale,
                'effect': ability.effect.name,
                'effectScale': ability.effectScale,
              },
            )
            .toList(growable: false),
      },
  };
  final mutations = {
    for (final mutation in GameData.mutations)
      mutation.id: mutation.incomeMultiplier,
  };
  final file = File(outputPath);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync('''// GENERATED FILE. DO NOT EDIT.
// Source: lib/data/game_data.dart and lib/data/arena_ability_data.dart.

export const animalCatalog = ${encoder.convert(animals)} as const;

export const mutationMultipliers = ${encoder.convert(mutations)} as const;
''');
  stdout.writeln('Generated ${file.path}');
}
