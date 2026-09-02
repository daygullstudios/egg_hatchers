import 'package:egg_hatchers/utils/arena_ability_visuals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArenaAbilityVisuals', () {
    test('gives DayGull animals their glitch identity', () {
      for (final animalId in [
        'boba_bazooka',
        'crossword_beast',
        'the_hatched_egg',
      ]) {
        final identity = ArenaAbilityVisuals.forAnimal(
          animalId: animalId,
          mutationId: 'none',
        );

        expect(identity.motif, ArenaAbilityMotif.glitch);
      }
    });

    test('preserves an animal motif while mutation colors take over', () {
      final normal = ArenaAbilityVisuals.forAnimal(
        animalId: 'shadow_phoenix',
        mutationId: 'none',
      );
      final golden = ArenaAbilityVisuals.forAnimal(
        animalId: 'shadow_phoenix',
        mutationId: 'golden',
      );
      final rainbow = ArenaAbilityVisuals.forAnimal(
        animalId: 'shadow_phoenix',
        mutationId: 'rainbow',
      );

      expect(normal.motif, ArenaAbilityMotif.shadow);
      expect(golden.motif, normal.motif);
      expect(rainbow.motif, normal.motif);
      expect(golden.primary, isNot(normal.primary));
      expect(rainbow.secondary, isNot(golden.secondary));
    });

    test('supports every visual motif', () {
      final representatives = <String, ArenaAbilityMotif>{
        'chicken': ArenaAbilityMotif.feather,
        'fire_dragon': ArenaAbilityMotif.flame,
        'dolphin': ArenaAbilityMotif.water,
        'rabbit': ArenaAbilityMotif.nature,
        'egg_guardian': ArenaAbilityMotif.stone,
        'nebula_hydra': ArenaAbilityMotif.cosmic,
        'night_rooster': ArenaAbilityMotif.shadow,
        'slime_king': ArenaAbilityMotif.slime,
        'boba_bazooka': ArenaAbilityMotif.glitch,
        'capybara': ArenaAbilityMotif.neutral,
      };

      for (final entry in representatives.entries) {
        final identity = ArenaAbilityVisuals.forAnimal(
          animalId: entry.key,
          mutationId: 'none',
        );
        expect(identity.motif, entry.value, reason: entry.key);
        expect(identity.primary.a, greaterThan(0), reason: entry.key);
        expect(identity.secondary.a, greaterThan(0), reason: entry.key);
      }
    });
  });
}
