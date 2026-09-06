import 'package:egg_hatchers/screens/settings_screen.dart';
import 'package:egg_hatchers/services/account_service.dart';
import 'package:egg_hatchers/services/audio_service.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/preferences_service.dart';
import 'package:egg_hatchers/widgets/account_scope.dart';
import 'package:egg_hatchers/widgets/audio_scope.dart';
import 'package:egg_hatchers/widgets/game_primary_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
}
