import 'dart:async';
import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/main.dart';
import 'package:egg_hatchers/models/account_protection_state.dart';
import 'package:egg_hatchers/models/online_lobby.dart';
import 'package:egg_hatchers/screens/main_game_shell.dart';
import 'package:egg_hatchers/services/account_protection_service.dart';
import 'package:egg_hatchers/services/account_service.dart';
import 'package:egg_hatchers/services/cloud_connection_service.dart';
import 'package:egg_hatchers/services/device_guest_slot_store.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/online_lobby_service.dart';
import 'package:egg_hatchers/services/progress_sync_service.dart';
import 'package:egg_hatchers/services/save_service.dart';
import 'package:egg_hatchers/services/save_transfer_service.dart';
import 'package:egg_hatchers/widgets/cloud_connection_scope.dart';
import 'package:egg_hatchers/widgets/save_import_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/save_import_fixture.dart';

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'slow same-identity recheck retains sync context, but a finished failure revokes it',
    (tester) async {
      final accounts = AccountService();
      await accounts.initialize();
      final gateway = _Gateway(), sync = _SyncRecorder();
      final identity = AccountProtectionService(gateway: gateway);
      await tester.pumpWidget(
        NestariumApp(
          accounts: accounts,
          accountProtection: identity,
          onlineLobby: _OfflineLobby(),
          progressSync: sync,
        ),
      );
      gateway.gate.complete(
        const ProtectedPlayerIdentity(playerId: 'same-mock'),
      );
      await _frames(tester);
      expect(sync.identities.last, 'same-mock');
      final before = sync.identities.length;
      final recheck = Completer<ProtectedPlayerIdentity?>();
      gateway.nextResult = recheck.future;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _frames(tester);
      await tester.pump(const Duration(seconds: 9));
      expect(identity.isChecking, true);
      expect(sync.identities.length, before);
      recheck.complete(const ProtectedPlayerIdentity(playerId: 'same-mock'));
      await _frames(tester);
      expect(sync.identities.length, before);
      final failure = Completer<ProtectedPlayerIdentity?>();
      gateway.nextResult = failure.future;
      final retry = identity.retryConnection();
      await _frames(tester);
      failure.completeError(StateError('mock offline failure'));
      await retry;
      await _frames(tester);
      expect(sync.identities.last, isNull);
      expect(find.byType(MainGameShell), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final changed in ['generation', 'selection']) {
    test(
      'identity binding refuses changed $changed at the write boundary',
      () async {
        final slots = DeviceGuestSlotStore();
        final slot = await slots.activate('guest_boundary');
        await expectLater(
          slots.bindFirebaseUid(
            accountId: slot.accountId,
            firebaseUid: 'do-not-bind',
            expectedGeneration: changed == 'generation'
                ? slot.generation + 1
                : slot.generation,
            stillCurrent: () => changed != 'selection',
          ),
          throwsStateError,
        );
        expect((await slots.read())!.firebaseUid, isNull);
      },
    );
  }

  testWidgets(
    'slow storage check explains the wait without a bypass or parallel retry',
    (tester) async {
      final storage = _SlowStorage();
      var clouds = 0, games = 0;
      await tester.pumpWidget(
        SaveImportBootstrap(
          transfer: SaveTransferService(storage: storage),
          acquireLease: ({bool exclusive = false}) async => () async {},
          initializeCloud: () async {
            clouds++;
            return true;
          },
          appBuilder: (_) {
            games++;
            return const SizedBox();
          },
        ),
      );
      await tester.pump(const Duration(seconds: 9));
      expect(
        find.textContaining('local save check is taking longer'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsNothing);
      expect(clouds, 0);
      expect(games, 0);
      expect(storage.reads, 1);
      storage.gate.complete();
      await _frames(tester);
      expect(clouds, 1);
      expect(games, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'slow local player load has scrollable guidance without starting identity',
    (tester) async {
      tester.view.physicalSize = const Size(320, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final accounts = AccountService();
      await accounts.initialize();
      final game = _SlowGame(), gateway = _Gateway();
      final identity = AccountProtectionService(gateway: gateway);
      await tester.pumpWidget(
        NestariumApp(
          accounts: accounts,
          game: game,
          accountProtection: identity,
          onlineLobby: _OfflineLobby(),
        ),
      );
      await _frames(tester);
      await tester.pump(const Duration(seconds: 9));
      expect(
        find.text('Local player is taking longer to load.'),
        findsOneWidget,
      );
      expect(find.byType(MainGameShell), findsNothing);
      expect(gateway.calls, 0);
      expect(tester.takeException(), isNull);
      game.gate.complete();
      await _frames(tester);
      expect(find.byType(MainGameShell), findsOneWidget);
      expect(gateway.calls, 1);
      gateway.gate.complete(null);
      await _frames(tester);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'late SDK success connects identity without reopening or replacing the local player',
    (tester) async {
      final accounts = AccountService();
      await accounts.initialize();
      final id = accounts.account!.id;
      await SaveService(accountId: id).save(
        GameData.startingPlayerState().copyWith(
          coins: 6543,
          tutorialCompleted: true,
          tutorialVersionCompleted: 999,
        ),
      );
      final sdk = Completer<bool>(), gateway = _Gateway(), game = GameService();
      final identity = AccountProtectionService(gateway: gateway);
      await tester.pumpWidget(
        SaveImportBootstrap(
          initializeCloud: () => sdk.future,
          acquireLease: ({bool exclusive = false}) async => () async {},
          appBuilder: (cloud) => NestariumApp(
            accounts: accounts,
            game: game,
            accountProtection: identity,
            onlineLobby: _OfflineLobby(),
            cloudConnection: cloud,
          ),
        ),
      );
      await _frames(tester);
      expect(find.byType(MainGameShell), findsOneWidget);
      expect(gateway.calls, 0);
      sdk.complete(true);
      await _frames(tester);
      expect(gateway.calls, 1);
      gateway.gate.complete(
        const ProtectedPlayerIdentity(playerId: 'late-sdk-identity'),
      );
      await _frames(tester);
      expect(accounts.account!.id, id);
      expect(game.coins, 6543);
      expect(identity.state.protectedPlayerId, 'late-sdk-identity');
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'slow cloud initialization stays single-flight and late success is accepted',
    (tester) async {
      var calls = 0;
      final gate = Completer<bool>();
      final cloud = CloudConnectionService(
        initialize: () {
          calls++;
          return gate.future;
        },
      );
      final first = cloud.connect();
      expect(identical(first, cloud.connect()), true);
      await tester.pump(const Duration(seconds: 9));
      expect(cloud.status, CloudConnectionStatus.slow);
      expect(cloud.isBusy, true);
      cloud.connect();
      expect(calls, 1);
      gate.complete(true);
      await first;
      expect(cloud.isAvailable, true);
      await cloud.connect();
      expect(calls, 1);
      cloud.dispose();
    },
  );
  test(
    'failed cloud initialization can retry without exposing the platform error',
    () async {
      var calls = 0;
      final cloud = CloudConnectionService(
        initialize: () async {
          if (++calls == 1) throw StateError('private-sdk-detail');
          return true;
        },
      );
      await cloud.connect();
      expect(cloud.status, CloudConnectionStatus.unavailable);
      await cloud.connect();
      expect(cloud.isAvailable, true);
      expect(calls, 2);
      cloud.dispose();
    },
  );
  test(
    'false SDK result is unavailable rather than a connected claim',
    () async {
      final cloud = CloudConnectionService(initialize: () async => false);
      await cloud.connect();
      expect(cloud.status, CloudConnectionStatus.unavailable);
      cloud.dispose();
    },
  );
  testWidgets('disposing a slow cloud startup suppresses late notifications', (
    tester,
  ) async {
    final gate = Completer<bool>();
    final cloud = CloudConnectionService(initialize: () => gate.future);
    var notifications = 0;
    cloud.addListener(() => notifications++);
    final work = cloud.connect();
    cloud.dispose();
    final before = notifications;
    await tester.pump(const Duration(seconds: 9));
    gate.complete(true);
    await work;
    expect(notifications, before);
  });
  testWidgets(
    'unreadable bootstrap storage blocks game AND cloud; retry stays read-only',
    (tester) async {
      final storage = _UnavailableStorage({'keep': 'original'});
      var clouds = 0, games = 0;
      await tester.pumpWidget(
        SaveImportBootstrap(
          transfer: SaveTransferService(storage: storage),
          acquireLease: ({bool exclusive = false}) async => () async {},
          initializeCloud: () async {
            clouds++;
            return true;
          },
          appBuilder: (_) {
            games++;
            return const MaterialApp(home: Text('Local game'));
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Startup paused'), findsOneWidget);
      expect(find.textContaining('private-storage-detail'), findsNothing);
      expect(games, 0);
      expect(clouds, 0);
      expect(storage.operations, isEmpty);
      storage.unavailable = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Local game'), findsOneWidget);
      expect(games, 1);
      expect(clouds, 1);
      expect(storage.values, {'keep': 'original'});
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final failCloud in [false, true]) {
    testWidgets(
      'valid local player opens and saves with ${failCloud ? 'failed' : 'hanging'} Firebase startup',
      (tester) async {
        final accounts = AccountService();
        await accounts.initialize();
        final id = accounts.account!.id;
        await SaveService(accountId: id).save(
          GameData.startingPlayerState().copyWith(
            coins: 8765,
            tutorialCompleted: true,
            tutorialVersionCompleted: 999,
          ),
        );
        final gateway = _Gateway();
        final identity = AccountProtectionService(gateway: gateway);
        final game = GameService();
        final gate = Completer<bool>();
        await tester.pumpWidget(
          SaveImportBootstrap(
            initializeCloud: () =>
                failCloud ? Future.error(StateError('offline')) : gate.future,
            acquireLease: ({bool exclusive = false}) async => () async {},
            appBuilder: (cloud) => NestariumApp(
              accounts: accounts,
              game: game,
              accountProtection: identity,
              onlineLobby: _OfflineLobby(),
              cloudConnection: cloud,
            ),
          ),
        );
        await _frames(tester);
        expect(find.byType(MainGameShell), findsOneWidget);
        expect(game.coins, 8765);
        expect(gateway.calls, 0);
        await game.save();
        expect((await SaveService(accountId: id).load())!.coins, 8765);
        await tester.pump(const Duration(seconds: 9));
        expect(find.byType(MainGameShell), findsOneWidget);
        expect(gateway.calls, 0);
        // Disposing before a late SDK success cannot start identity work.
        await tester.pumpWidget(const SizedBox());
        if (!failCloud) gate.complete(true);
        await _frames(tester);
        expect(gateway.calls, 0);
      },
    );
  }
  testWidgets(
    'hanging identity does not block local play; late success binds the same player',
    (tester) async {
      final accounts = AccountService();
      await accounts.initialize();
      final id = accounts.account!.id;
      await SaveService(accountId: id).save(
        GameData.startingPlayerState().copyWith(
          coins: 4321,
          tutorialCompleted: true,
          tutorialVersionCompleted: 999,
        ),
      );
      final gateway = _Gateway(), game = GameService();
      final identity = AccountProtectionService(gateway: gateway);
      await tester.pumpWidget(
        NestariumApp(
          accounts: accounts,
          game: game,
          accountProtection: identity,
          onlineLobby: _OfflineLobby(),
        ),
      );
      await _frames(tester);
      expect(find.byType(MainGameShell), findsOneWidget);
      expect(gateway.calls, 1);
      await tester.pump(const Duration(seconds: 9));
      expect(identity.state.status, AccountProtectionStatus.error);
      expect(identity.isChecking, true);
      expect(find.byType(MainGameShell), findsOneWidget);
      final retry = identity.retryConnection();
      expect(gateway.calls, 1);
      await game.save();
      gateway.gate.complete(
        const ProtectedPlayerIdentity(playerId: 'mock-cloud-identity'),
      );
      await retry;
      await _frames(tester);
      expect(
        (await DeviceGuestSlotStore().read())!.firebaseUid,
        'mock-cloud-identity',
      );
      expect(game.coins, 4321);
      expect(accounts.account!.id, id);
      expect(identity.state.protectedPlayerId, 'mock-cloud-identity');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final action in ['switch', 'generation', 'dispose', 'import']) {
    testWidgets('late identity cannot bind after $action', (tester) async {
      final slots = DeviceGuestSlotStore();
      await slots.activate('guest_mock');
      final gateway = _Gateway();
      final identity = AccountProtectionService(gateway: gateway);
      final pending = identity.initialize(accountId: 'guest_mock');
      await _frames(tester);
      expect(gateway.calls, 1);
      Future<void>? draining;
      if (action == 'switch') {
        await identity.selectAccount(null);
      }
      if (action == 'generation') {
        await slots.invalidateForAccountReplacement(previousGeneration: 1);
        await slots.activate('guest_mock');
      }
      if (action == 'dispose') identity.dispose();
      if (action == 'import') {
        var drained = false;
        draining = identity.pauseForSaveImport().then((_) => drained = true);
        await tester.pump();
        expect(drained, false);
      }
      gateway.gate.complete(
        const ProtectedPlayerIdentity(playerId: 'late-mock'),
      );
      await pending;
      await draining;
      expect((await slots.read())?.firebaseUid, isNull);
      expect(identity.state.protectedPlayerId, isNull);
      expect(gateway.calls, 1);
      if (action != 'dispose') identity.dispose();
    });
  }
  testWidgets(
    'different identity restores serialize while repeated selection coalesces',
    (tester) async {
      final slots = DeviceGuestSlotStore();
      await slots.activate('guest_first');
      final gateway = _Gateway();
      final identity = AccountProtectionService(gateway: gateway);
      final first = identity.selectAccount('guest_first');
      expect(identical(first, identity.selectAccount('guest_first')), true);
      await _frames(tester);
      await slots.activate('guest_second');
      final second = identity.selectAccount('guest_second');
      await _frames(tester);
      expect(gateway.calls, 1);
      gateway.gate.complete(
        const ProtectedPlayerIdentity(playerId: 'first-mock'),
      );
      await first;
      await second;
      expect(gateway.calls, 2);
      expect((await slots.read())!.accountId, 'guest_second');
      expect((await slots.read())!.firebaseUid, 'second-mock');
      expect(identity.state.protectedPlayerId, 'second-mock');
      identity.dispose();
    },
  );
  for (final size in [
    const Size(320, 360),
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    testWidgets('cloud retry notice fits $size at 200% text', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var attempts = 0;
      final cloud = CloudConnectionService(
        initialize: () async {
          attempts++;
          return false;
        },
      );
      await cloud.connect();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: AnimatedBuilder(
                animation: cloud,
                builder: (_, _) => CloudConnectionNotice(
                  connection: cloud,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        DefaultTextStyle.of(
          tester.element(find.text('Cloud unavailable')),
        ).style.color,
        Colors.white,
      );
      await tester.ensureVisible(find.text('Retry cloud connection'));
      await tester.tap(find.text('Retry cloud connection'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      cloud.dispose();
    });
  }
}

class _Gateway implements AccountProtectionGateway {
  final gate = Completer<ProtectedPlayerIdentity?>();
  Future<ProtectedPlayerIdentity?>? nextResult;
  int calls = 0;
  @override
  bool get isConfigured => true;
  @override
  bool get canLinkGoogle => false;
  @override
  Future<ProtectedPlayerIdentity?> restoreIdentity({
    required String accountId,
    required String? expectedPlayerId,
  }) {
    calls++;
    return calls == 1
        ? gate.future
        : nextResult ??
              Future.value(
                const ProtectedPlayerIdentity(playerId: 'second-mock'),
              );
  }

  @override
  Future<ProtectedPlayerIdentity?> linkGoogle({
    required String expectedPlayerId,
  }) async => null;
}

class _SyncRecorder extends ProgressSyncService {
  final identities = <String?>[];
  @override
  Future<void> selectAccount({
    required String? accountId,
    required String? protectedPlayerId,
    CloudProgressRepository? cloud,
    ApplyCloudProgress? applyCloud,
  }) async {
    identities.add(protectedPlayerId);
  }
}

class _UnavailableStorage extends ImportMemoryStorage {
  _UnavailableStorage(super.initial);
  bool unavailable = true;
  @override
  Future<Map<String, Object>> readAll() async {
    if (unavailable) throw StateError('private-storage-detail');
    return super.readAll();
  }
}

class _OfflineLobby extends OnlineLobbyService {
  @override
  void updatePresence(OnlinePresenceSnapshot presence) {}
}

class _SlowStorage extends ImportMemoryStorage {
  final gate = Completer<void>();
  int reads = 0;
  @override
  Future<Map<String, Object>> readAll() async {
    reads++;
    await gate.future;
    return super.readAll();
  }
}

class _SlowGame extends GameService {
  final gate = Completer<void>();
  @override
  Future<void> initialize({
    String? accountId,
    bool migrateLegacySave = false,
  }) async {
    await gate.future;
    await super.initialize(
      accountId: accountId,
      migrateLegacySave: migrateLegacySave,
    );
  }
}
