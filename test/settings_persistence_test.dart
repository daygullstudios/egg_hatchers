import 'dart:async';

import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/main.dart';
import 'package:egg_hatchers/models/background_theme.dart';
import 'package:egg_hatchers/models/online_lobby.dart';
import 'package:egg_hatchers/screens/main_game_shell.dart';
import 'package:egg_hatchers/services/account_protection_service.dart';
import 'package:egg_hatchers/services/account_service.dart';
import 'package:egg_hatchers/services/audio_service.dart';
import 'package:egg_hatchers/services/custom_sprite_service.dart';
import 'package:egg_hatchers/services/device_settings_store.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/online_lobby_service.dart';
import 'package:egg_hatchers/services/preferences_service.dart';
import 'package:egg_hatchers/services/save_import_storage.dart';
import 'package:egg_hatchers/services/save_service.dart';
import 'package:egg_hatchers/services/save_transfer_service.dart';
import 'package:egg_hatchers/widgets/save_import_review_dialog.dart';
import 'package:egg_hatchers/widgets/save_import_scope.dart';
import 'package:egg_hatchers/widgets/settings_save_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/save_import_fixture.dart';

const _key = DeviceSettingsStore.musicEnabledKey;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final mode in _Failure.values.where((m) => m != _Failure.none)) {
    test('settings retain and retry $mode without claiming success', () async {
      final storage = _Storage()..mode = mode;
      final store = DeviceSettingsStore(storage: storage);
      addTearDown(store.dispose);
      expect(await store.writeMusicEnabled(false), false);
      expect(store.needsAttention, true);
      expect(store.isSaving, false);
      expect(store.unsavedLabels, ['Music']);
      final mutations = storage.mutations;
      storage.mode = _Failure.none;
      storage.failReads = false;
      await store.retry();
      expect(store.hasUnsavedChanges, false);
      expect((await store.read()).musicEnabled, false);
      expect(
        storage.mutations,
        mutations +
            ([
                  _Failure.applyReject,
                  _Failure.applyThrow,
                  _Failure.readAfter,
                ].contains(mode)
                ? 0
                : 1),
      );
      expect(storage.values['other-player'], 'keep');
    });
  }

  test(
    'fresh reads distinguish saved values from session-only choices',
    () async {
      final storage = _Storage()..mode = _Failure.reject;
      final store = DeviceSettingsStore(storage: storage);
      final preferences = PreferencesService(store: store);
      await preferences.initialize();
      expect(await preferences.setHapticsEnabled(false), false);
      expect(preferences.hapticsEnabled, false);
      expect((await store.read()).hapticsEnabled, true);
      expect((await store.read(includePending: true)).hapticsEnabled, false);
      await preferences.initialize();
      expect(preferences.hapticsEnabled, false);
      storage.mode = _Failure.none;
      // Choosing the same value again must not short circuit a failed save.
      expect(await preferences.setHapticsEnabled(false), true);
      expect((await store.read()).hapticsEnabled, false);
      expect(store.hasUnsavedChanges, false);
      preferences.dispose();
      store.dispose();
    },
  );

  testWidgets(
    'runtime read cannot roll back a choice confirmed during its backend read',
    (tester) async {
      final gate = Completer<void>();
      final storage = _Storage()..readGate = gate;
      final store = DeviceSettingsStore(storage: storage);
      final read = store.read(includePending: true);
      await tester.pump();
      expect(await store.writeHapticsEnabled(false), true);
      gate.complete();
      await tester.pump();
      expect((await read).hapticsEnabled, false);
      store.dispose();
    },
  );

  test(
    'read outages do not mutate storage or manufacture saved defaults',
    () async {
      final storage = _Storage()..failReads = true;
      final store = DeviceSettingsStore(storage: storage);
      expect(await store.writeMusicEnabled(false), false);
      expect(storage.mutations, 0);
      await expectLater(store.read(), throwsStateError);
      expect(store.hasUnsavedChanges, true);
      storage.failReads = false;
      await store.retry();
      expect(storage.values[_key], false);
      store.dispose();
    },
  );

  test(
    'all ten settings have checked writes and human-readable retry labels',
    () async {
      final storage = _Storage()..mode = _Failure.reject;
      final store = DeviceSettingsStore(storage: storage);
      final results = await Future.wait([
        store.writeBackgroundTheme('night'),
        store.writeAnimalSpriteTheme('retro'),
        store.writeShowBattleBackgrounds(false),
        store.writeReducedBattleEffects(true),
        store.writeHapticsEnabled(false),
        store.writeShowCustomSprites(false),
        store.writeMusicEnabled(false),
        store.writeSfxEnabled(false),
        store.writeMusicVolume(.2),
        store.writeSfxVolume(.3),
      ]);
      expect(results, everyElement(false));
      expect(store.unsavedLabels.length, 10);
      storage.mode = _Failure.none;
      await store.retry();
      expect(store.unsavedLabels, isEmpty);
      expect(storage.values.length, 11);
      store.dispose();
    },
  );

  for (final mode in [
    _Failure.reject,
    _Failure.throwBefore,
    _Failure.applyReject,
    _Failure.lie,
  ]) {
    test('partial settings reset tracks failed removals: $mode', () async {
      final storage = _Storage()
        ..values[DeviceSettingsStore.backgroundThemeKey] = 'night'
        ..failKey = DeviceSettingsStore.backgroundThemeKey
        ..mode = mode;
      final store = DeviceSettingsStore(storage: storage);
      expect(await store.resetToDefaults(), false);
      expect(store.unsavedLabels, ['Background']);
      final mutations = storage.mutations;
      storage.mode = _Failure.none;
      await store.retry();
      expect((await store.read()).backgroundThemeId, null);
      expect(
        storage.mutations,
        mutations + (mode == _Failure.applyReject ? 0 : 1),
      );
      expect(storage.values['other-player'], 'keep');
      store.dispose();
    });
  }

  testWidgets(
    'rapid settings changes serialize and skip superseded intentions',
    (tester) async {
      final storage = _Storage()..gate = Completer<void>();
      final store = DeviceSettingsStore(storage: storage);
      final first = store.writeMusicEnabled(false);
      await tester.pump();
      final middle = store.writeMusicEnabled(false);
      final latest = store.writeMusicEnabled(true);
      await tester.pump();
      expect(storage.mutations, 1);
      storage.gate!.complete();
      await tester.pump();
      expect(await first, false);
      expect(await middle, false);
      expect(await latest, true);
      expect(storage.mutations, 2);
      expect(storage.maxInFlight, 1);
      expect(storage.values[_key], true);
      store.dispose();
    },
  );

  testWidgets('same-key writes across store instances do not overlap', (
    tester,
  ) async {
    final storage = _Storage()..gate = Completer<void>();
    final firstStore = DeviceSettingsStore(storage: storage);
    final secondStore = DeviceSettingsStore(storage: storage);
    final first = firstStore.writeMusicEnabled(false);
    await tester.pump();
    final second = secondStore.writeMusicEnabled(true);
    await tester.pump();
    expect(storage.mutations, 1);
    storage.gate!.complete();
    await tester.pump();
    expect(await first, true);
    expect(await second, true);
    expect(storage.maxInFlight, 1);
    expect(storage.values[_key], true);
    firstStore.dispose();
    secondStore.dispose();
  });

  testWidgets(
    'slow writes show guidance without retry overlap or blocking mute',
    (tester) async {
      final calls = <String>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      for (final name in [
        'xyz.luan/audioplayers.global',
        'xyz.luan/audioplayers.global/events',
      ]) {
        messenger.setMockMethodCallHandler(
          MethodChannel(name),
          (_) async => null,
        );
      }
      messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers'),
        (call) async {
          calls.add(call.method);
          if (call.method == 'create') {
            final id = (call.arguments as Map)['playerId'];
            messenger.setMockMethodCallHandler(
              MethodChannel('xyz.luan/audioplayers/events/$id'),
              (_) async => null,
            );
          }
          return null;
        },
      );
      final storage = _Storage()..gate = Completer<void>();
      final store = DeviceSettingsStore(storage: storage);
      final audio = AudioService(settingsStore: store);
      final pending = audio.setMusicEnabled(false);
      await tester.pump();
      expect(audio.musicEnabled, false);
      expect(calls, contains('stop'));
      await tester.pump(const Duration(seconds: 9));
      expect(store.needsAttention, true);
      expect(store.isSaving, true);
      await store.retry();
      expect(storage.mutations, 1);
      expect(await audio.setSfxEnabled(false), true);
      expect(audio.sfxEnabled, false);
      expect(store.isSaving, true);
      storage.gate!.complete();
      await tester.pump();
      expect(await pending, true);
      expect(store.needsAttention, false);
      audio.dispose();
      store.dispose();
    },
  );

  testWidgets('disposing stops queued writes and late notifications', (
    tester,
  ) async {
    final storage = _Storage()..gate = Completer<void>();
    final store = DeviceSettingsStore(storage: storage);
    final first = store.writeMusicEnabled(false);
    await tester.pump();
    final queued = store.writeMusicEnabled(true);
    store.dispose();
    storage.gate!.complete();
    await tester.pump();
    expect(await first, false);
    expect(await queued, false);
    expect(storage.mutations, 1);
    expect(tester.takeException(), null);
  });

  test('unsaved custom visibility survives switching players', () async {
    final storage = _Storage()..mode = _Failure.reject;
    final store = DeviceSettingsStore(storage: storage);
    final sprites = CustomSpriteService(settingsStore: store);
    await sprites.initialize(accountId: 'mock-a');
    expect(await sprites.setShowCustomSprites(false), false);
    await sprites.initialize(accountId: 'mock-b');
    expect(sprites.showCustomSprites, false);
    expect(store.unsavedLabels, ['Custom animal visibility']);
    storage.mode = _Failure.none;
    await store.retry();
    expect((await store.read()).showCustomSprites, false);
    sprites.dispose();
    store.dispose();
  });

  test(
    'failed theme selection does not report success and keeps its preview',
    () async {
      final storage = _Storage()..mode = _Failure.reject;
      final store = DeviceSettingsStore(storage: storage);
      final preferences = PreferencesService(store: store);
      final theme = BackgroundThemes.all.last;
      expect(await preferences.setBackgroundTheme(theme), false);
      expect(preferences.selectedTheme, theme);
      expect(store.needsAttention, true);
      preferences.dispose();
      store.dispose();
    },
  );

  for (final size in [
    const Size(320, 360),
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    testWidgets(
      'settings recovery stays reachable across routes at $size and 200% text',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final storage = _Storage()..mode = _Failure.reject;
        final store = DeviceSettingsStore(storage: storage);
        final navigator = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: Center(
                child: SizedBox(
                  width: 440,
                  child: SettingsSaveHost(
                    store: store,
                    navigatorKey: navigator,
                    child: child!,
                  ),
                ),
              ),
            ),
            home: const Scaffold(body: Text('Hatchery')),
          ),
        );
        await store.writeMusicEnabled(false);
        await store.writeBackgroundTheme('night');
        await tester.pumpAndSettle();
        unawaited(
          navigator.currentState!.push(
            MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Collection')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('settings-save-attention')));
        await tester.pumpAndSettle();
        expect(find.text('Settings not yet saved'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('settings-save-close')));
        await tester.pumpAndSettle();
        expect(find.text('Collection'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('settings-save-attention')));
        await tester.pumpAndSettle();
        storage.mode = _Failure.none;
        await tester.tap(find.byKey(const ValueKey('settings-save-retry')));
        await tester.pumpAndSettle();
        expect(find.text('Settings saved'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('settings-save-close')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('settings-save-attention')),
          findsNothing,
        );
        expect(tester.takeException(), null);
        await tester.pumpWidget(const SizedBox());
        store.dispose();
      },
    );
  }

  testWidgets(
    'import preflight rejection permits cancellation without forcing a lossy restart',
    (tester) async {
      var restarted = false;
      await tester.pumpWidget(
        MaterialApp(
          home: SaveImportReviewDialog(
            preview: SaveTransferService().inspectSave(importFixture()),
            stageImport: (_) async => throw const SaveImportNotStartedException(
              'Finish saving settings first.',
            ),
            restart: () => restarted = true,
          ),
        ),
      );
      final confirm = find.byKey(
        const ValueKey('settings-confirm-import-save'),
      );
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(restarted, false);
      expect(find.text('Finish saving settings first.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Restart game'), findsNothing);
    },
  );

  testWidgets(
    'root keeps gameplay and player intact and refuses import before pausing writers',
    (tester) async {
      final accounts = AccountService();
      await accounts.initialize();
      final id = accounts.account!.id;
      await SaveService(accountId: id).save(
        GameData.startingPlayerState().copyWith(
          coins: 2345,
          tutorialCompleted: true,
          tutorialVersionCompleted: 999,
        ),
      );
      final game = GameService();
      final storage = _Storage();
      final store = DeviceSettingsStore(storage: storage);
      await tester.pumpWidget(
        NestariumApp(
          accounts: accounts,
          game: game,
          deviceSettings: store,
          accountProtection: AccountProtectionService(),
          onlineLobby: _OfflineLobby(),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.byType(MainGameShell), findsOneWidget);
      storage.mode = _Failure.reject;
      expect(await store.writeHapticsEnabled(false), false);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('settings-save-attention')),
        findsOneWidget,
      );
      final context = tester.element(find.byType(MainGameShell));
      await expectLater(
        SaveImportScope.maybeOf(
          context,
        )!.stageImport(SaveTransferService().inspectSave(importFixture())),
        throwsA(isA<SaveImportNotStartedException>()),
      );
      expect(game.saveNeedsAttention, false);
      expect(accounts.account!.id, id);
      storage.mode = _Failure.none;
      await store.retry();
      await game.save();
      expect((await SaveService(accountId: id).load())!.coins, 2345);
      await game.suspendProgressWrites();
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), null);
    },
  );
}

class _OfflineLobby extends OnlineLobbyService {
  @override
  void updatePresence(OnlinePresenceSnapshot presence) {}
}

enum _Failure {
  none,
  reject,
  throwBefore,
  applyReject,
  applyThrow,
  lie,
  readAfter,
}

class _Storage implements SaveImportStorage {
  final values = <String, Object>{'other-player': 'keep'};
  _Failure mode = _Failure.none;
  String? failKey;
  bool failReads = false;
  Completer<void>? gate;
  Completer<void>? readGate;
  int mutations = 0, inFlight = 0, maxInFlight = 0;
  @override
  Future<Map<String, Object>> readAll() async {
    if (failReads) throw StateError('private backend detail');
    final snapshot = Map.of(values);
    final pendingRead = readGate;
    readGate = null;
    await pendingRead?.future;
    return snapshot;
  }

  Future<bool> _change(String key, Object? value) async {
    mutations++;
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    try {
      if (key == _key) await gate?.future;
      final failure = failKey == null || failKey == key ? mode : _Failure.none;
      if (failure == _Failure.throwBefore) {
        throw StateError('private backend detail');
      }
      if (failure == _Failure.reject) return false;
      if (failure != _Failure.lie) {
        if (value == null) {
          values.remove(key);
        } else {
          values[key] = value;
        }
      }
      if (failure == _Failure.applyThrow) {
        throw StateError('private backend detail');
      }
      if (failure == _Failure.readAfter) failReads = true;
      return failure != _Failure.applyReject;
    } finally {
      inFlight--;
    }
  }

  @override
  Future<bool> write(String key, Object value) => _change(key, value);
  @override
  Future<bool> remove(String key) => _change(key, null);
}
