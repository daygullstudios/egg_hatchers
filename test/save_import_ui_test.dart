import 'dart:async';

import 'package:egg_hatchers/services/save_transfer_service.dart';
import 'package:egg_hatchers/widgets/save_import_bootstrap.dart';
import 'package:egg_hatchers/widgets/save_import_review_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/save_import_fixture.dart';

void main() {
  for (final config in [
    (320.0, 640.0, 1.0),
    (390.0, 844.0, 1.0),
    (430.0, 932.0, 1.0),
    (1440.0, 900.0, 1.0),
    (320.0, 360.0, 1.0),
    (320.0, 360.0, 2.0),
  ]) {
    testWidgets('review and cancellation fit $config', (tester) async {
      tester.view.physicalSize = Size(config.$1, config.$2);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var stages = 0;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(config.$3)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => SaveImportReviewDialog(
                    preview: SaveTransferService().inspectSave(importFixture()),
                    stageImport: (_) async {
                      stages++;
                    },
                    restart: () {},
                  ),
                ),
                child: const Text('Review'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Cancel'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(stages, 0);
      expect(find.byType(SaveImportReviewDialog), findsNothing);
    });
  }

  testWidgets(
    'keyboard default cancels; explicit import stages once and requires restart',
    (tester) async {
      var stages = 0, restarts = 0;
      final gate = Completer<void>();
      Future<void> open() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: FilledButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => SaveImportReviewDialog(
                      preview: SaveTransferService().inspectSave(
                        importFixture(),
                      ),
                      stageImport: (_) async {
                        stages++;
                        await gate.future;
                      },
                      restart: () {
                        restarts++;
                      },
                    ),
                  ),
                  child: const Text('Review'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Review'));
        await tester.pumpAndSettle();
      }

      await open();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(SaveImportReviewDialog), findsNothing);
      expect(stages, 0);
      await open();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import & restart'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byType(SaveImportReviewDialog), findsOneWidget);
      expect(stages, 1);
      expect(find.text('Cancel'), findsNothing);
      gate.complete();
      await tester.pumpAndSettle();
      expect(restarts, 1);
      expect(find.text('Restart game'), findsOneWidget);
    },
  );

  testWidgets('failed preparation cannot return to the old running game', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SaveImportReviewDialog(
          preview: SaveTransferService().inspectSave(importFixture()),
          stageImport: (_) async => throw StateError('private payload'),
          restart: () {},
        ),
      ),
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import & restart'));
    await tester.pumpAndSettle();
    expect(find.text('Restart game'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    expect(find.textContaining('private payload'), findsNothing);
  });

  testWidgets(
    'blocked exclusive lease starts neither Firebase nor game; cancellation preserves originals',
    (tester) async {
      final storage = ImportMemoryStorage({'keep': 'original'});
      final transfer = SaveTransferService(storage: storage);
      await transfer.stageImport(transfer.inspectSave(importFixture()));
      var otherTab = true, cloudStarts = 0;
      final leases = <String>[];
      await tester.pumpWidget(
        SaveImportBootstrap(
          transfer: transfer,
          initializeCloud: () async {
            cloudStarts++;
            return true;
          },
          appBuilder: (_) => const MaterialApp(home: Text('Game')),
          acquireLease: ({bool exclusive = false}) async {
            leases.add(exclusive ? 'exclusive' : 'shared');
            if (exclusive && otherTab) {
              throw const SaveTransferException('Close other game tabs');
            }
            return () async {
              leases.add('release');
            };
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Import paused'), findsOneWidget);
      expect(cloudStarts, 0);
      expect(storage.values['keep'], 'original');
      expect(leases, ['shared', 'release', 'exclusive']);
      otherTab = false;
      await tester.tap(find.text('Keep original saves'));
      await tester.pumpAndSettle();
      expect(storage.values, {'keep': 'original'});
      expect(cloudStarts, 0);
      await tester.tap(find.text('Open game'));
      await tester.pumpAndSettle();
      expect(cloudStarts, 1);
      expect(find.text('Game'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('successful import precedes all game and cloud initialization', (
    tester,
  ) async {
    final storage = ImportMemoryStorage({'keep': 'original'});
    final transfer = SaveTransferService(storage: storage);
    await transfer.stageImport(transfer.inspectSave(importFixture()));
    var starts = 0;
    await tester.pumpWidget(
      SaveImportBootstrap(
        transfer: transfer,
        acquireLease: ({bool exclusive = false}) async => () async {},
        initializeCloud: () async {
          starts++;
          expect(await transfer.hasPendingImport(), false);
          return true;
        },
        appBuilder: (_) => const MaterialApp(home: Text('Game')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Import complete'), findsOneWidget);
    expect(starts, 0);
    expect(storage.values['keep'], isNull);
    await tester.tap(find.text('Open game'));
    await tester.pumpAndSettle();
    expect(starts, 1);
    await tester.pumpWidget(const SizedBox());
  });
}
