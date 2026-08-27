import '../models/arena.dart';

class ArenaAbilityData {
  ArenaAbilityData._();

  static List<ArenaAbility> forAnimal(String animalId) {
    final loadout = _loadouts[animalId] ?? _fallback;
    return [
      ArenaAbility(name: loadout.quickName, energyCost: 2, damageScale: 1),
      ArenaAbility(
        name: loadout.techniqueName,
        energyCost: 4,
        damageScale: _techniqueDamage(loadout.techniqueEffect),
        effect: loadout.techniqueEffect,
        effectScale: _techniqueEffectScale(loadout.techniqueEffect),
      ),
      ArenaAbility(
        name: loadout.signatureName,
        energyCost: 7,
        damageScale: _signatureDamage(loadout.signatureEffect),
        effect: loadout.signatureEffect,
        effectScale: _signatureEffectScale(loadout.signatureEffect),
      ),
    ];
  }

  static bool hasLoadout(String animalId) => _loadouts.containsKey(animalId);

  static double _techniqueDamage(ArenaAbilityEffect effect) => switch (effect) {
    ArenaAbilityEffect.damage => 1.55,
    ArenaAbilityEffect.shield => 0.8,
    ArenaAbilityEffect.heal => 0.7,
    ArenaAbilityEffect.drain => 1.05,
  };

  static double _signatureDamage(ArenaAbilityEffect effect) => switch (effect) {
    ArenaAbilityEffect.damage => 2.45,
    ArenaAbilityEffect.shield => 1.45,
    ArenaAbilityEffect.heal => 1.25,
    ArenaAbilityEffect.drain => 1.75,
  };

  static double _techniqueEffectScale(ArenaAbilityEffect effect) =>
      switch (effect) {
        ArenaAbilityEffect.damage => 0,
        ArenaAbilityEffect.shield => 0.85,
        ArenaAbilityEffect.heal => 0.62,
        ArenaAbilityEffect.drain => 2,
      };

  static double _signatureEffectScale(ArenaAbilityEffect effect) =>
      switch (effect) {
        ArenaAbilityEffect.damage => 0,
        ArenaAbilityEffect.shield => 1.55,
        ArenaAbilityEffect.heal => 1.1,
        ArenaAbilityEffect.drain => 4,
      };

  static const _fallback = ArenaAbilityLoadout(
    quickName: 'Quick Strike',
    techniqueName: 'Guard Break',
    signatureName: 'Wild Finale',
  );

  static const _loadouts = <String, ArenaAbilityLoadout>{
    'chicken': ArenaAbilityLoadout(
      quickName: 'Chicken Scratch',
      techniqueName: 'Wing Slap',
      signatureName: 'Flock Frenzy',
    ),
    'mouse': ArenaAbilityLoadout(
      quickName: 'Tiny Chomp',
      techniqueName: 'Scurry Shield',
      signatureName: 'Cheese Stampede',
      techniqueEffect: ArenaAbilityEffect.shield,
    ),
    'rabbit': ArenaAbilityLoadout(
      quickName: 'Rapid Kick',
      techniqueName: 'Burrow Dodge',
      signatureName: 'Carrot Barrage',
      techniqueEffect: ArenaAbilityEffect.shield,
    ),
    'fox': ArenaAbilityLoadout(
      quickName: 'Quick Bite',
      techniqueName: 'Tail Feint',
      signatureName: 'Fire Pounce',
      techniqueEffect: ArenaAbilityEffect.drain,
    ),
    'deer': ArenaAbilityLoadout(
      quickName: 'Antler Jab',
      techniqueName: 'Forest Mend',
      signatureName: 'Stampede Crown',
      techniqueEffect: ArenaAbilityEffect.heal,
    ),
    'bear': ArenaAbilityLoadout(
      quickName: 'Paw Swipe',
      techniqueName: 'Thick Hide',
      signatureName: 'Cave Quake',
      techniqueEffect: ArenaAbilityEffect.shield,
    ),
    'tiger': ArenaAbilityLoadout(
      quickName: 'Fang Rush',
      techniqueName: 'Predator Focus',
      signatureName: 'Jungle Maul',
    ),
    'dragon': ArenaAbilityLoadout(
      quickName: 'Claw Swipe',
      techniqueName: 'Scale Guard',
      signatureName: 'Inferno Breath',
      techniqueEffect: ArenaAbilityEffect.shield,
    ),
    'unicorn': ArenaAbilityLoadout(
      quickName: 'Horn Spark',
      techniqueName: 'Prismatic Heal',
      signatureName: 'Rainbow Nova',
      techniqueEffect: ArenaAbilityEffect.heal,
    ),
    'cow': ArenaAbilityLoadout(
      quickName: 'Hoof Bump',
      techniqueName: 'Pasture Guard',
      signatureName: 'Barnyard Charge',
      techniqueEffect: ArenaAbilityEffect.shield,
    ),
    'pig': ArenaAbilityLoadout(
      quickName: 'Snout Slam',
      techniqueName: 'Mud Armor',
      signatureName: 'Truffle Tumble',
      techniqueEffect: ArenaAbilityEffect.shield,
    ),
    'sheep': ArenaAbilityLoadout(
      quickName: 'Wool Whack',
      techniqueName: 'Cozy Recovery',
      signatureName: 'Fleece Cyclone',
      techniqueEffect: ArenaAbilityEffect.heal,
    ),
    'horse': ArenaAbilityLoadout(
      quickName: 'Front Kick',
      techniqueName: 'Gallop Rush',
      signatureName: 'Thunder Hooves',
    ),
    'monkey': ArenaAbilityLoadout(
      quickName: 'Palm Pop',
      techniqueName: 'Banana Swipe',
      signatureName: 'Canopy Chaos',
      techniqueEffect: ArenaAbilityEffect.drain,
    ),
    'parrot': ArenaAbilityLoadout(
      quickName: 'Beak Peck',
      techniqueName: 'Echo Screech',
      signatureName: 'Feather Firestorm',
      techniqueEffect: ArenaAbilityEffect.drain,
    ),
    'snake': ArenaAbilityLoadout(
      quickName: 'Fang Tap',
      techniqueName: 'Coil Crush',
      signatureName: 'Venom Tempest',
    ),
    'gorilla': ArenaAbilityLoadout(
      quickName: 'Knuckle Hit',
      techniqueName: 'Chest Guard',
      signatureName: 'Jungle Breaker',
      techniqueEffect: ArenaAbilityEffect.shield,
    ),
    'fish': ArenaAbilityLoadout(
      quickName: 'Fin Flick',
      techniqueName: 'Bubble Veil',
      signatureName: 'Riptide Rush',
      techniqueEffect: ArenaAbilityEffect.shield,
    ),
    'turtle': ArenaAbilityLoadout(
      quickName: 'Shell Bonk',
      techniqueName: 'Shell Fortress',
      signatureName: 'Tidal Roll',
      techniqueEffect: ArenaAbilityEffect.shield,
    ),
    'dolphin': ArenaAbilityLoadout(
      quickName: 'Nose Jab',
      techniqueName: 'Healing Current',
      signatureName: 'Sonar Tsunami',
      techniqueEffect: ArenaAbilityEffect.heal,
    ),
    'shark': ArenaAbilityLoadout(
      quickName: 'Razor Bite',
      techniqueName: 'Blood Rush',
      signatureName: 'Abyssal Chomp',
    ),
    'penguin': ArenaAbilityLoadout(
      quickName: 'Flipper Slap',
      techniqueName: 'Ice Slide',
      signatureName: 'Blizzard Bellyflop',
      techniqueEffect: ArenaAbilityEffect.shield,
    ),
    'seal': ArenaAbilityLoadout(
      quickName: 'Flipper Clap',
      techniqueName: 'Arctic Snack',
      signatureName: 'Glacier Splash',
      techniqueEffect: ArenaAbilityEffect.heal,
    ),
    'polar_bear': ArenaAbilityLoadout(
      quickName: 'Frost Paw',
      techniqueName: 'Snow Guard',
      signatureName: 'Polar Avalanche',
      techniqueEffect: ArenaAbilityEffect.shield,
    ),
    'snow_owl': ArenaAbilityLoadout(
      quickName: 'Talon Tap',
      techniqueName: 'Silent Siphon',
      signatureName: 'Whiteout Dive',
      techniqueEffect: ArenaAbilityEffect.drain,
    ),
    'raptor': ArenaAbilityLoadout(
      quickName: 'Sickle Claw',
      techniqueName: 'Pack Ambush',
      signatureName: 'Cretaceous Rush',
    ),
    'triceratops': ArenaAbilityLoadout(
      quickName: 'Horn Jab',
      techniqueName: 'Frill Fortress',
      signatureName: 'Tri-Horn Stampede',
      techniqueEffect: ArenaAbilityEffect.shield,
    ),
    't_rex': ArenaAbilityLoadout(
      quickName: 'Titan Bite',
      techniqueName: 'King Roar',
      signatureName: 'Extinction Chomp',
      techniqueEffect: ArenaAbilityEffect.drain,
    ),
    'fossil_dragon': ArenaAbilityLoadout(
      quickName: 'Bone Claw',
      techniqueName: 'Ancient Plating',
      signatureName: 'Fossil Cataclysm',
      techniqueEffect: ArenaAbilityEffect.shield,
    ),
    'moon_cat': ArenaAbilityLoadout(
      quickName: 'Lunar Scratch',
      techniqueName: 'Moonlight Mend',
      signatureName: 'Crescent Pounce',
      techniqueEffect: ArenaAbilityEffect.heal,
    ),
    'star_fox': ArenaAbilityLoadout(
      quickName: 'Comet Bite',
      techniqueName: 'Starlight Steal',
      signatureName: 'Meteor Pounce',
      techniqueEffect: ArenaAbilityEffect.drain,
    ),
    'alien_slime': ArenaAbilityLoadout(
      quickName: 'Plasma Plop',
      techniqueName: 'Cosmic Absorb',
      signatureName: 'UFO Ooze',
      techniqueEffect: ArenaAbilityEffect.heal,
    ),
    'galaxy_dragon': ArenaAbilityLoadout(
      quickName: 'Nebula Claw',
      techniqueName: 'Orbit Shield',
      signatureName: 'Shooting-Star Storm',
      techniqueEffect: ArenaAbilityEffect.shield,
    ),
    'scarab_beetle': ArenaAbilityLoadout(
      quickName: 'Horn Pinch',
      techniqueName: 'Sun Carapace',
      signatureName: 'Pharaoh Swarm',
      techniqueEffect: ArenaAbilityEffect.shield,
    ),
    'saber_cub': ArenaAbilityLoadout(
      quickName: 'Saber Nip',
      techniqueName: 'Primal Prowl',
      signatureName: 'Ice Age Ambush',
    ),
    'stone_golem': ArenaAbilityLoadout(
      quickName: 'Pebble Punch',
      techniqueName: 'Granite Guard',
      signatureName: 'Mountain Collapse',
      techniqueEffect: ArenaAbilityEffect.shield,
    ),
    'royal_chicken': ArenaAbilityLoadout(
      quickName: 'Regal Scratch',
      techniqueName: 'Crown Command',
      signatureName: 'Royal Roost Rush',
      techniqueEffect: ArenaAbilityEffect.heal,
    ),
    'crown_fox': ArenaAbilityLoadout(
      quickName: 'Scepter Bite',
      techniqueName: 'Royal Ruse',
      signatureName: 'Thronefire Pounce',
      techniqueEffect: ArenaAbilityEffect.drain,
    ),
    'gem_dragon': ArenaAbilityLoadout(
      quickName: 'Crystal Claw',
      techniqueName: 'Jewel Barrier',
      signatureName: 'Diamond Inferno',
      techniqueEffect: ArenaAbilityEffect.shield,
    ),
    'cloud_bunny': ArenaAbilityLoadout(
      quickName: 'Cloud Kick',
      techniqueName: 'Mist Mend',
      signatureName: 'Skyhop Cyclone',
      techniqueEffect: ArenaAbilityEffect.heal,
    ),
    'sun_lion': ArenaAbilityLoadout(
      quickName: 'Solar Claw',
      techniqueName: 'Radiant Roar',
      signatureName: 'Sunburst Maul',
    ),
    'cosmic_phoenix': ArenaAbilityLoadout(
      quickName: 'Star Peck',
      techniqueName: 'Cosmic Rebirth',
      signatureName: 'Supernova Wings',
      techniqueEffect: ArenaAbilityEffect.heal,
    ),
    'void_mouse': ArenaAbilityLoadout(
      quickName: 'Void Nibble',
      techniqueName: 'Energy Vanish',
      signatureName: 'Black-Hole Scurry',
      techniqueEffect: ArenaAbilityEffect.drain,
    ),
    'eclipse_wolf': ArenaAbilityLoadout(
      quickName: 'Dusk Fang',
      techniqueName: 'Eclipse Howl',
      signatureName: 'Totality Hunt',
      techniqueEffect: ArenaAbilityEffect.drain,
    ),
    'nebula_hydra': ArenaAbilityLoadout(
      quickName: 'Triple Snap',
      techniqueName: 'Nebula Renewal',
      signatureName: 'Hydra Starfall',
      techniqueEffect: ArenaAbilityEffect.heal,
    ),
    'crossword_beast': ArenaAbilityLoadout(
      quickName: 'Clue Crunch',
      techniqueName: 'Grid Guard',
      signatureName: 'Puzzlequake',
      techniqueEffect: ArenaAbilityEffect.shield,
    ),
    'boba_bazooka': ArenaAbilityLoadout(
      quickName: 'Pearl Pop',
      techniqueName: 'Tea Tap',
      signatureName: 'Boba Blastoff',
      techniqueEffect: ArenaAbilityEffect.drain,
    ),
    'the_hatched_egg': ArenaAbilityLoadout(
      quickName: 'Rule Crack',
      techniqueName: 'Shell Rewrite',
      signatureName: 'Gamebreaker Hatch',
      techniqueEffect: ArenaAbilityEffect.heal,
    ),
    'slime_pet': ArenaAbilityLoadout(
      quickName: 'Slime Splash',
      techniqueName: 'Gelatin Guard',
      signatureName: 'Ooze Overload',
      techniqueEffect: ArenaAbilityEffect.shield,
    ),
    'egg_golem_pet': ArenaAbilityLoadout(
      quickName: 'Shell Fist',
      techniqueName: 'Yolkstone Wall',
      signatureName: 'Hatchquake',
      techniqueEffect: ArenaAbilityEffect.shield,
    ),
    'night_rooster': ArenaAbilityLoadout(
      quickName: 'Midnight Spur',
      techniqueName: 'Dread Crow',
      signatureName: 'Nightfall Talons',
      techniqueEffect: ArenaAbilityEffect.drain,
    ),
    'slime_king': ArenaAbilityLoadout(
      quickName: 'Royal Slap',
      techniqueName: 'Crown Gel',
      signatureName: 'Kingdom of Ooze',
      techniqueEffect: ArenaAbilityEffect.heal,
    ),
    'egg_guardian': ArenaAbilityLoadout(
      quickName: 'Guardian Jab',
      techniqueName: 'Ancient Shell',
      signatureName: 'Sanctuary Shatter',
      techniqueEffect: ArenaAbilityEffect.shield,
    ),
    'shadow_phoenix': ArenaAbilityLoadout(
      quickName: 'Umbral Peck',
      techniqueName: 'Ashen Rebirth',
      signatureName: 'Shadowfire Eclipse',
      techniqueEffect: ArenaAbilityEffect.heal,
    ),
  };
}
