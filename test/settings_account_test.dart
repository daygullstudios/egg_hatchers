import 'package:egg_hatchers/screens/settings_screen.dart';
import 'package:egg_hatchers/services/account_service.dart';
import 'package:egg_hatchers/services/account_protection_service.dart';
import 'package:egg_hatchers/services/audio_service.dart';
import 'package:egg_hatchers/services/device_guest_slot_store.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/preferences_service.dart';
import 'package:egg_hatchers/services/save_service.dart';
import 'package:egg_hatchers/services/progress_sync_service.dart';
import 'package:egg_hatchers/models/progress_sync_state.dart';
import 'package:egg_hatchers/models/progress_conflict_review.dart';
import 'package:egg_hatchers/widgets/progress_sync_scope.dart';
import 'package:egg_hatchers/widgets/progress_conflict_dialog.dart';
import 'package:egg_hatchers/widgets/account_scope.dart';
import 'package:egg_hatchers/widgets/account_protection_scope.dart';
import 'package:egg_hatchers/widgets/audio_scope.dart';
import 'package:egg_hatchers/widgets/game_primary_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'Settings opens review instead of replacing either save directly',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final accounts = AccountService();
      final game = GameService();
      final preferences = PreferencesService();
      final audio = AudioService();
      final sync = _ReviewOnlySync();
      await accounts.initialize();
      await game.initialize(accountId: accounts.account!.id);
      await preferences.initialize();
      await tester.pumpWidget(
        AccountScope(
          accounts: accounts,
          child: AudioScope(
            audio: audio,
            child: ProgressSyncScope(
              sync: sync,
              child: MaterialApp(
                home: SettingsScreen(preferences: preferences, game: game),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-panel-account')));
      await tester.pumpAndSettle();
      expect(find.text('Use Cloud'), findsNothing);
      expect(find.text('Keep Device'), findsNothing);
      final compare = find.byKey(const ValueKey('settings-compare-saves'));
      await tester.ensureVisible(compare);
      await tester.tap(compare);
      await tester.pumpAndSettle();
      expect(find.byType(ProgressConflictDialog), findsOneWidget);
      expect(sync.reviews, 1);
      expect(find.text('Replace'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('save-review-later')));
      await tester.pumpAndSettle();
      expect(find.byType(ProgressConflictDialog), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      sync.dispose();
      audio.dispose();
      preferences.dispose();
      game.dispose();
      accounts.dispose();
    },
  );

  testWidgets('local removal cancels safely and preserves other players', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final accounts = AccountService();
    final game = GameService();
    final preferences = PreferencesService();
    final audio = AudioService();
    addTearDown(accounts.dispose);
    addTearDown(preferences.dispose);
    await accounts.initialize();
    final otherPlayer = accounts.account!;
    await game.initialize(accountId: otherPlayer.id);
    game.setCoins(777);
    await game.save();
    await preferences.initialize();
    await accounts.createAccount(
      displayName: 'Remove This Player',
      username: 'remove_me',
      avatarColor: AccountService.avatarColors.first,
    );
    final target = accounts.account!;
    await game.switchAccount(target.id);
    game.setCoins(5678);
    await game.save();
    final prefs = await SharedPreferences.getInstance();
    final targetArt = 'customSprite.account.${target.id}.chicken';
    final otherArt = 'customSprite.account.${otherPlayer.id}.chicken';
    await prefs.setString(targetArt, 'target-art');
    await prefs.setString(otherArt, 'other-art');
    await preferences.setHapticsEnabled(false);

    await tester.pumpWidget(
      AccountScope(
        accounts: accounts,
        child: AudioScope(
          audio: audio,
          child: MaterialApp(
            home: SettingsScreen(preferences: preferences, game: game),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings-panel-account')));
    await tester.pumpAndSettle();
    expect(find.text('Delete Account'), findsNothing);
    expect(find.text('Remove local player'), findsOneWidget);
    final remove = find.byKey(const ValueKey('settings-delete-account-button'));
    await tester.ensureVisible(remove);
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(find.text('Remove local player?'), findsOneWidget);
    expect(find.text('Remove This Player'), findsNWidgets(2));
    expect(
      find.text('Cloud data and sign-in accounts are not deleted.'),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('settings-cancel-remove-local-player')),
    );
    await tester.pumpAndSettle();
    expect(accounts.account?.id, target.id);
    expect((await SaveService(accountId: target.id).load())?.coins, 5678);
    expect(prefs.getString(targetArt), 'target-art');

    await tester.ensureVisible(remove);
    await tester.tap(remove);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('settings-confirm-delete-account')),
    );
    await tester.pumpAndSettle();
    expect(accounts.accounts.any((a) => a.id == target.id), isFalse);
    expect(await SaveService(accountId: target.id).load(), isNull);
    expect(prefs.containsKey(targetArt), isFalse);
    expect(accounts.accounts.single.id, otherPlayer.id);
    expect((await SaveService(accountId: otherPlayer.id).load())?.coins, 777);
    expect(prefs.getString(otherArt), 'other-art');
    final restoredPreferences = PreferencesService();
    await restoredPreferences.initialize();
    expect(restoredPreferences.hapticsEnabled, isFalse);
    restoredPreferences.dispose();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    game.dispose();
    audio.dispose();
  });

  testWidgets('settings shows and switches the active account', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final accounts = AccountService();
    final game = GameService();
    final preferences = PreferencesService();
    final audio = AudioService();
    await Future.wait([
      accounts.initialize(),
      game.initialize(),
      preferences.initialize(),
    ]);
    await accounts.createAccount(
      displayName: 'Settings Player',
      username: 'settings_player',
      avatarColor: AccountService.avatarColors.first,
    );

    await tester.pumpWidget(
      AccountScope(
        accounts: accounts,
        child: AudioScope(
          audio: audio,
          child: MaterialApp(
            home: MainGameShellScope(
              current: MainGameDestination.settings,
              game: game,
              onSelect: (_) {},
              child: SettingsScreen(preferences: preferences, game: game),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Account & Saves'), findsOneWidget);
    expect(find.text('Sound & Feedback'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Custom Animals'), findsNothing);
    expect(find.byType(GamePrimaryNavigation), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    expect(find.text('Music').hitTestable(), findsNothing);
    expect(find.text('Settings Player').hitTestable(), findsNothing);

    await tester.tap(find.byKey(const ValueKey('settings-panel-account')));
    await tester.pumpAndSettle();

    expect(find.text('Settings Player').hitTestable(), findsOneWidget);
    expect(find.text('@settings_player'), findsOneWidget);
    expect(find.text('Device only'), findsOneWidget);
    expect(find.text('Progress is saved only on this device.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings-progress-sync-status')),
      findsOneWidget,
    );
    expect(find.text('Device progress'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings-account-protection-status')),
      findsOneWidget,
    );
    expect(find.text('Save Transfer'), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-export-save')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-copy-save')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-import-save')), findsOneWidget);
    expect(find.text('Music').hitTestable(), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('settings-switch-account-button')),
    );
    await tester.pump();
    expect(accounts.hasAccount, isFalse);

    game.dispose();
    audio.dispose();
  });

  testWidgets('device guest can protect progress with Google', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final accounts = AccountService();
    final game = GameService();
    final preferences = PreferencesService();
    final audio = AudioService();
    await accounts.initialize();
    await Future.wait([
      game.initialize(accountId: accounts.account?.id),
      preferences.initialize(),
    ]);
    final account = accounts.account!;
    await DeviceGuestSlotStore().bindFirebaseUid(
      accountId: account.id,
      firebaseUid: 'anonymous-123',
    );
    final protection = AccountProtectionService(
      gateway: _SettingsProtectionGateway(),
    );
    await protection.initialize(accountId: account.id);

    await tester.pumpWidget(
      AccountScope(
        accounts: accounts,
        child: AccountProtectionScope(
          protection: protection,
          child: AudioScope(
            audio: audio,
            child: MaterialApp(
              home: MainGameShellScope(
                current: MainGameDestination.settings,
                game: game,
                onSelect: (_) {},
                child: SettingsScreen(preferences: preferences, game: game),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings-panel-account')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('settings-protect-with-google')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('settings-protect-with-google')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Protected'), findsOneWidget);
    expect(find.text('Protected with Google'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings-protect-with-google')),
      findsNothing,
    );

    protection.dispose();
    game.dispose();
    audio.dispose();
  });
}

class _ReviewOnlySync extends ProgressSyncService {
  var reviews = 0;
  @override
  ProgressSyncState get state => const ProgressSyncState(
    status: ProgressSyncStatus.conflict,
    message: 'Compare both saves before choosing.',
  );
  @override
  Future<ProgressConflictReview?> prepareConflictReview() async {
    reviews++;
    return null;
  }
}

final class _SettingsProtectionGateway implements AccountProtectionGateway {
  @override
  bool get isConfigured => true;

  @override
  bool get canLinkGoogle => true;

  @override
  Future<ProtectedPlayerIdentity?> restoreIdentity({
    required String accountId,
    required String? expectedPlayerId,
  }) async => const ProtectedPlayerIdentity(playerId: 'anonymous-123');

  @override
  Future<ProtectedPlayerIdentity?> linkGoogle({
    required String expectedPlayerId,
  }) async => const ProtectedPlayerIdentity(
    playerId: 'anonymous-123',
    providerIds: {'google.com'},
  );
}
