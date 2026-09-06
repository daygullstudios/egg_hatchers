import 'package:egg_hatchers/models/player_account.dart';
import 'package:egg_hatchers/widgets/app_theme_background.dart';
import 'package:egg_hatchers/widgets/local_player_removal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final _guest = PlayerAccount(
  id: 'guest_test',
  displayName: 'WWWWWWWWWWWWWWWWWWWW',
  username: 'guest_test',
  avatarColorValue: 0xFF5271FF,
  createdAt: DateTime.utc(2026, 9, 6),
  isGuest: true,
);

Future<void> _openDialog(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  ValueChanged<bool?>? onResult,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: PortraitAppShell(child: child!),
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (_) => LocalPlayerRemovalDialog(account: _guest),
                );
                onResult?.call(result);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  for (final scenario in [
    (const Size(320, 568), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(390, 844), 1.0),
    (const Size(430, 932), 2.0),
    (const Size(320, 360), 2.0),
    (const Size(1400, 900), 2.0),
  ]) {
    testWidgets('removal is readable/reachable at $scenario', (tester) async {
      await _openDialog(tester, size: scenario.$1, textScale: scenario.$2);
      final surface = tester.getRect(find.byKey(PortraitAppShell.surfaceKey));
      final dialog = tester.getRect(find.byType(AlertDialog));
      expect(dialog.left, greaterThanOrEqualTo(surface.left));
      expect(dialog.right, lessThanOrEqualTo(surface.right));
      expect(dialog.top, greaterThanOrEqualTo(surface.top));
      expect(dialog.bottom, lessThanOrEqualTo(surface.bottom));
      expect(tester.takeException(), isNull);

      // Long content can move without hiding or shrinking the decision buttons.
      final backup = find.textContaining('There is no undo.');
      await tester.ensureVisible(backup);
      await tester.pumpAndSettle();
      expect(backup.hitTestable(), findsOneWidget);
      for (final key in [
        'settings-cancel-remove-local-player',
        'settings-confirm-delete-account',
      ]) {
        final button = find.byKey(ValueKey(key));
        expect(button.hitTestable(), findsOneWidget);
        final rect = tester.getRect(button);
        expect(rect.top, greaterThanOrEqualTo(surface.top));
        expect(rect.bottom, lessThanOrEqualTo(surface.bottom));
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('explains local scope and keyboard defaults to keeping player', (
    tester,
  ) async {
    bool? result;
    await _openDialog(tester, onResult: (value) => result = value);
    expect(find.text('Remove local player?'), findsOneWidget);
    expect(
      find.textContaining('Other players and device settings stay.'),
      findsOneWidget,
    );
    expect(
      find.text('Cloud data and sign-in accounts are not deleted.'),
      findsOneWidget,
    );
    expect(find.textContaining('A guest cloud copy'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(LocalPlayerRemovalDialog), findsNothing);
    expect(result, isFalse);
  });

  testWidgets('only explicit Remove confirms local removal', (tester) async {
    bool? result;
    await _openDialog(tester, onResult: (value) => result = value);
    await tester.tap(
      find.byKey(const ValueKey('settings-confirm-delete-account')),
    );
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
