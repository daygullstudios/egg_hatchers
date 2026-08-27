import '../models/retro_pixel_sprite_definition.dart';
import 'retro_pixel_native_64_canvas.dart';
import 'retro_pixel_palette.dart';

/// Native 64×64 Retro Pixel art for animals beyond the first priority batch.
class RetroPixelNative64Extended {
  RetroPixelNative64Extended._();

  static const _k = RetroPixelPalette.black;
  static const _w = RetroPixelPalette.offWhite;
  static const _g = RetroPixelPalette.lightGray;
  static const _dg = RetroPixelPalette.darkGray;
  static const _pk = RetroPixelPalette.pink;
  static const _r = RetroPixelPalette.red;
  static const _o = RetroPixelPalette.orange;
  static const _y = RetroPixelPalette.yellow;
  static const _e = RetroPixelPalette.green;
  static const _d = RetroPixelPalette.darkGreen;
  static const _l = RetroPixelPalette.blue;
  static const _dl = RetroPixelPalette.darkBlue;
  static const _b = RetroPixelPalette.brown;
  static const _db = RetroPixelPalette.darkBrown;
  static const _tn = RetroPixelPalette.tan;
  static const _s = RetroPixelPalette.slimeGreen;
  static const _sd = RetroPixelPalette.slimeDark;
  static const _pu = RetroPixelPalette.purple;
  static const _cr = RetroPixelPalette.cream;

  static const extendedIds = [
    'bear',
    'tiger',
    'dragon',
    'unicorn',
    'snake',
    'gorilla',
    'dolphin',
    'shark',
    'seal',
    'polar_bear',
    'snow_owl',
    'raptor',
    'triceratops',
    't_rex',
    'fossil_dragon',
    'star_fox',
    'galaxy_dragon',
    'scarab_beetle',
    'saber_cub',
    'stone_golem',
    'royal_chicken',
    'crown_fox',
    'gem_dragon',
    'sun_lion',
    'cosmic_phoenix',
    'void_mouse',
    'eclipse_wolf',
    'nebula_hydra',
    'crossword_beast',
    'boba_bazooka',
    'the_hatched_egg',
    'egg_golem_pet',
    'night_rooster',
    'slime_king',
    'egg_guardian',
    'shadow_phoenix',
  ];

  static final Map<String, RetroPixelSpriteDefinition> all = {
    for (final id in extendedIds) id: _builders[id]!(),
  };

  static final Map<String, RetroPixelSpriteDefinition Function()> _builders = {
    'bear': _bear,
    'tiger': _tiger,
    'dragon': _dragon,
    'unicorn': _unicorn,
    'snake': _snake,
    'gorilla': _gorilla,
    'dolphin': _dolphin,
    'shark': _shark,
    'seal': _seal,
    'polar_bear': _polarBear,
    'snow_owl': _snowOwl,
    'raptor': _raptor,
    'triceratops': _triceratops,
    't_rex': _tRex,
    'fossil_dragon': _fossilDragon,
    'star_fox': _starFox,
    'galaxy_dragon': _galaxyDragon,
    'scarab_beetle': _scarabBeetle,
    'saber_cub': _saberCub,
    'stone_golem': _stoneGolem,
    'royal_chicken': _royalChicken,
    'crown_fox': _crownFox,
    'gem_dragon': _gemDragon,
    'sun_lion': _sunLion,
    'cosmic_phoenix': _cosmicPhoenix,
    'void_mouse': _voidMouse,
    'eclipse_wolf': _eclipseWolf,
    'nebula_hydra': _nebulaHydra,
    'crossword_beast': _crosswordBeast,
    'boba_bazooka': _bobaBazooka,
    'the_hatched_egg': _theHatchedEgg,
    'egg_golem_pet': _eggGolemPet,
    'night_rooster': _nightRooster,
    'slime_king': _slimeKing,
    'egg_guardian': _eggGuardian,
    'shadow_phoenix': _shadowPhoenix,
  };

  static RetroPixelSpriteDefinition _bear() {
    final c = RetroPixelNative64Canvas();
    c.outlineEllipse(32, 20, 8, 8, _b, _k);
    c.eye(28, 18);
    c.eye(36, 18);
    c.set(32, 22, _k);
    c.outlineEllipse(32, 40, 16, 14, _b, _k);
    c.fillEllipse(28, 38, 5, 4, _tn);
    c.fillRect(14, 34, 8, 10, _b);
    c.fillRect(42, 34, 8, 10, _b);
    c.fillRect(22, 52, 6, 8, _b);
    c.fillRect(36, 52, 6, 8, _b);
    c.fillRect(21, 59, 8, 2, _k);
    c.fillRect(35, 59, 8, 2, _k);
    return c.build(displayScale: 1.08);
  }

  static RetroPixelSpriteDefinition _tiger() {
    final c = RetroPixelNative64Canvas();
    c.outlineEllipse(32, 22, 11, 9, _o, _k);
    c.eye(28, 20);
    c.eye(36, 20);
    c.fillRect(30, 26, 4, 2, _k);
    c.outlineEllipse(32, 42, 14, 11, _o, _k);
    for (var i = 0; i < 4; i++) {
      c.fillRect(22 + i * 5, 38 + (i % 2), 3, 2, _k);
    }
    c.fillRect(18, 36, 6, 12, _o);
    c.fillRect(40, 36, 6, 12, _o);
    c.fillRect(22, 54, 5, 8, _o);
    c.fillRect(37, 54, 5, 8, _o);
    c.fillRect(44, 40, 10, 4, _o);
    c.set(43, 40, _k);
    return c.build(displayScale: 1.08);
  }

  static RetroPixelSpriteDefinition _dragon() {
    final c = RetroPixelNative64Canvas();
    c.outlineEllipse(28, 20, 10, 8, _e, _k);
    c.sideEye(32, 18);
    c.fillRect(36, 22, 8, 4, _e);
    c.set(43, 23, _k);
    c.outlineEllipse(32, 40, 15, 12, _e, _k);
    c.fillRect(14, 32, 10, 8, _e);
    c.fillRect(12, 28, 8, 6, _d);
    c.fillRect(46, 36, 12, 8, _e);
    c.fillRect(52, 32, 6, 10, _d);
    c.fillRect(20, 52, 5, 10, _e);
    c.fillRect(38, 52, 5, 10, _e);
    c.fillRect(19, 61, 7, 2, _k);
    c.fillRect(37, 61, 7, 2, _k);
    return c.build(displayScale: 1.06);
  }

  static RetroPixelSpriteDefinition _unicorn() {
    final c = RetroPixelNative64Canvas();
    c.fillRect(30, 4, 4, 10, _y);
    c.fillRect(28, 6, 8, 4, _y);
    c.set(29, 3, _k);
    c.outlineEllipse(30, 22, 10, 8, _w, _k);
    c.sideEye(34, 20);
    c.fillRect(38, 24, 8, 4, _w);
    c.outlineEllipse(32, 42, 13, 10, _w, _k);
    c.fillRect(24, 38, 6, 8, _pk);
    c.fillRect(20, 52, 4, 10, _w);
    c.fillRect(34, 52, 4, 10, _w);
    c.fillRect(40, 52, 4, 10, _w);
    c.fillRect(19, 61, 6, 2, _k);
    c.fillRect(33, 61, 6, 2, _k);
    c.fillRect(39, 61, 6, 2, _k);
    c.fillRect(44, 38, 8, 6, _pk);
    return c.build(displayScale: 1.06);
  }

  static RetroPixelSpriteDefinition _snake() {
    final c = RetroPixelNative64Canvas();
    c.outlineEllipse(20, 18, 8, 7, _e, _k);
    c.sideEye(24, 16);
    c.set(26, 20, _k);
    c.fillRect(24, 24, 8, 6, _e);
    c.fillRect(30, 28, 8, 6, _d);
    c.fillRect(36, 32, 8, 6, _e);
    c.fillRect(40, 38, 8, 6, _d);
    c.fillRect(42, 44, 8, 6, _e);
    c.fillRect(40, 50, 8, 6, _d);
    c.fillRect(34, 54, 8, 5, _e);
    c.fillRect(28, 56, 6, 4, _d);
    return c.build(displayScale: 1.08);
  }

  static RetroPixelSpriteDefinition _gorilla() {
    final c = RetroPixelNative64Canvas();
    c.outlineEllipse(18, 24, 6, 6, _db, _k);
    c.outlineEllipse(46, 24, 6, 6, _db, _k);
    c.outlineEllipse(32, 28, 13, 11, _db, _k);
    c.fillRect(26, 26, 12, 8, _dg);
    c.eye(28, 26);
    c.eye(36, 26);
    c.set(32, 34, _k);
    c.outlineEllipse(32, 46, 14, 10, _db, _k);
    c.fillRect(14, 40, 8, 6, _db);
    c.fillRect(42, 40, 8, 6, _db);
    c.fillRect(22, 54, 6, 8, _db);
    c.fillRect(36, 54, 6, 8, _db);
    return c.build(displayScale: 1.08);
  }

  static RetroPixelSpriteDefinition _dolphin() {
    final c = RetroPixelNative64Canvas();
    c.outlineEllipse(28, 32, 18, 10, _g, _k);
    c.fillRect(44, 28, 10, 8, _g);
    c.fillRect(50, 30, 6, 4, _g);
    c.eye(34, 30);
    c.set(24, 32, _k);
    c.fillRect(14, 30, 6, 5, _l);
    c.fillRect(12, 34, 4, 4, _dl);
    c.fillRect(46, 36, 8, 5, _l);
    return c.build(displayScale: 1.1);
  }

  static RetroPixelSpriteDefinition _shark() {
    final c = RetroPixelNative64Canvas();
    c.outlineEllipse(30, 34, 18, 9, _g, _k);
    c.fillRect(46, 30, 10, 8, _g);
    c.eye(36, 32);
    c.fillRect(34, 36, 6, 4, _w);
    for (var i = 0; i < 3; i++) {
      c.set(28 + i * 2, 38, _k);
    }
    c.fillRect(14, 28, 5, 8, _dg);
    c.fillRect(12, 24, 4, 6, _dg);
    c.fillRect(48, 38, 6, 5, _l);
    return c.build(displayScale: 1.1);
  }

  static RetroPixelSpriteDefinition _seal() {
    final c = RetroPixelNative64Canvas();
    c.outlineEllipse(32, 22, 10, 9, _dg, _k);
    c.eye(28, 20);
    c.eye(36, 20);
    c.set(32, 26, _k);
    c.outlineEllipse(32, 42, 16, 12, _dg, _k);
    c.fillRect(14, 38, 10, 6, _dg);
    c.fillRect(40, 38, 10, 6, _dg);
    c.fillRect(24, 52, 8, 5, _dg);
    c.fillRect(32, 52, 8, 5, _dg);
    for (var x = 24; x <= 39; x++) {
      c.set(x, 51, _k);
    }
    return c.build(displayScale: 1.08);
  }

  static RetroPixelSpriteDefinition _polarBear() {
    final c = RetroPixelNative64Canvas();
    c.outlineEllipse(32, 20, 9, 8, _w, _k);
    c.eye(28, 18);
    c.eye(36, 18);
    c.set(32, 22, _k);
    c.outlineEllipse(32, 40, 16, 13, _w, _k);
    c.fillRect(14, 34, 8, 10, _w);
    c.fillRect(42, 34, 8, 10, _w);
    c.fillRect(22, 52, 6, 8, _w);
    c.fillRect(36, 52, 6, 8, _w);
    c.fillRect(21, 59, 8, 2, _k);
    c.fillRect(35, 59, 8, 2, _k);
    c.fillRect(28, 36, 4, 3, _l);
    return c.build(displayScale: 1.08);
  }

  static RetroPixelSpriteDefinition _snowOwl() {
    final c = RetroPixelNative64Canvas();
    c.outlineEllipse(32, 24, 12, 10, _w, _k);
    c.fillRect(26, 22, 12, 8, _w);
    c.eye(28, 24);
    c.eye(36, 24);
    c.fillRect(30, 30, 4, 3, _o);
    c.fillRect(28, 32, 8, 2, _k);
    c.outlineEllipse(32, 42, 14, 10, _w, _k);
    c.fillRect(18, 38, 8, 6, _w);
    c.fillRect(38, 38, 8, 6, _w);
    c.fillRect(26, 52, 6, 4, _o);
    c.fillRect(32, 52, 6, 4, _o);
    return c.build(displayScale: 1.08);
  }

  static RetroPixelSpriteDefinition _raptor() {
    final c = RetroPixelNative64Canvas();
    c.outlineEllipse(30, 20, 10, 8, _d, _k);
    c.sideEye(34, 18);
    c.fillRect(38, 22, 6, 3, _d);
    for (var i = 0; i < 3; i++) {
      c.set(36 + i, 24, _k);
    }
    c.outlineEllipse(32, 40, 14, 10, _d, _k);
    c.fillRect(18, 36, 6, 4, _d);
    c.fillRect(22, 52, 4, 10, _d);
    c.fillRect(38, 52, 4, 10, _d);
    c.fillRect(44, 38, 12, 4, _d);
    c.set(43, 38, _k);
    return c.build(displayScale: 1.08);
  }

  static RetroPixelSpriteDefinition _triceratops() {
    final c = RetroPixelNative64Canvas();
    c.fillRect(14, 10, 4, 8, _g);
    c.fillRect(28, 8, 8, 10, _g);
    c.fillRect(46, 10, 4, 8, _g);
    for (var x = 14; x <= 49; x++) {
      c.set(x, 9, _k);
    }
    c.outlineEllipse(32, 26, 11, 8, _d, _k);
    c.eye(28, 24);
    c.eye(36, 24);
    c.outlineEllipse(32, 44, 16, 10, _d, _k);
    c.fillRect(20, 52, 6, 8, _d);
    c.fillRect(38, 52, 6, 8, _d);
    c.fillRect(19, 59, 8, 2, _k);
    c.fillRect(37, 59, 8, 2, _k);
    return c.build(displayScale: 1.06);
  }

  static RetroPixelSpriteDefinition _tRex() {
    final c = RetroPixelNative64Canvas();
    c.outlineEllipse(28, 20, 12, 9, _d, _k);
    c.sideEye(32, 18);
    for (var i = 0; i < 4; i++) {
      c.set(36 + i, 22, _k);
    }
    c.outlineEllipse(32, 42, 14, 11, _d, _k);
    c.fillRect(14, 36, 6, 4, _d);
    c.fillRect(18, 52, 5, 10, _d);
    c.fillRect(40, 52, 5, 10, _d);
    c.fillRect(44, 40, 10, 5, _d);
    c.set(43, 40, _k);
    return c.build(displayScale: 1.06);
  }

  static RetroPixelSpriteDefinition _fossilDragon() {
    final c = RetroPixelNative64Canvas();
    c.outlineEllipse(28, 20, 10, 8, _tn, _k);
    c.sideEye(32, 18);
    c.outlineEllipse(32, 40, 15, 12, _tn, _k);
    c.fillRect(14, 32, 10, 8, _tn);
    c.fillRect(46, 36, 12, 8, _b);
    for (var y = 38; y <= 44; y++) {
      c.set(30 + (y % 3), y, _b);
    }
    c.fillRect(20, 52, 5, 10, _tn);
    c.fillRect(38, 52, 5, 10, _tn);
    return c.build(displayScale: 1.06);
  }

  static RetroPixelSpriteDefinition _starFox() {
    final c = RetroPixelNative64Canvas();
    c.fillRect(14, 10, 6, 6, _l);
    c.fillRect(16, 8, 2, 2, _w);
    c.fillRect(44, 10, 6, 6, _l);
    c.fillRect(46, 8, 2, 2, _w);
    c.outlineEllipse(32, 26, 12, 10, _o, _k);
    c.eye(28, 24);
    c.eye(36, 24);
    c.fillRect(28, 30, 8, 6, _w);
    c.outlineEllipse(30, 44, 13, 10, _o, _k);
    c.fillRect(44, 38, 12, 8, _o);
    c.fillRect(50, 36, 6, 6, _w);
    c.fillRect(22, 54, 5, 8, _k);
    c.fillRect(36, 54, 5, 8, _k);
    return c.build(displayScale: 1.08);
  }

  static RetroPixelSpriteDefinition _galaxyDragon() {
    final c = RetroPixelNative64Canvas();
    c.fillRect(10, 12, 3, 3, _w);
    c.fillRect(50, 16, 3, 3, _w);
    c.fillRect(24, 8, 4, 2, _l);
    c.outlineEllipse(28, 22, 10, 8, _pu, _k);
    c.sideEye(32, 20);
    c.outlineEllipse(32, 42, 15, 12, _pu, _k);
    c.fillRect(14, 34, 10, 8, _pu);
    c.fillRect(46, 36, 12, 8, _dl);
    c.fillRect(20, 52, 5, 10, _pu);
    c.fillRect(38, 52, 5, 10, _pu);
    c.fillRect(36, 30, 4, 2, _pk);
    return c.build(displayScale: 1.06);
  }

  static RetroPixelSpriteDefinition _scarabBeetle() {
    final c = RetroPixelNative64Canvas();
    c.outlineEllipse(32, 34, 16, 12, _d, _k);
    c.fillRect(24, 28, 16, 4, _y);
    c.fillRect(26, 24, 12, 4, _y);
    c.eye(28, 20);
    c.eye(36, 20);
    c.fillRect(18, 36, 6, 8, _d);
    c.fillRect(40, 36, 6, 8, _d);
    c.fillRect(22, 48, 4, 6, _d);
    c.fillRect(38, 48, 4, 6, _d);
    c.fillRect(30, 22, 4, 4, _y);
    return c.build(displayScale: 1.08);
  }

  static RetroPixelSpriteDefinition _saberCub() {
    final c = RetroPixelNative64Canvas();
    c.outlineEllipse(32, 22, 10, 9, _o, _k);
    c.eye(28, 20);
    c.eye(36, 20);
    c.fillRect(24, 26, 4, 2, _w);
    c.fillRect(36, 26, 4, 2, _w);
    c.fillRect(18, 24, 6, 3, _g);
    c.fillRect(40, 24, 6, 3, _g);
    c.outlineEllipse(32, 44, 13, 10, _o, _k);
    c.fillRect(22, 54, 5, 8, _o);
    c.fillRect(37, 54, 5, 8, _o);
    c.fillRect(44, 42, 8, 4, _o);
    return c.build(displayScale: 1.08);
  }

  static RetroPixelSpriteDefinition _stoneGolem() {
    final c = RetroPixelNative64Canvas();
    c.rectOutline(22, 14, 20, 16, _g, _k);
    c.eye(28, 20);
    c.eye(36, 20);
    c.fillRect(30, 28, 4, 3, _dg);
    c.rectOutline(20, 32, 24, 18, _g, _k);
    c.fillRect(14, 36, 6, 12, _g);
    c.fillRect(44, 36, 6, 12, _g);
    c.fillRect(24, 50, 6, 10, _g);
    c.fillRect(34, 50, 6, 10, _g);
    for (var x = 23; x <= 40; x++) {
      c.set(x, 49, _k);
    }
    return c.build(displayScale: 1.06);
  }

  static RetroPixelSpriteDefinition _royalChicken() {
    final c = RetroPixelNative64Canvas();
    c.fillRect(24, 4, 16, 4, _y);
    c.fillRect(26, 2, 12, 2, _y);
    c.fillRect(28, 0, 8, 2, _y);
    for (var x = 24; x <= 39; x++) {
      c.set(x, 3, _k);
    }
    c.fillRect(26, 8, 12, 4, _r);
    c.fillRect(28, 6, 8, 2, _r);
    c.outlineEllipse(32, 22, 10, 9, _w, _k);
    c.sideEye(38, 20);
    c.fillRect(42, 22, 6, 4, _o);
    c.fillRect(40, 28, 4, 5, _r);
    c.outlineEllipse(30, 40, 14, 12, _w, _k);
    c.fillRect(24, 50, 4, 6, _o);
    c.fillRect(34, 50, 4, 6, _o);
    c.fillRect(22, 56, 8, 3, _o);
    c.fillRect(32, 56, 8, 3, _o);
    return c.build(displayScale: 1.08);
  }

  static RetroPixelSpriteDefinition _crownFox() {
    final c = RetroPixelNative64Canvas();
    c.fillRect(24, 4, 16, 4, _y);
    c.fillRect(28, 0, 8, 4, _y);
    for (var x = 24; x <= 39; x++) {
      c.set(x, 3, _k);
    }
    c.fillRect(18, 10, 9, 12, _o);
    c.fillRect(37, 10, 9, 12, _o);
    c.outlineEllipse(32, 26, 12, 10, _o, _k);
    c.eye(28, 24);
    c.eye(36, 24);
    c.fillRect(28, 30, 8, 6, _w);
    c.outlineEllipse(30, 44, 13, 10, _o, _k);
    c.fillRect(44, 38, 12, 8, _o);
    c.fillRect(50, 36, 6, 6, _w);
    c.fillRect(22, 54, 5, 8, _k);
    c.fillRect(36, 54, 5, 8, _k);
    return c.build(displayScale: 1.08);
  }

  static RetroPixelSpriteDefinition _gemDragon() {
    final c = RetroPixelNative64Canvas();
    c.outlineEllipse(28, 20, 10, 8, _l, _k);
    c.sideEye(32, 18);
    c.fillRect(36, 22, 8, 4, _l);
    c.outlineEllipse(32, 40, 15, 12, _l, _k);
    c.fillRect(14, 32, 10, 8, _l);
    c.fillRect(24, 34, 4, 4, _pk);
    c.fillRect(36, 38, 4, 4, _e);
    c.fillRect(46, 36, 12, 8, _dl);
    c.fillRect(20, 52, 5, 10, _l);
    c.fillRect(38, 52, 5, 10, _l);
    return c.build(displayScale: 1.06);
  }

  static RetroPixelSpriteDefinition _sunLion() {
    final c = RetroPixelNative64Canvas();
    for (var i = 0; i < 8; i++) {
      c.fillRect(12 + i * 6, 8 + (i % 2) * 2, 4, 6, _y);
    }
    c.outlineEllipse(32, 26, 12, 10, _o, _k);
    c.eye(28, 24);
    c.eye(36, 24);
    c.fillRect(30, 30, 4, 3, _k);
    c.outlineEllipse(32, 44, 14, 10, _o, _k);
    c.fillRect(24, 40, 8, 6, _y);
    c.fillRect(22, 52, 5, 10, _o);
    c.fillRect(37, 52, 5, 10, _o);
    c.fillRect(44, 42, 8, 4, _o);
    return c.build(displayScale: 1.06);
  }

  static RetroPixelSpriteDefinition _cosmicPhoenix() {
    final c = RetroPixelNative64Canvas();
    c.outlineEllipse(28, 20, 9, 8, _r, _k);
    c.sideEye(32, 18);
    c.fillRect(36, 22, 8, 4, _o);
    c.fillRect(22, 30, 16, 10, _r);
    c.fillRect(24, 40, 12, 8, _o);
    c.fillRect(26, 48, 8, 6, _y);
    c.fillRect(38, 34, 4, 8, _r);
    c.fillRect(42, 38, 4, 10, _o);
    c.fillRect(46, 42, 4, 12, _y);
    c.fillRect(14, 36, 8, 6, _r);
    c.fillRect(26, 54, 6, 3, _o);
    c.fillRect(32, 54, 6, 3, _o);
    return c.build(displayScale: 1.06);
  }

  static RetroPixelSpriteDefinition _voidMouse() {
    final c = RetroPixelNative64Canvas();
    c.fillRect(12, 10, 4, 4, _pu);
    c.fillRect(48, 10, 4, 4, _pu);
    c.outlineEllipse(22, 14, 5, 7, _pu, _k);
    c.outlineEllipse(42, 14, 5, 7, _pu, _k);
    c.outlineEllipse(32, 32, 14, 12, _dg, _k);
    c.eye(28, 28, sclera: _l);
    c.eye(36, 28, sclera: _l);
    c.fillRect(14, 36, 10, 3, _k);
    c.fillRect(40, 36, 10, 3, _k);
    c.paw(24, 44, _dg);
    c.paw(36, 44, _dg);
    c.fillRect(46, 36, 10, 3, _k);
    return c.build(displayScale: 1.1);
  }

  static RetroPixelSpriteDefinition _eclipseWolf() {
    final c = RetroPixelNative64Canvas();
    c.fillRect(18, 10, 9, 12, _dg);
    c.fillRect(37, 10, 9, 12, _dg);
    c.outlineEllipse(32, 26, 12, 10, _dg, _k);
    c.eye(28, 24, sclera: _w);
    c.eye(36, 24, sclera: _w);
    c.fillRect(28, 30, 8, 5, _dg);
    c.set(31, 34, _k);
    c.set(33, 34, _k);
    c.outlineEllipse(30, 44, 13, 10, _dg, _k);
    c.fillRect(44, 38, 12, 8, _dg);
    c.fillRect(22, 54, 5, 8, _k);
    c.fillRect(36, 54, 5, 8, _k);
    c.fillRect(48, 40, 4, 4, _w);
    return c.build(displayScale: 1.08);
  }

  static RetroPixelSpriteDefinition _nebulaHydra() {
    final c = RetroPixelNative64Canvas();
    c.outlineEllipse(18, 16, 7, 6, _pu, _k);
    c.eye(16, 14, sclera: _pk);
    c.outlineEllipse(32, 12, 7, 6, _pu, _k);
    c.eye(30, 10, sclera: _pk);
    c.outlineEllipse(46, 16, 7, 6, _pu, _k);
    c.eye(44, 14, sclera: _pk);
    c.fillRect(20, 24, 24, 8, _pu);
    c.fillRect(24, 32, 16, 8, _dl);
    c.fillRect(28, 40, 8, 8, _pu);
    c.fillRect(26, 48, 12, 6, _dl);
    c.fillRect(10, 20, 4, 3, _w);
    c.fillRect(50, 20, 4, 3, _w);
    return c.build(displayScale: 1.06);
  }

  static RetroPixelSpriteDefinition _crosswordBeast() {
    final c = RetroPixelNative64Canvas();
    c.outlineEllipse(32, 24, 13, 10, _dl, _k);
    c.eye(27, 22, sclera: _l);
    c.eye(37, 22, sclera: _l);
    c.fillRect(22, 14, 6, 8, _pu);
    c.fillRect(38, 14, 6, 8, _pu);
    c.outlineEllipse(32, 42, 16, 12, _dl, _k);
    c.fillRect(20, 34, 24, 4, _w);
    c.fillRect(20, 42, 24, 4, _w);
    c.fillRect(28, 30, 4, 20, _w);
    c.fillRect(36, 30, 4, 20, _w);
    for (var x = 20; x <= 43; x += 8) {
      c.fillRect(x, 34, 2, 4, _k);
      c.fillRect(x, 42, 2, 4, _k);
    }
    for (var y = 30; y <= 49; y += 8) {
      c.fillRect(28, y, 4, 2, _k);
      c.fillRect(36, y, 4, 2, _k);
    }
    c.fillRect(18, 48, 8, 8, _pu);
    c.fillRect(38, 48, 8, 8, _pu);
    c.fillRect(16, 56, 12, 3, _k);
    c.fillRect(36, 56, 12, 3, _k);
    return c.build(displayScale: 1.06);
  }

  static RetroPixelSpriteDefinition _bobaBazooka() {
    final c = RetroPixelNative64Canvas();
    c.rectOutline(24, 18, 18, 30, _tn, _k);
    c.fillRect(26, 20, 14, 7, _cr);
    c.fillRect(26, 28, 14, 16, _b);
    for (final point in [(28, 39), (33, 36), (37, 41), (30, 44), (38, 34)]) {
      c.fillEllipse(point.$1, point.$2, 2, 2, _k);
    }
    c.fillRect(30, 8, 4, 12, _l);
    c.fillRect(34, 6, 4, 14, _pu);
    c.fillRect(42, 28, 14, 7, _dl);
    c.fillRect(54, 26, 6, 11, _l);
    c.fillRect(58, 28, 4, 7, _pu);
    c.set(60, 27, _k);
    c.set(60, 35, _k);
    c.eye(28, 24, sclera: _w);
    c.sideEye(36, 24);
    c.fillRect(29, 30, 7, 2, _k);
    c.fillRect(18, 34, 6, 10, _tn);
    c.fillRect(40, 42, 8, 6, _tn);
    c.fillRect(24, 48, 5, 10, _tn);
    c.fillRect(36, 48, 5, 10, _tn);
    c.fillRect(23, 58, 7, 2, _k);
    c.fillRect(35, 58, 7, 2, _k);
    return c.build(displayScale: 1.06);
  }

  static RetroPixelSpriteDefinition _theHatchedEgg() {
    final c = RetroPixelNative64Canvas();
    c.outlineEllipse(32, 36, 18, 21, _cr, _k);
    c.fillRect(18, 22, 6, 5, _w);
    c.fillRect(25, 17, 7, 6, _w);
    c.fillRect(34, 18, 7, 5, _w);
    c.fillRect(42, 23, 5, 5, _w);
    c.fillRect(20, 24, 4, 3, _k);
    c.fillRect(30, 21, 5, 3, _k);
    c.fillRect(40, 25, 5, 3, _k);
    c.outlineEllipse(32, 35, 10, 9, _y, _k);
    c.fillRect(24, 32, 16, 4, _o);
    c.eye(28, 32, sclera: _w);
    c.eye(36, 32, sclera: _w);
    c.fillRect(30, 39, 5, 3, _o);
    c.fillRect(18, 42, 8, 10, _cr);
    c.fillRect(40, 42, 8, 10, _cr);
    c.fillRect(24, 55, 8, 4, _o);
    c.fillRect(34, 55, 8, 4, _o);
    c.fillRect(22, 58, 11, 2, _k);
    c.fillRect(33, 58, 11, 2, _k);
    c.fillRect(12, 28, 8, 2, _pu);
    c.fillRect(44, 16, 9, 2, _l);
    c.fillRect(48, 44, 8, 2, _pu);
    return c.build(displayScale: 1.08);
  }

  static RetroPixelSpriteDefinition _eggGolemPet() {
    final c = RetroPixelNative64Canvas();
    c.rectOutline(22, 12, 20, 14, _g, _k);
    c.fillRect(26, 8, 12, 4, _cr);
    c.eye(28, 18);
    c.eye(36, 18);
    c.rectOutline(20, 30, 24, 16, _g, _k);
    c.fillRect(14, 34, 6, 12, _g);
    c.fillRect(44, 34, 6, 12, _g);
    c.fillRect(24, 48, 6, 10, _g);
    c.fillRect(34, 48, 6, 10, _g);
    c.fillRect(28, 14, 8, 2, _y);
    return c.build(displayScale: 1.06);
  }

  static RetroPixelSpriteDefinition _nightRooster() {
    final c = RetroPixelNative64Canvas();
    c.fillRect(26, 8, 12, 4, _pu);
    c.fillRect(28, 6, 8, 2, _pu);
    c.fillRect(30, 4, 4, 2, _pu);
    for (var x = 26; x <= 37; x++) {
      c.set(x, 7, _k);
    }
    c.outlineEllipse(32, 22, 10, 9, _dg, _k);
    c.sideEye(38, 20);
    c.fillRect(42, 22, 6, 4, _o);
    c.fillRect(40, 28, 4, 5, _pu);
    c.outlineEllipse(30, 40, 14, 12, _dg, _k);
    c.fillRect(24, 50, 4, 6, _o);
    c.fillRect(34, 50, 4, 6, _o);
    c.fillRect(22, 56, 8, 3, _o);
    c.fillRect(32, 56, 8, 3, _o);
    return c.build(displayScale: 1.08);
  }

  static RetroPixelSpriteDefinition _slimeKing() {
    final c = RetroPixelNative64Canvas();
    c.fillRect(22, 4, 20, 4, _y);
    c.fillRect(24, 2, 16, 2, _y);
    c.fillRect(26, 0, 12, 2, _y);
    for (var x = 22; x <= 41; x++) {
      c.set(x, 3, _k);
    }
    c.outlineEllipse(32, 38, 16, 14, _s, _k);
    c.fillRect(22, 26, 6, 4, _w);
    c.eye(26, 34);
    c.eye(38, 34);
    c.fillRect(28, 40, 8, 3, _sd);
    c.fillRect(18, 50, 4, 6, _s);
    c.fillRect(42, 50, 4, 6, _s);
    c.fillRect(24, 8, 4, 4, _y);
    return c.build(displayScale: 1.1);
  }

  static RetroPixelSpriteDefinition _eggGuardian() {
    final c = RetroPixelNative64Canvas();
    c.rectOutline(20, 14, 24, 16, _cr, _k);
    c.fillRect(24, 10, 16, 4, _y);
    c.eye(28, 20, sclera: _l);
    c.eye(36, 20, sclera: _l);
    c.fillRect(30, 26, 4, 3, _y);
    c.rectOutline(18, 32, 28, 18, _cr, _k);
    c.fillRect(12, 36, 6, 12, _cr);
    c.fillRect(46, 36, 6, 12, _cr);
    c.fillRect(24, 50, 6, 10, _cr);
    c.fillRect(34, 50, 6, 10, _cr);
    c.fillRect(26, 8, 4, 4, _l);
    c.fillRect(34, 8, 4, 4, _l);
    return c.build(displayScale: 1.06);
  }

  static RetroPixelSpriteDefinition _shadowPhoenix() {
    final c = RetroPixelNative64Canvas();
    c.outlineEllipse(28, 20, 9, 8, _dl, _k);
    c.sideEye(32, 18);
    c.fillRect(36, 22, 8, 4, _pu);
    c.fillRect(22, 30, 16, 10, _dl);
    c.fillRect(24, 40, 12, 8, _pu);
    c.fillRect(26, 48, 8, 6, _l);
    c.fillRect(38, 34, 4, 8, _dl);
    c.fillRect(42, 38, 4, 10, _pu);
    c.fillRect(46, 42, 4, 12, _l);
    c.fillRect(14, 36, 8, 6, _dl);
    c.fillRect(26, 54, 6, 3, _pu);
    c.fillRect(32, 54, 6, 3, _pu);
    return c.build(displayScale: 1.06);
  }
}
