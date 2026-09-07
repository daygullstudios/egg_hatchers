import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/models/custom_egg.dart';
import 'package:egg_hatchers/models/custom_sprite_data.dart';
import 'package:egg_hatchers/screens/custom_egg_editor_screen.dart';
import 'package:egg_hatchers/screens/sprite_editor_screen.dart';
import 'package:egg_hatchers/services/custom_content_store.dart';
import 'package:egg_hatchers/services/custom_egg_service.dart';
import 'package:egg_hatchers/services/custom_sprite_service.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/preferences_service.dart';
import 'package:egg_hatchers/services/save_import_storage.dart';
import 'package:egg_hatchers/services/sprite_rating_service.dart';
import 'package:egg_hatchers/services/sprite_reference_overlay_service.dart';
import 'package:egg_hatchers/services/unsaved_exit_guard.dart';
import 'package:egg_hatchers/widgets/custom_content_action.dart';

const egg = CustomEgg(
  id: 'draft',
  name: 'Draft Egg',
  emoji: '⭐',
  cost: 1000,
  selectedAnimalIds: ['chicken'],
);
final drawing = CustomSpriteData.empty().setPixel(0, 0, 0xFFAA0033);
final contentError = isA<CustomContentException>();

enum Failure {
  none,
  reject,
  throwBefore,
  applyReject,
  applyThrow,
  lie,
  readAfter,
}

class Storage implements SaveImportStorage {
  final values = <String, Object>{'unrelated': 'keep'};
  Failure failure = Failure.none;
  String? failKey;
  bool failReads = false;
  Completer<void>? gate;
  int mutations = 0;
  final touched = <String>[];
  @override
  Future<Map<String, Object>> readAll() async {
    if (failReads) throw StateError('disposable read failure');
    return Map.of(values);
  }

  Future<bool> change(String key, Object? value) async {
    mutations++;
    touched.add(key);
    await gate?.future;
    final mode = failKey == null || failKey == key ? failure : Failure.none;
    if (mode == Failure.reject) return false;
    if (mode == Failure.throwBefore) {
      throw StateError('disposable write failure');
    }
    if (mode != Failure.lie) {
      if (value == null) {
        values.remove(key);
      } else {
        values[key] = value;
      }
    }
    if (mode == Failure.applyThrow) {
      throw StateError('disposable uncertain failure');
    }
    if (mode == Failure.readAfter) failReads = true;
    return mode != Failure.applyReject;
  }

  @override
  Future<bool> write(String key, Object value) => change(key, value);
  @override
  Future<bool> remove(String key) => change(key, null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final failure in Failure.values.where((f) => f != Failure.none)) {
    test(
      'egg and sprite saves verify $failure and retry without duplicate uncertain writes',
      () async {
        for (final sprite in [false, true]) {
          final storage = Storage();
          final eggs = CustomEggService(storage: storage);
          final sprites = CustomSpriteService(storage: storage);
          await eggs.initialize();
          await sprites.initialize();
          storage.failure = failure;
          Future<void> save() => sprite
              ? sprites.saveSprite('chicken', drawing)
              : eggs.saveEgg(egg);
          await expectLater(save(), throwsA(contentError));
          expect(eggs.allEggs, isEmpty);
          expect(sprites.hasCustomSprite('chicken'), false);
          final mutations = storage.mutations;
          storage
            ..failure = Failure.none
            ..failReads = false;
          await save();
          expect(
            sprite
                ? sprites.hasCustomSprite('chicken')
                : eggs.getById(egg.id) != null,
            true,
          );
          expect(
            storage.mutations,
            mutations +
                ([
                      Failure.applyReject,
                      Failure.applyThrow,
                      Failure.readAfter,
                    ].contains(failure)
                    ? 0
                    : 1),
          );
          expect(storage.values['unrelated'], 'keep');
          eggs.dispose();
          sprites.dispose();
        }
      },
    );
    test(
      'egg delete and sprite reset verify $failure before removing the visible copy',
      () async {
        final storage = Storage();
        final eggs = CustomEggService(storage: storage);
        final sprites = CustomSpriteService(storage: storage);
        await eggs.initialize();
        await sprites.initialize();
        await eggs.saveEgg(egg);
        await sprites.saveSprite('chicken', drawing);
        storage.failure = failure;
        await expectLater(eggs.deleteEgg(egg.id), throwsA(contentError));
        expect(eggs.allEggs.length, 1);
        storage.failReads = false;
        await expectLater(
          sprites.resetSprite('chicken'),
          throwsA(contentError),
        );
        expect(sprites.hasCustomSprite('chicken'), true);
        storage
          ..failure = Failure.none
          ..failReads = false;
        await eggs.deleteEgg(egg.id);
        await sprites.resetSprite('chicken');
        expect(eggs.allEggs, isEmpty);
        expect(sprites.hasCustomSprite('chicken'), false);
        eggs.dispose();
        sprites.dispose();
      },
    );
  }

  test(
    'unknown egg fields and malformed entries survive unrelated edits',
    () async {
      final storage = Storage();
      storage.values['customEggs'] = jsonEncode([
        {
          ...egg.toJson(),
          'futureField': {'keep': true},
        },
        {'unknown': 'keep'},
        42,
      ]);
      final eggs = CustomEggService(storage: storage);
      await eggs.initialize();
      await eggs.saveEgg(egg.copyWith(name: 'Changed'));
      final raw = jsonDecode(storage.values['customEggs'] as String) as List;
      expect(raw.first['futureField'], {'keep': true});
      expect(raw.skip(1), [
        {'unknown': 'keep'},
        42,
      ]);
      eggs.dispose();
    },
  );

  test('corrupt whole egg storage is not replaced', () async {
    final storage = Storage()..values['customEggs'] = '{not readable';
    final eggs = CustomEggService(storage: storage);
    await eggs.initialize();
    await expectLater(eggs.saveEgg(egg), throwsA(contentError));
    expect(storage.mutations, 0);
    expect(storage.values['customEggs'], '{not readable');
    eggs.dispose();
  });

  test('fresh read outages do not mutate custom records', () async {
    final storage = Storage();
    final eggs = CustomEggService(storage: storage);
    await eggs.initialize();
    storage.failReads = true;
    await expectLater(eggs.saveEgg(egg), throwsA(contentError));
    expect(storage.mutations, 0);
    eggs.dispose();
  });

  test(
    'separate tab baselines reject changed custom eggs and sprites',
    () async {
      final storage = Storage();
      final a = CustomEggService(storage: storage),
          b = CustomEggService(storage: storage);
      final sa = CustomSpriteService(storage: storage),
          sb = CustomSpriteService(storage: storage);
      await a.initialize();
      await b.initialize();
      await sa.initialize();
      await sb.initialize();
      await a.saveEgg(egg);
      await sa.saveSprite('chicken', drawing);
      await expectLater(
        b.saveEgg(egg.copyWith(id: 'second')),
        throwsA(contentError),
      );
      await expectLater(sb.resetSprite('chicken'), throwsA(contentError));
      expect(jsonDecode(storage.values['customEggs'] as String), hasLength(1));
      for (final service in [a, b, sa, sb]) {
        service.dispose();
      }
    },
  );

  test(
    'a later egg edit preserves an applied but unconfirmed prior new egg',
    () async {
      final storage = Storage();
      final eggs = CustomEggService(storage: storage);
      await eggs.initialize();
      storage.failure = Failure.applyReject;
      await expectLater(eggs.saveEgg(egg), throwsA(contentError));
      storage.failure = Failure.none;
      await eggs.saveEgg(egg.copyWith(id: 'second'));
      expect(eggs.allEggs.map((e) => e.id), [egg.id, 'second']);
      eggs.dispose();
    },
  );

  test(
    'bulk reset reports partial success and retries only remaining removals',
    () async {
      final storage = Storage();
      final sprites = CustomSpriteService(storage: storage);
      await sprites.initialize();
      final ids = GameData.animals.take(3).map((a) => a.id).toList();
      for (final id in ids) {
        await sprites.saveSprite(id, drawing);
      }
      storage
        ..failKey = 'customSprite_${ids[1]}'
        ..failure = Failure.reject;
      await expectLater(
        sprites.resetAllCustomSprites(),
        throwsA(
          isA<CustomContentException>().having(
            (e) => e.message,
            'partial results',
            contains('1 custom drawings confirmed removed'),
          ),
        ),
      );
      expect(sprites.hasCustomSprite(ids.first), false);
      expect(sprites.hasCustomSprite(ids[1]), true);
      expect(sprites.hasCustomSprite(ids.last), true);
      final attempts = storage.mutations;
      storage.failure = Failure.none;
      await sprites.resetAllCustomSprites();
      expect(storage.mutations, attempts + 2);
      sprites.dispose();
    },
  );

  testWidgets(
    'slow saves reject overlap and cannot retarget a switched player',
    (tester) async {
      for (final sprite in [false, true]) {
        final storage = Storage();
        final eggs = CustomEggService(storage: storage);
        final sprites = CustomSpriteService(storage: storage);
        await eggs.initialize(accountId: 'a');
        await sprites.initialize(accountId: 'a');
        final token = sprite ? sprites.sessionToken : eggs.sessionToken;
        storage.gate = Completer<void>();
        final pending = sprite
            ? sprites.saveSprite('chicken', drawing, expectedSession: token)
            : eggs.saveEgg(egg, expectedSession: token);
        final failure = expectLater(pending, throwsA(contentError));
        await tester.pump();
        await expectLater(
          sprite ? sprites.resetSprite('chicken') : eggs.deleteEgg(egg.id),
          throwsA(contentError),
        );
        final switching = sprite
            ? sprites.initialize(accountId: 'b')
            : eggs.initialize(accountId: 'b');
        storage.gate!.complete();
        await failure;
        await switching;
        expect(
          sprite ? sprites.hasCustomSprite('chicken') : eggs.allEggs.isNotEmpty,
          false,
        );
        await expectLater(
          sprite
              ? sprites.saveSprite('chicken', drawing, expectedSession: token)
              : eggs.saveEgg(egg, expectedSession: token),
          throwsA(contentError),
        );
        expect(storage.values['customEggs.account.b'], sprite ? null : '[]');
        expect(storage.values['customSprite.account.b.chicken'], isNull);
        eggs.dispose();
        sprites.dispose();
      }
    },
  );

  test(
    'legacy migration failure never marks sprite copying complete',
    () async {
      final storage = Storage()
        ..values['customSprite_chicken'] = drawing.toJsonString()
        ..failure = Failure.reject;
      final sprites = CustomSpriteService(storage: storage);
      await expectLater(
        sprites.initialize(accountId: 'a', migrateLegacyData: true),
        throwsA(contentError),
      );
      expect(storage.values['customSpriteMigrationComplete.account.a'], isNull);
      expect(sprites.isInitialized, false);
      storage.failure = Failure.none;
      await sprites.initialize(accountId: 'a', migrateLegacyData: true);
      expect(sprites.hasCustomSprite('chicken'), true);
      expect(storage.values['customSprite_chicken'], drawing.toJsonString());
      sprites.dispose();
    },
  );

  test(
    'new player empty egg namespace prevents legacy adoption on restart',
    () async {
      final storage = Storage()
        ..values['customEggs'] = CustomEgg.listToJsonString([egg]);
      final eggs = CustomEggService(storage: storage);
      await eggs.initialize(accountId: 'new-player');
      expect(eggs.allEggs, isEmpty);
      await eggs.initialize(accountId: 'new-player', migrateLegacyData: true);
      expect(eggs.allEggs, isEmpty);
      expect(storage.values['customEggs.account.new-player'], '[]');
      expect(storage.values['customEggs'], CustomEgg.listToJsonString([egg]));
      eggs.dispose();
    },
  );

  test(
    'removing custom weights restores defaults and published eggs are snapshots',
    () async {
      final storage = Storage();
      final eggs = CustomEggService(storage: storage);
      await eggs.initialize();
      await eggs.saveEgg(egg.copyWith(animalWeights: {'chicken': 9}));
      await eggs.saveEgg(egg);
      expect(eggs.getById(egg.id)!.animalWeights, isEmpty);
      eggs.allEggs.single.selectedAnimalIds.clear();
      expect(eggs.getById(egg.id)!.selectedAnimalIds, ['chicken']);
      eggs.dispose();
    },
  );

  for (final size in [
    const Size(320, 360),
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    testWidgets('recovery and discard controls fit $size at 200 percent text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var attempts = 0;
      final gate = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => MediaQuery(
            data: MediaQueryData(size: size, textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  runCustomContentAction(
                    context,
                    title: 'Saving custom animal',
                    action: () async {
                      attempts++;
                      if (attempts == 1) {
                        await gate.future;
                        throw const CustomContentException(
                          'Saving could not be confirmed. Your draft is still here. Keep it open and retry.',
                        );
                      }
                    },
                  );
                },
                child: const Text('Save'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 9));
      expect(find.textContaining('taking longer'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(attempts, 1);
      gate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Retry'));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(find.byType(AlertDialog), findsNothing);
      expect(hasOpenCustomDrafts, false);
    });
  }

  testWidgets(
    'egg editor keeps typed draft on failure and confirms Back discard',
    (tester) async {
      final storage = Storage();
      final eggs = CustomEggService(storage: storage);
      final sprites = CustomSpriteService();
      final game = GameService();
      final prefs = PreferencesService();
      await Future.wait([
        eggs.initialize(),
        sprites.initialize(),
        game.initialize(),
        prefs.initialize(),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => CustomEggEditorScreen(
                      game: game,
                      preferences: prefs,
                      customEggs: eggs,
                      customSprites: sprites,
                      existing: egg,
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Kept Draft');
      storage.failure = Failure.reject;
      await tester.tap(find.text('Save Custom Egg'));
      await tester.pumpAndSettle();
      expect(find.text('Change not confirmed'), findsOneWidget);
      expect(eggs.allEggs, isEmpty);
      await tester.tap(find.text('Return to screen'));
      await tester.pumpAndSettle();
      expect(find.text('Kept Draft'), findsOneWidget);
      expect(hasOpenCustomDrafts, true);
      expect(game.isQuestNotificationDeferred, true);
      await tester.tap(find.byType(CustomDraftBackButton));
      await tester.pumpAndSettle();
      expect(find.text('Discard unsaved draft?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('Kept Draft'), findsOneWidget);
      storage.failure = Failure.none;
      await tester.tap(find.text('Save Custom Egg'));
      await tester.pumpAndSettle();
      expect(eggs.allEggs.single.name, 'Kept Draft');
      expect(find.text('Open'), findsOneWidget);
      expect(hasOpenCustomDrafts, false);
      expect(game.isQuestNotificationDeferred, false);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        'Discard this draft',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard draft'));
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      expect(eggs.allEggs.single.name, 'Kept Draft');
      expect(hasOpenCustomDrafts, false);
      await tester.pumpWidget(const SizedBox.shrink());
      game.dispose();
      eggs.dispose();
      sprites.dispose();
      prefs.dispose();
    },
  );

  testWidgets(
    'sprite reset failure retains drawing and reset requires confirmation',
    (tester) async {
      final storage = Storage();
      final sprites = CustomSpriteService(storage: storage);
      final game = GameService();
      final prefs = PreferencesService();
      final ratings = SpriteRatingService();
      final references = SpriteReferenceOverlayService();
      await Future.wait([
        sprites.initialize(),
        game.initialize(),
        prefs.initialize(),
        ratings.initialize(),
        references.initialize(),
      ]);
      await sprites.saveSprite('chicken', drawing);
      await tester.pumpWidget(
        MaterialApp(
          home: SpriteEditorScreen(
            animal: GameData.animalById('chicken')!,
            theme: prefs.selectedTheme,
            customSprites: sprites,
            game: game,
            spriteRating: ratings,
            referenceOverlay: references,
          ),
        ),
      );
      final reset = find.widgetWithText(OutlinedButton, 'Reset');
      await tester.ensureVisible(reset);
      await tester.tap(reset);
      await tester.pumpAndSettle();
      expect(find.text('Restore original animal?'), findsOneWidget);
      storage.failure = Failure.reject;
      await tester.tap(find.text('Restore original'));
      await tester.pumpAndSettle();
      expect(find.text('Change not confirmed'), findsOneWidget);
      expect(sprites.getSprite('chicken')!.pixels, drawing.pixels);
      await tester.tap(find.text('Return to screen'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      game.dispose();
      sprites.dispose();
      prefs.dispose();
      ratings.dispose();
      references.dispose();
    },
  );
}
