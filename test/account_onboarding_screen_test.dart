import 'package:egg_hatchers/screens/account_onboarding_screen.dart';
import 'package:egg_hatchers/services/account_service.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('account onboarding fits a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final accounts = AccountService();
    final game = GameService();
    await Future.wait([accounts.initialize(), game.initialize()]);

    await tester.pumpWidget(
      MaterialApp(
        home: AccountOnboardingScreen(accounts: accounts, game: game),
      ),
    );
    await tester.pump();

    expect(find.text('Create your account'), findsOneWidget);
    expect(tester.takeException(), isNull);
    game.dispose();
  });

  testWidgets('account onboarding creates the first player profile', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final accounts = AccountService();
    final game = GameService();
    await Future.wait([accounts.initialize(), game.initialize()]);
    await tester.pumpWidget(
      MaterialApp(
        home: AccountOnboardingScreen(accounts: accounts, game: game),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('account-display-name')),
      'Egg Hero',
    );
    await tester.enterText(
      find.byKey(const ValueKey('account-username')),
      'egg_hero',
    );
    await tester.tap(find.byKey(const ValueKey('create-account-button')));
    await tester.pumpAndSettle();

    expect(accounts.hasAccount, isTrue);
    expect(accounts.account!.username, 'egg_hero');
    game.dispose();
  });

  testWidgets('account picker selects between saved profiles', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final accounts = AccountService();
    final game = GameService();
    await Future.wait([accounts.initialize(), game.initialize()]);
    await accounts.createAccount(
      displayName: 'First Player',
      username: 'first_player',
      avatarColor: AccountService.avatarColors.first,
    );
    await accounts.createAccount(
      displayName: 'Second Player',
      username: 'second_player',
      avatarColor: AccountService.avatarColors.last,
    );
    accounts.chooseAnotherAccount();

    await tester.pumpWidget(
      MaterialApp(
        home: AccountOnboardingScreen(accounts: accounts, game: game),
      ),
    );

    expect(find.text('Choose account'), findsOneWidget);
    expect(find.text('First Player'), findsOneWidget);
    expect(find.text('Second Player'), findsOneWidget);
    await tester.tap(find.text('First Player'));
    expect(accounts.account!.username, 'first_player');
    game.dispose();
  });
}
