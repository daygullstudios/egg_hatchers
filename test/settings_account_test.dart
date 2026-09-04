import 'package:egg_hatchers/screens/settings_screen.dart';
import 'package:egg_hatchers/services/account_service.dart';
import 'package:egg_hatchers/services/audio_service.dart';
import 'package:egg_hatchers/services/custom_sprite_service.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/preferences_service.dart';
import 'package:egg_hatchers/services/sprite_rating_service.dart';
import 'package:egg_hatchers/services/sprite_reference_overlay_service.dart';
import 'package:egg_hatchers/widgets/account_scope.dart';
import 'package:egg_hatchers/widgets/audio_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('settings shows and switches the active account', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final accounts = AccountService();
    final game = GameService();
    final preferences = PreferencesService();
    final sprites = CustomSpriteService();
    final ratings = SpriteRatingService();
    final references = SpriteReferenceOverlayService();
    final audio = AudioService();
    await Future.wait([
      accounts.initialize(),
      game.initialize(),
      preferences.initialize(),
      sprites.initialize(),
      ratings.initialize(),
      references.initialize(),
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
            home: SettingsScreen(
              preferences: preferences,
              customSprites: sprites,
              game: game,
              spriteRating: ratings,
              referenceOverlay: references,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Settings Player'), findsOneWidget);
    expect(find.text('@settings_player'), findsOneWidget);
    expect(find.text('Save Transfer'), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-export-save')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-copy-save')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-import-save')), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('settings-switch-account-button')),
    );
    await tester.pump();
    expect(accounts.hasAccount, isFalse);

    game.dispose();
    audio.dispose();
  });
}
