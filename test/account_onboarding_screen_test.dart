import 'package:egg_hatchers/models/player_state.dart';
import 'package:egg_hatchers/screens/account_onboarding_screen.dart';
import 'package:egg_hatchers/services/account_service.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/save_service.dart';
import 'package:egg_hatchers/widgets/app_theme_background.dart';
import 'package:egg_hatchers/widgets/local_player_removal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final scenario in [
    (const Size(320, 568), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(390, 844), 1.0),
    (const Size(430, 932), 2.0),
    (const Size(320, 360), 2.0),
    (const Size(1400, 900), 2.0),
  ]) {
    testWidgets('picker, safe removal and creation fit $scenario', (
      tester,
    ) async {
      final fixture = await _openPicker(
        tester,
        size: scenario.$1,
        textScale: scenario.$2,
      );
      final guest = fixture.accounts.accounts.single;
      final surface = tester.getRect(find.byKey(PortraitAppShell.surfaceKey));
      expect(
        find.textContaining('not a sign-in or recovery screen'),
        findsOneWidget,
      );
      expect(find.byTooltip('Delete account'), findsNothing);
      final remove = find.byKey(ValueKey('delete-account-${guest.id}'));
      await tester.ensureVisible(remove);
      await tester.pumpAndSettle();
      expect(tester.getSize(remove).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(remove).height, greaterThanOrEqualTo(48));
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(find.byType(LocalPlayerRemovalDialog), findsOneWidget);
      expect(
        find.text('Cloud data and sign-in accounts are not deleted.'),
        findsOneWidget,
      );
      final backup = find.text('Settings > Account & Saves > Export Save.');
      await tester.ensureVisible(backup);
      await tester.pumpAndSettle();
      expect(backup.hitTestable(), findsOneWidget);
      final dialog = tester.getRect(find.byType(AlertDialog));
      expect(dialog.left, greaterThanOrEqualTo(surface.left));
      expect(dialog.right, lessThanOrEqualTo(surface.right));
      expect(dialog.top, greaterThanOrEqualTo(surface.top));
      expect(dialog.bottom, lessThanOrEqualTo(surface.bottom));
      expect(find.text('Keep player').hitTestable(), findsOneWidget);
      expect(find.text('Remove').hitTestable(), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(LocalPlayerRemovalDialog), findsNothing);
      expect(fixture.accounts.accounts.single.id, guest.id);

      final create = find.byKey(
        const ValueKey('create-another-account-button'),
      );
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Existing players keep their saves.'),
        findsOneWidget,
      );
      expect(find.textContaining('not your real name'), findsOneWidget);
      for (final color in [
        'Blue',
        'Purple',
        'Teal',
        'Pink',
        'Orange',
        'Green',
      ]) {
        final choice = find.byKey(ValueKey('avatar-color-$color'));
        await tester.ensureVisible(choice);
        await tester.pumpAndSettle();
        final rect = tester.getRect(choice);
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.left, greaterThanOrEqualTo(surface.left));
        expect(rect.right, lessThanOrEqualTo(surface.right));
        expect(choice.hitTestable(), findsOneWidget);
      }
      final back = find.text('Back to players');
      await tester.ensureVisible(back);
      await tester.pumpAndSettle();
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.text('Choose local player'), findsOneWidget);
      expect(fixture.accounts.accounts.single.id, guest.id);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      fixture.game.dispose();
      fixture.accounts.dispose();
    });
  }

  testWidgets(
    'picker cancellation and removal preserve another player and settings',
    (tester) async {
      final fixture = await _openPicker(tester);
      final target = fixture.accounts.accounts.single;
      await SaveService(
        accountId: target.id,
      ).save(PlayerState.initial().copyWith(coins: 900));
      await fixture.accounts.createAccount(
        displayName: 'Other Player',
        username: 'other_player',
        avatarColor: AccountService.avatarColors.last,
      );
      final other = fixture.accounts.account!;
      await SaveService(
        accountId: other.id,
      ).save(PlayerState.initial().copyWith(coins: 777));
      fixture.accounts.chooseAnotherAccount();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'customSprite.account.${target.id}.chicken',
        'target-art',
      );
      await prefs.setString(
        'customSprite.account.${other.id}.chicken',
        'other-art',
      );
      await prefs.setBool('device-setting-test', false);

      final remove = find.byKey(ValueKey('delete-account-${target.id}'));
      await tester.tap(remove);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep player'));
      await tester.pumpAndSettle();
      expect((await SaveService(accountId: target.id).load())?.coins, 900);
      expect(
        prefs.getString('customSprite.account.${target.id}.chicken'),
        'target-art',
      );
      expect(fixture.accounts.accounts.length, 2);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(fixture.accounts.accounts.single.id, other.id);
      expect(await SaveService(accountId: target.id).load(), isNull);
      expect(
        prefs.containsKey('customSprite.account.${target.id}.chicken'),
        isFalse,
      );
      expect((await SaveService(accountId: other.id).load())?.coins, 777);
      expect(
        prefs.getString('customSprite.account.${other.id}.chicken'),
        'other-art',
      );
      expect(prefs.getBool('device-setting-test'), isFalse);
      expect(find.text('Other Player'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      fixture.game.dispose();
      fixture.accounts.dispose();
    },
  );

  testWidgets('account picker fits a narrow phone for the automatic guest', (
    tester,
  ) async {
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

    expect(find.text('Choose local player'), findsOneWidget);
    expect(find.text('Guest Hatcher'), findsOneWidget);
    expect(find.text('Guest · saved on this device'), findsOneWidget);
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

    final existing = accounts.account!;
    await SaveService(
      accountId: existing.id,
    ).save(PlayerState.initial().copyWith(coins: 7654));

    await tester.tap(
      find.byKey(const ValueKey('create-another-account-button')),
    );
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey('account-display-name')),
      'Egg Hero',
    );
    await tester.enterText(
      find.byKey(const ValueKey('account-username')),
      'egg_hero',
    );
    final createButton = find.byKey(const ValueKey('create-account-button'));
    await tester.ensureVisible(createButton);
    await tester.pumpAndSettle();
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(accounts.hasAccount, isTrue);
    expect(accounts.account!.username, 'egg_hero');
    expect(accounts.accounts.any((player) => player.id == existing.id), isTrue);
    expect((await SaveService(accountId: existing.id).load())?.coins, 7654);
    expect(await SaveService(accountId: accounts.account!.id).load(), isNull);
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

    expect(find.text('Choose local player'), findsOneWidget);
    expect(find.text('First Player'), findsOneWidget);
    expect(find.text('Second Player'), findsOneWidget);
    expect(find.text('Local profile · @first_player'), findsOneWidget);
    expect(find.text('Local profile · @second_player'), findsOneWidget);
    await tester.tap(find.text('First Player'));
    expect(accounts.account!.username, 'first_player');
    game.dispose();
  });
}

Future<({AccountService accounts, GameService game})> _openPicker(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final accounts = AccountService();
  final game = GameService();
  await accounts.initialize();
  await game.initialize(accountId: accounts.account!.id);
  accounts.chooseAnotherAccount();
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: PortraitAppShell(child: child!),
      ),
      home: AccountOnboardingScreen(accounts: accounts, game: game),
    ),
  );
  await tester.pumpAndSettle();
  return (accounts: accounts, game: game);
}
