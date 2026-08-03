import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/data/egg_theme_assets.dart';
import 'package:egg_hatchers/data/realistic_animal_sprites.dart';
import 'package:egg_hatchers/data/realistic_boss_background_assets.dart';
import 'package:egg_hatchers/data/retro_pixel_animal_sprites.dart';
import 'package:egg_hatchers/data/retro_pixel_boss_projectiles.dart';
import 'package:egg_hatchers/data/retro_pixel_boss_sprites.dart';
import 'package:egg_hatchers/data/retro_pixel_hand_authored_sprites.dart';
import 'package:egg_hatchers/data/retro_pixel_native_64_sprites.dart';
import 'package:egg_hatchers/data/sprite_reference_data.dart';
import 'package:egg_hatchers/models/animal_sprite_theme.dart';
import 'package:egg_hatchers/models/retro_pixel_sprite_definition.dart';
import 'package:egg_hatchers/models/retro_pixel_sprite_source.dart';
import 'package:egg_hatchers/utils/boss_visual_config.dart';

bool _isPureUpscale(
  RetroPixelSpriteDefinition small,
  RetroPixelSpriteDefinition large,
  int factor,
) {
  if (large.width != small.width * factor ||
      large.height != small.height * factor) {
    return false;
  }
  for (var y = 0; y < small.height; y++) {
    for (var x = 0; x < small.width; x++) {
      final c = small.pixelAt(x, y);
      for (var dy = 0; dy < factor; dy++) {
        for (var dx = 0; dx < factor; dx++) {
          if (large.pixelAt(x * factor + dx, y * factor + dy) != c) {
            return false;
          }
        }
      }
    }
  }
  return true;
}

void main() {
  test('AnimalSpriteThemes defaults invalid ids to classic', () {
    expect(AnimalSpriteThemes.byId(null).id, 'classic');
    expect(AnimalSpriteThemes.byId('unknown').id, 'classic');
    expect(AnimalSpriteThemes.byId('retroPixel').id, 'retroPixel');
    expect(AnimalSpriteThemes.byId('realistic').id, 'realistic');
  });

  test('Every built-in egg has Classic, Retro Pixel, and Realistic art', () {
    final eggs = [...GameData.eggs, ...GameData.battleEggs];
    final expectedIds = eggs.map((egg) => egg.id).toSet();

    expect(EggThemeAssets.supportedEggIds, expectedIds);

    for (final egg in eggs) {
      expect(egg.spritePath, isNotNull, reason: '${egg.id} Classic path');
      expect(
        File(egg.spritePath!).existsSync(),
        isTrue,
        reason: egg.spritePath,
      );

      for (final theme in [
        AnimalSpriteThemes.retroPixel,
        AnimalSpriteThemes.realistic,
      ]) {
        final path = EggThemeAssets.assetPathFor(
          themeId: theme.id,
          eggId: egg.id,
        );
        expect(path, isNotNull, reason: '${egg.id} ${theme.id} path');
        expect(File(path!).existsSync(), isTrue, reason: path);
      }
    }
  });

  test('Egg theme resolver keeps Classic and custom eggs on fallback art', () {
    expect(
      EggThemeAssets.assetPathFor(themeId: 'classic', eggId: 'basic'),
      isNull,
    );
    expect(
      EggThemeAssets.assetPathFor(themeId: 'realistic', eggId: 'custom_egg'),
      isNull,
    );
  });

  test('Realistic theme includes generated assets for every animal', () {
    final expectedIds = GameData.animals.map((animal) => animal.id).toSet();

    expect(RealisticAnimalSprites.supportedAnimalIds, expectedIds);
    expect(RealisticAnimalSprites.hasSprite('mouse'), isTrue);

    for (final animalId in expectedIds) {
      expect(GameData.animalById(animalId), isNotNull, reason: animalId);
      final assetPath = RealisticAnimalSprites.assetPathFor(animalId);
      expect(assetPath, isNotNull, reason: animalId);
      expect(File(assetPath!).existsSync(), isTrue, reason: assetPath);
    }
  });

  test('Realistic theme includes generated backgrounds for every boss', () {
    const bossIds = {
      'slime_boss',
      'egg_golem',
      'shadow_rooster',
      'night_rooster',
      'night_crow',
      'slime_king',
      'egg_guardian',
      'shadow_phoenix',
      'rotten_shell',
    };

    for (final bossId in bossIds) {
      final assetPath = RealisticBossBackgroundAssets.assetPathForBossId(
        bossId,
      );
      expect(assetPath, isNotNull, reason: bossId);
      expect(File(assetPath!).existsSync(), isTrue, reason: assetPath);
    }

    expect(
      RealisticBossBackgroundAssets.assetPathForBossId('unknown_boss'),
      isNull,
    );
  });

  test('Realistic theme maps boss sprites to current animal art', () {
    const expectedBossIds = {
      'slime_boss',
      'egg_golem',
      'shadow_rooster',
      'night_rooster',
      'night_crow',
      'slime_king',
      'egg_guardian',
      'shadow_phoenix',
      'rotten_shell',
    };

    expect(RealisticAnimalSprites.supportedBossIds, expectedBossIds);
    expect(
      RealisticAnimalSprites.assetPathFor('slime_boss'),
      RealisticAnimalSprites.assetPathFor('slime_pet'),
    );
    expect(
      RealisticAnimalSprites.assetPathFor('egg_golem'),
      RealisticAnimalSprites.assetPathFor('egg_golem_pet'),
    );
    expect(
      RealisticAnimalSprites.assetPathFor('shadow_rooster'),
      RealisticAnimalSprites.assetPathFor('night_rooster'),
    );
    expect(
      RealisticAnimalSprites.assetPathFor('night_crow'),
      RealisticAnimalSprites.assetPathFor('night_rooster'),
    );
    expect(
      RealisticAnimalSprites.assetPathFor('rotten_shell'),
      'assets/images/animal_themes/realistic/rotten_shell.png',
    );

    for (final bossId in expectedBossIds) {
      final assetPath = RealisticAnimalSprites.assetPathFor(bossId);
      expect(assetPath, isNotNull, reason: bossId);
      expect(File(assetPath!).existsSync(), isTrue, reason: assetPath);
    }
  });

  test('Retro Pixel covers every built-in animal', () {
    for (final animal in GameData.animals) {
      expect(
        RetroPixelAnimalSprites.hasSprite(animal.id),
        isTrue,
        reason: 'missing retro pixel sprite for ${animal.id}',
      );
      final sprite = RetroPixelAnimalSprites.spriteFor(animal.id)!;
      expect(sprite.hasVisiblePixels, isTrue);
      expect(sprite.width, greaterThanOrEqualTo(48));
      expect(sprite.height, greaterThanOrEqualTo(48));
      expect(sprite.pixels, contains(0xFF000000));
    }

    expect(
      RetroPixelAnimalSprites.supportedAnimalIds.length,
      GameData.animals.length,
    );
  });

  test('Every built-in animal uses native64 Retro Pixel art', () {
    for (final animal in GameData.animals) {
      final sprite = RetroPixelAnimalSprites.spriteFor(animal.id)!;
      expect(sprite.width, 64, reason: animal.id);
      expect(sprite.height, 64, reason: animal.id);
      expect(
        RetroPixelAnimalSprites.sourceFor(animal.id),
        RetroPixelSpriteSource.native64,
        reason: animal.id,
      );
      expect(
        sprite.pixels,
        RetroPixelNative64Sprites.all[animal.id]!.pixels,
        reason: animal.id,
      );
    }

    expect(
      RetroPixelNative64Sprites.native64Ids.length,
      GameData.animals.length,
    );
  });

  test('Native sprites are not pure upscale of legacy 32x32', () {
    for (final animal in GameData.animals) {
      final legacy = RetroPixelHandAuthoredSprites.all[animal.id];
      if (legacy == null) continue;
      final native = RetroPixelAnimalSprites.spriteFor(animal.id)!;
      expect(
        _isPureUpscale(legacy, native, 2),
        isFalse,
        reason: '${animal.id} should be redrawn, not 2x upscale',
      );
    }
  });

  test('Retro Pixel chicken is native64, not rating reference', () {
    final chicken = RetroPixelAnimalSprites.spriteFor('chicken')!;
    final ratingReference = SpriteReferenceData.referenceFor('chicken')!;

    expect(chicken.width, 64);
    expect(chicken.pixels.length, isNot(ratingReference.pixels.length));
    expect(
      RetroPixelAnimalSprites.sourceFor('chicken'),
      RetroPixelSpriteSource.native64,
    );
  });

  test('Retro Pixel boss projectile art exists for all boss types', () {
    const types = [
      BossProjectileVisualType.slimeGlob,
      BossProjectileVisualType.rockEgg,
      BossProjectileVisualType.shadowFeather,
      BossProjectileVisualType.royalSlime,
      BossProjectileVisualType.guardianShard,
      BossProjectileVisualType.phoenixFlame,
    ];

    for (final type in types) {
      final art = RetroPixelBossProjectiles.forType(type);
      expect(art, isNotNull);
      expect(art!.hasVisiblePixels, isTrue);
      expect(art.width, greaterThanOrEqualTo(20));
    }
  });

  test('Retro Pixel boss sprite art exists for all bosses', () {
    for (final bossId in RetroPixelBossSprites.bossIds) {
      final art = RetroPixelBossSprites.forBossId(bossId);
      expect(art, isNotNull, reason: bossId);
      expect(art!.hasVisiblePixels, isTrue, reason: bossId);
      expect(art.width, 64, reason: bossId);
      expect(art.height, 64, reason: bossId);
      expect(art.pixels, contains(0xFF000000), reason: bossId);
    }

    expect(RetroPixelBossSprites.forBossId('night_rooster'), isNotNull);
    expect(RetroPixelBossSprites.forBossId('night_crow'), isNotNull);
    expect(RetroPixelBossSprites.forBossId('unknown_boss'), isNull);
  });

  test(
    'RetroPixelSpriteDefinition supports per-sprite dimensions and scale',
    () {
      final wide = RetroPixelSpriteDefinition(
        width: 24,
        height: 32,
        pixels: List<int?>.filled(24 * 32, null),
      );
      expect(wide.cellCount, 768);
      expect(wide.scale2x().width, 48);
      expect(wide.scale(4).width, 96);
      expect(wide.scaleToMinDimension(64).width, 96);
      expect(wide.scaleToMinDimension(64).height, 128);
    },
  );

  test('unimplemented ids outside game data return null', () {
    expect(RetroPixelAnimalSprites.hasSprite('not_an_animal'), isFalse);
    expect(RetroPixelAnimalSprites.spriteFor('not_an_animal'), isNull);
  });
}
