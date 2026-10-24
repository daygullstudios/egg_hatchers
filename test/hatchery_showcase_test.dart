import 'dart:convert';

import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/models/player_state.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/save_service.dart';
import 'package:egg_hatchers/services/custom_sprite_service.dart';
import 'package:egg_hatchers/models/background_theme.dart';
import 'package:egg_hatchers/widgets/hatchery_showcase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final basic = GameData.eggs.firstWhere((e) => e.id == 'basic');
  PlayerState collection() => PlayerState.initial().copyWith(
    ownedAnimals: [
      for (final id in basic.possibleAnimalIds)
        OwnedAnimal(animalId: id, quantity: 1),
    ],
    animalMasteryWins: const {'chicken': 10},
  );
  Future<GameService> load(PlayerState state) async {
    SharedPreferences.setMockInitialValues({
      'egg_hatchers_player_state_account_showcase': jsonEncode(state.toJson()),
    });
    final game = GameService(saveService: SaveService(accountId: 'showcase'));
    await game.initialize(accountId: 'showcase');
    addTearDown(game.dispose);
    return game;
  }

  test('legacy saves default safely and cosmetics round trip', () {
    final legacy = PlayerState.initial().toJson()
      ..remove('showcaseAnimalIds')
      ..remove('showcaseDecoration')
      ..remove('collectionBadges')
      ..remove('animalMasteryWins');
    expect(PlayerState.fromJson(legacy).showcaseAnimalIds, isEmpty);
    final state = collection().copyWith(
      showcaseAnimalIds: ['chicken'],
      showcaseDecoration: 'basic',
      collectionBadges: ['basic'],
    );
    final restored = PlayerState.fromJson(
      jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>,
    );
    expect(restored.showcaseAnimalIds, ['chicken']);
    expect(restored.showcaseDecoration, 'basic');
    expect(restored.collectionBadges, ['basic']);
    expect(restored.animalMasteryWins, {'chicken': 10});
  });

  test(
    'collection completion earns a badge; rejects unowned animals and locked decorations',
    () async {
      final game = await load(collection());
      expect(game.completedCollectionEggs.map((e) => e.id), contains('basic'));
      expect(game.state.collectionBadges, contains('basic'));
      expect(game.setHatcheryShowcase(['not-owned'], 'plain'), isFalse);
      expect(game.setHatcheryShowcase(['chicken'], 'daygull'), isFalse);
      expect(game.setHatcheryShowcase(['chicken'], 'basic'), isTrue);
      await game.save();
      final saved = await SaveService(accountId: 'showcase').load();
      expect(saved!.showcaseAnimalIds, ['chicken']);
      await game.initialize(accountId: 'fresh');
      expect(game.state.showcaseAnimalIds, isEmpty);
      expect(game.state.collectionBadges, isEmpty);
      expect(game.state.animalMasteryWins, isEmpty);
    },
  );

  test(
    'earned decorations remain available without owning the collection',
    () async {
      final game = await load(
        PlayerState.initial().copyWith(collectionBadges: ['basic']),
      );
      expect(game.setHatcheryShowcase([], 'basic'), isTrue);
    },
  );

  test(
    'manual victories earn animal mastery; automatic victories do not',
    () async {
      final game = await load(collection());
      game.devCollectAllAnimals();
      final result = game.simulateBossBattle(
        bossId: 'slime_boss',
        animalId: 'nebula_hydra',
        mutationId: 'none',
        isProtected: false,
      )!;
      expect(result.won, isTrue);
      game.applyBossBattleRewards(
        'slime_boss',
        result,
        isManualBattle: false,
        masteryAnimalId: 'nebula_hydra',
      );
      expect(game.state.animalMasteryWins['nebula_hydra'], isNull);
      game.applyBossBattleRewards(
        'slime_boss',
        result,
        masteryAnimalId: 'nebula_hydra',
      );
      expect(game.state.animalMasteryWins['nebula_hydra'], 1);
    },
  );

  testWidgets('showcase and editor fit a narrow phone with large text', (
    tester,
  ) async {
    final game = await load(collection());
    await game.suspendProgressWrites();
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 700),
            textScaler: TextScaler.linear(1.4),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: HatcheryShowcase(
                game: game,
                theme: BackgroundThemes.defaultTheme,
                customSprites: CustomSpriteService(),
                onOpenCollection: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Customize nest'));
    await tester.pumpAndSettle();
    expect(find.text('Save Nest'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
