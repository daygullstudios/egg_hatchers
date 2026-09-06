import 'dart:async';

import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/models/cloud_progress_read.dart';
import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/models/player_state.dart';
import 'package:egg_hatchers/models/quest_progress.dart';
import 'package:egg_hatchers/services/progress_sync_service.dart';
import 'package:egg_hatchers/services/save_service.dart';
import 'package:egg_hatchers/widgets/app_theme_background.dart';
import 'package:egg_hatchers/widgets/progress_conflict_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final scenario in [
    (const Size(320, 568), 1.0),
    (const Size(390, 844), 1.0),
    (const Size(430, 932), 2.0),
    (const Size(320, 360), 2.0),
    (const Size(1400, 900), 2.0),
  ]) {
    testWidgets('comparison and confirmation remain usable at $scenario', (
      tester,
    ) async {
      final fixture = await _open(
        tester,
        size: scenario.$1,
        scale: scenario.$2,
      );
      expect(find.text('Coins: 800'), findsOneWidget);
      expect(find.text('Coins: 1,500'), findsOneWidget);
      expect(find.text('Animals owned: 9'), findsOneWidget);
      expect(find.text('Rebirth level: 2'), findsOneWidget);
      expect(find.text('Eggs hatched: 25'), findsOneWidget);
      expect(find.textContaining('(local time)'), findsNWidgets(2));
      // Each side remains readable by scrolling without moving footer actions.
      final cloudWins = find.descendant(
        of: find.byKey(const ValueKey('save-summary-Cloud copy')),
        matching: find.text('Boss wins: 3'),
      );
      await tester.ensureVisible(cloudWins);
      await tester.pumpAndSettle();
      expect(cloudWins.hitTestable(), findsOneWidget);
      _expectContained(tester, [
        'save-review-later',
        'save-review-device',
        'save-review-cloud',
      ]);
      await tester.tap(find.byKey(const ValueKey('save-review-cloud')));
      await tester.pumpAndSettle();
      expect(find.text('Replace device progress?'), findsOneWidget);
      await tester.ensureVisible(
        find.text('Progress is replaced, not merged.'),
      );
      await tester.pumpAndSettle();
      _expectContained(tester, ['save-review-back', 'save-review-confirm']);
      expect(fixture.cloud.writes, 0);
      expect(fixture.cloud.restores, 0);
      // Enter follows safe autofocus, not the destructive button.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Compare saves'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(ProgressConflictDialog), findsNothing);
      expect((await fixture.local.load())?.coins, 800);
      fixture.sync.dispose();
    });
  }

  for (final keepDevice in [true, false]) {
    testWidgets(
      'only final ${keepDevice ? 'device' : 'cloud'} confirmation replaces progress',
      (tester) async {
        final fixture = await _open(tester);
        await tester.tap(
          find.byKey(
            ValueKey(keepDevice ? 'save-review-device' : 'save-review-cloud'),
          ),
        );
        await tester.pumpAndSettle();
        expect(fixture.cloud.writes, 0);
        expect(fixture.cloud.restores, 0);
        await tester.tap(find.byKey(const ValueKey('save-review-confirm')));
        await tester.pumpAndSettle();
        expect(find.byType(ProgressConflictDialog), findsNothing);
        expect(fixture.cloud.writes, keepDevice ? 1 : 0);
        expect(fixture.cloud.restores, keepDevice ? 0 : 1);
        expect((await fixture.local.load())?.coins, keepDevice ? 800 : 1500);
        fixture.sync.dispose();
      },
    );
  }

  testWidgets('changed cloud shows Retry without overwriting either save', (
    tester,
  ) async {
    final fixture = await _open(tester);
    await tester.tap(find.byKey(const ValueKey('save-review-device')));
    await tester.pumpAndSettle();
    fixture.cloud.snapshot = _snapshot(
      GameData.startingPlayerState().copyWith(coins: 1700),
      5,
    );
    await tester.tap(find.byKey(const ValueKey('save-review-confirm')));
    await tester.pumpAndSettle();
    expect(find.textContaining('cloud save changed'), findsOneWidget);
    expect(find.byKey(const ValueKey('save-review-confirm')), findsNothing);
    expect(fixture.cloud.writes, 0);
    expect(fixture.cloud.restores, 0);
    expect((await fixture.local.load())?.coins, 800);
    await tester.tap(find.byKey(const ValueKey('save-review-retry')));
    await tester.pumpAndSettle();
    expect(find.text('Coins: 1,700'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('save-review-later')));
    await tester.pumpAndSettle();
    fixture.sync.dispose();
  });

  testWidgets('loading can be cancelled without applying the late result', (
    tester,
  ) async {
    final gate = Completer<void>();
    final fixture = await _open(tester, gate: gate);
    expect(find.textContaining('Reading both saves'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('save-review-later')));
    await tester.pumpAndSettle();
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(ProgressConflictDialog), findsNothing);
    expect(fixture.cloud.writes, 0);
    expect(fixture.cloud.restores, 0);
    expect(tester.takeException(), isNull);
    fixture.sync.dispose();
  });
}

void _expectContained(WidgetTester tester, List<String> keys) {
  expect(tester.takeException(), isNull);
  final surface = tester.getRect(find.byKey(PortraitAppShell.surfaceKey));
  final dialog = tester.getRect(find.byType(AlertDialog));
  expect(dialog.left, greaterThanOrEqualTo(surface.left));
  expect(dialog.right, lessThanOrEqualTo(surface.right));
  expect(dialog.top, greaterThanOrEqualTo(surface.top));
  expect(dialog.bottom, lessThanOrEqualTo(surface.bottom));
  for (final key in keys) {
    final button = find.byKey(ValueKey(key));
    expect(button.hitTestable(), findsOneWidget);
    final rect = tester.getRect(button);
    expect(rect.width, greaterThanOrEqualTo(48));
    expect(rect.height, greaterThanOrEqualTo(48));
    expect(rect.bottom, lessThanOrEqualTo(surface.bottom));
  }
}

Future<({ProgressSyncService sync, SaveService local, _Cloud cloud})> _open(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  Completer<void>? gate,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final local = SaveService(accountId: 'test_review');
  await local.save(
    GameData.startingPlayerState().copyWith(
      coins: 800,
      rebirthLevel: 2,
      ownedAnimals: const [
        OwnedAnimal(animalId: 'chicken', quantity: 7),
        OwnedAnimal(animalId: 'mouse', quantity: 2, mutationId: 'golden'),
      ],
      questProgress: const QuestProgress(totalEggsHatched: 25),
    ),
  );
  final cloud = _Cloud();
  final sync = ProgressSyncService();
  await sync.selectAccount(
    accountId: 'test_review',
    protectedPlayerId: 'test_identity',
    cloud: cloud,
    applyCloud: (state) async {
      cloud.restores++;
      await local.save(state);
      return true;
    },
  );
  cloud.gate = gate;
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: PortraitAppShell(child: child!),
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => ProgressConflictDialog(
                  sync: sync,
                  playerName: 'WWWWWWWWWWWWWWWWWWWW',
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return (sync: sync, local: local, cloud: cloud);
}

CloudProgressSnapshot _snapshot(PlayerState state, int revision) =>
    CloudProgressSnapshot(
      state: state,
      contentFingerprint: SaveService.contentFingerprint(state),
      cloudRevision: revision,
      savedAt: DateTime.utc(2026, 9, 6, 16),
    );

class _Cloud implements CloudProgressRepository {
  CloudProgressSnapshot snapshot = _snapshot(
    GameData.startingPlayerState().copyWith(
      coins: 1500,
      rebirthLevel: 1,
      questProgress: const QuestProgress(totalBossBattlesWon: 3),
    ),
    4,
  );
  var writes = 0;
  var restores = 0;
  Completer<void>? gate;
  @override
  Future<CloudProgressRead> read(String protectedPlayerId) async {
    await gate?.future;
    return CloudProgressRead.present(snapshot);
  }

  @override
  Future<CloudProgressSnapshot> write({
    required String protectedPlayerId,
    required ProgressSaveSnapshot local,
    required int? expectedCloudRevision,
  }) async {
    if (expectedCloudRevision != snapshot.cloudRevision) {
      throw const CloudProgressWriteConflict();
    }
    writes++;
    snapshot = _snapshot(local.state, snapshot.cloudRevision + 1);
    return snapshot;
  }
}
