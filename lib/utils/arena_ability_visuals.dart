import 'package:flutter/material.dart';

enum ArenaAbilityMotif {
  neutral,
  feather,
  flame,
  water,
  nature,
  stone,
  cosmic,
  shadow,
  slime,
  glitch,
}

class ArenaAbilityVisualIdentity {
  const ArenaAbilityVisualIdentity({
    required this.primary,
    required this.secondary,
    required this.motif,
  });

  final Color primary;
  final Color secondary;
  final ArenaAbilityMotif motif;
}

class ArenaAbilityVisuals {
  ArenaAbilityVisuals._();

  static ArenaAbilityVisualIdentity forAnimal({
    required String animalId,
    required String mutationId,
  }) {
    final base = _baseIdentity(animalId);
    return switch (mutationId) {
      'golden' => ArenaAbilityVisualIdentity(
        primary: const Color(0xFFFFD54F),
        secondary: const Color(0xFFFF8F00),
        motif: base.motif,
      ),
      'rainbow' => ArenaAbilityVisualIdentity(
        primary: const Color(0xFF5DEBFF),
        secondary: const Color(0xFFFF5CCA),
        motif: base.motif,
      ),
      'shadow' => ArenaAbilityVisualIdentity(
        primary: const Color(0xFFB388FF),
        secondary: const Color(0xFF4527A0),
        motif: base.motif,
      ),
      'boss' => ArenaAbilityVisualIdentity(
        primary: const Color(0xFFFF6E6E),
        secondary: const Color(0xFFFFC857),
        motif: base.motif,
      ),
      _ => base,
    };
  }

  static ArenaAbilityVisualIdentity _baseIdentity(String id) {
    if (_containsAny(id, const ['crossword', 'boba', 'hatched'])) {
      return const ArenaAbilityVisualIdentity(
        primary: Color(0xFF67E8FF),
        secondary: Color(0xFFB65CFF),
        motif: ArenaAbilityMotif.glitch,
      );
    }
    if (_containsAny(id, const ['shadow', 'night', 'void', 'eclipse'])) {
      return const ArenaAbilityVisualIdentity(
        primary: Color(0xFFB388FF),
        secondary: Color(0xFF311B92),
        motif: ArenaAbilityMotif.shadow,
      );
    }
    if (_containsAny(id, const ['slime', 'ooze'])) {
      return const ArenaAbilityVisualIdentity(
        primary: Color(0xFF69F0AE),
        secondary: Color(0xFF00A896),
        motif: ArenaAbilityMotif.slime,
      );
    }
    if (_containsAny(id, const [
      'moon',
      'star',
      'galaxy',
      'cosmic',
      'nebula',
      'alien',
      'unicorn',
    ])) {
      return const ArenaAbilityVisualIdentity(
        primary: Color(0xFF80D8FF),
        secondary: Color(0xFFE879F9),
        motif: ArenaAbilityMotif.cosmic,
      );
    }
    if (_containsAny(id, const [
      'fish',
      'dolphin',
      'shark',
      'penguin',
      'seal',
      'polar',
      'snow',
      'turtle',
    ])) {
      return const ArenaAbilityVisualIdentity(
        primary: Color(0xFF67E8F9),
        secondary: Color(0xFF2563EB),
        motif: ArenaAbilityMotif.water,
      );
    }
    if (_containsAny(id, const [
      'dragon',
      'fox',
      'tiger',
      'lion',
      'phoenix',
      't_rex',
      'raptor',
      'saber',
    ])) {
      return const ArenaAbilityVisualIdentity(
        primary: Color(0xFFFFB74D),
        secondary: Color(0xFFFF3D00),
        motif: ArenaAbilityMotif.flame,
      );
    }
    if (_containsAny(id, const [
      'golem',
      'guardian',
      'fossil',
      'scarab',
      'triceratops',
    ])) {
      return const ArenaAbilityVisualIdentity(
        primary: Color(0xFFFFCC80),
        secondary: Color(0xFF8D6E63),
        motif: ArenaAbilityMotif.stone,
      );
    }
    if (_containsAny(id, const ['chicken', 'rooster', 'parrot', 'owl'])) {
      return const ArenaAbilityVisualIdentity(
        primary: Color(0xFFFFF176),
        secondary: Color(0xFFFF7043),
        motif: ArenaAbilityMotif.feather,
      );
    }
    if (_containsAny(id, const [
      'deer',
      'rabbit',
      'bunny',
      'bear',
      'horse',
      'monkey',
      'gorilla',
      'cow',
      'pig',
      'sheep',
    ])) {
      return const ArenaAbilityVisualIdentity(
        primary: Color(0xFFAED581),
        secondary: Color(0xFF43A047),
        motif: ArenaAbilityMotif.nature,
      );
    }
    return const ArenaAbilityVisualIdentity(
      primary: Color(0xFF4DD0E1),
      secondary: Color(0xFF5C6BC0),
      motif: ArenaAbilityMotif.neutral,
    );
  }

  static bool _containsAny(String value, List<String> fragments) {
    return fragments.any(value.contains);
  }
}
