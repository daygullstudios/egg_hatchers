import 'dart:async';

import 'package:flutter/material.dart';

import 'models/background_theme.dart';
import 'models/multiplayer.dart';
import 'models/online_lobby.dart';
import 'screens/account_onboarding_screen.dart';
import 'screens/main_game_shell.dart';
import 'screens/multiplayer_lobby_screen.dart';
import 'screens/online_trading_screen.dart';
import 'services/account_service.dart';
import 'services/account_protection_service.dart';
import 'services/audio_service.dart';
import 'services/custom_egg_service.dart';
import 'services/custom_sprite_service.dart';
import 'services/game_service.dart';
import 'services/online_lobby_service.dart';
import 'services/preferences_service.dart';
import 'services/sprite_rating_service.dart';
import 'services/sprite_reference_overlay_service.dart';
import 'widgets/animal_sprite_theme_scope.dart';
import 'widgets/account_scope.dart';
import 'widgets/account_protection_scope.dart';
import 'widgets/app_theme_background.dart';
import 'widgets/audio_scope.dart';
import 'widgets/coin_balance_scope.dart';
import 'widgets/online_lobby_host.dart';
import 'widgets/online_lobby_scope.dart';
import 'widgets/tutorial_host.dart';
import 'navigation/app_page_route.dart';
import 'utils/arena_logic.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EggHatchersApp());
}

class EggHatchersApp extends StatefulWidget {
  const EggHatchersApp({super.key});

  @override
  State<EggHatchersApp> createState() => _EggHatchersAppState();
}

class _EggHatchersAppState extends State<EggHatchersApp>
    with WidgetsBindingObserver {
  final GameService _game = GameService();
  final AccountService _accounts = AccountService();
  final AccountProtectionService _accountProtection =
      AccountProtectionService();
  final PreferencesService _preferences = PreferencesService();
  final CustomSpriteService _customSprites = CustomSpriteService();
  final CustomEggService _customEggs = CustomEggService();
  final SpriteRatingService _spriteRating = SpriteRatingService();
  final SpriteReferenceOverlayService _referenceOverlay =
      SpriteReferenceOverlayService();
  final AudioService _audio = AudioService();
  final OnlineLobbyService _onlineLobby = OnlineLobbyService();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  String? _loadedAccountId;
  var _switchingAccount = false;
  var _legacyMigrationPending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
    _game.addListener(_onGameChanged);
    _accounts.addListener(_onAccountsChanged);
    _preferences.addListener(_onGameChanged);
    _customSprites.addListener(_onGameChanged);
    _customEggs.addListener(_onGameChanged);
    _spriteRating.addListener(_onGameChanged);
    _referenceOverlay.addListener(_onGameChanged);
    _audio.addListener(_onGameChanged);
  }

  Future<void> _initialize() async {
    unawaited(_audio.initialize());
    await Future.wait([
      _accounts.initialize(),
      _accountProtection.initialize(),
    ]);
    _loadedAccountId = _accounts.account?.id;
    _legacyMigrationPending =
        _loadedAccountId == null && _accounts.accounts.isNotEmpty;
    await _game.initialize(
      accountId: _loadedAccountId,
      migrateLegacySave: _loadedAccountId != null,
    );
    await Future.wait([
      _preferences.initialize(),
      _customSprites.initialize(
        accountId: _loadedAccountId,
        migrateLegacyData: _loadedAccountId != null,
      ),
      _customEggs.initialize(
        accountId: _loadedAccountId,
        migrateLegacyData: _loadedAccountId != null,
      ),
      _spriteRating.initialize(
        accountId: _loadedAccountId,
        migrateLegacyData: _loadedAccountId != null,
      ),
      _referenceOverlay.initialize(
        accountId: _loadedAccountId,
        migrateLegacyData: _loadedAccountId != null,
      ),
    ]);
    _syncOnlinePresence();
    if (mounted) setState(() {});
  }

  void _onGameChanged() {
    _syncOnlinePresence();
    if (mounted) setState(() {});
  }

  void _onAccountsChanged() {
    _onGameChanged();
    final accountId = _accounts.account?.id;
    if (accountId == null) {
      _loadedAccountId = null;
      unawaited(_onlineLobby.disconnect());
      return;
    }
    if (!_game.isInitialized || accountId == _loadedAccountId) return;
    unawaited(_switchGameAccount(accountId));
  }

  Future<void> _switchGameAccount(String accountId) async {
    _switchingAccount = true;
    await _onlineLobby.disconnect();
    if (mounted) setState(() {});
    final migrateLegacyData = _legacyMigrationPending;
    await _game.switchAccount(accountId, migrateLegacySave: migrateLegacyData);
    await Future.wait([
      _customSprites.initialize(
        accountId: accountId,
        migrateLegacyData: migrateLegacyData,
      ),
      _customEggs.initialize(
        accountId: accountId,
        migrateLegacyData: migrateLegacyData,
      ),
      _spriteRating.initialize(
        accountId: accountId,
        migrateLegacyData: migrateLegacyData,
      ),
      _referenceOverlay.initialize(
        accountId: accountId,
        migrateLegacyData: migrateLegacyData,
      ),
    ]);
    _legacyMigrationPending = false;
    _loadedAccountId = accountId;
    _switchingAccount = false;
    _syncOnlinePresence();
    if (mounted) setState(() {});
  }

  void _syncOnlinePresence() {
    final account = _accounts.account;
    if (!_game.isInitialized || account == null) return;
    final team = ArenaLogic.recommendedTeam(_game.state.ownedAnimals)
        .map(ArenaLogic.fighterFromOwned)
        .map(MultiplayerFighterSnapshot.fromArenaFighter)
        .toList(growable: false);
    _onlineLobby.updatePresence(
      OnlinePresenceSnapshot(
        account: account,
        rating: _game.arenaRating,
        team: team,
        animals: _game.state.ownedAnimals,
      ),
    );
  }

  void _openOnlineSession(OnlineSessionLaunch launch) {
    _onlineLobby.clearSessionLaunch();
    final account = _accounts.account;
    final navigator = _navigatorKey.currentState;
    if (account == null || navigator == null) return;
    if (launch.kind == OnlineInviteKind.battle) {
      navigator.push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: kMultiplayerArenaRouteName),
          builder: (_) => MultiplayerLobbyScreen(
            game: _game,
            preferences: _preferences,
            customSprites: _customSprites,
            account: account,
            directRoomId: launch.roomId,
            lobby: _onlineLobby,
          ),
        ),
      );
    } else {
      navigator.push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: kOnlineTradingRouteName),
          builder: (_) => OnlineTradingScreen(
            game: _game,
            account: account,
            theme: _preferences.selectedTheme,
            customSprites: _customSprites,
            directRoomId: launch.roomId,
            lobby: _onlineLobby,
          ),
        ),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _game.save();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _game.removeListener(_onGameChanged);
    _accounts.removeListener(_onAccountsChanged);
    _preferences.removeListener(_onGameChanged);
    _customSprites.removeListener(_onGameChanged);
    _customEggs.removeListener(_onGameChanged);
    _spriteRating.removeListener(_onGameChanged);
    _referenceOverlay.removeListener(_onGameChanged);
    _audio.removeListener(_onGameChanged);
    _audio.dispose();
    _accountProtection.dispose();
    _onlineLobby.dispose();
    _game.dispose();
    super.dispose();
  }

  bool get _isReady =>
      _game.isInitialized &&
      _accounts.isInitialized &&
      _accountProtection.isInitialized &&
      _preferences.isInitialized &&
      _customSprites.isInitialized &&
      _customEggs.isInitialized &&
      _spriteRating.isInitialized &&
      _referenceOverlay.isInitialized;

  @override
  Widget build(BuildContext context) {
    final theme = _isReady
        ? _preferences.selectedTheme
        : BackgroundThemes.defaultTheme;

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Egg Hatchers',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [AppNavigationTracker.instance],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: theme.primaryColor,
          brightness: theme.isDark ? Brightness.dark : Brightness.light,
        ),
        scaffoldBackgroundColor: theme.scaffoldColor,
        canvasColor: theme.scaffoldColor,
        dialogTheme: DialogThemeData(backgroundColor: theme.cardColor),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        if (!_isReady || _switchingAccount) {
          return AppThemeBackground(theme: theme, child: content);
        }
        return AppThemeBackground(
          theme: theme,
          child: AudioScope(
            audio: _audio,
            child: AudioUnlockListener(
              audio: _audio,
              child: AccountScope(
                accounts: _accounts,
                child: AccountProtectionScope(
                  protection: _accountProtection,
                  child: OnlineLobbyScope(
                    lobby: _onlineLobby,
                    child: OnlineLobbyHost(
                      lobby: _onlineLobby,
                      onSessionReady: _openOnlineSession,
                      child: CoinBalanceScope(
                        coins: _game.coins,
                        child: AnimalSpriteThemeScope(
                          theme: _preferences.animalSpriteTheme,
                          child: TutorialHost(
                            game: _game,
                            theme: theme,
                            child: content,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      home: !_isReady || _switchingAccount
          ? const _LoadingScreen()
          : !_accounts.hasAccount
          ? AccountOnboardingScreen(accounts: _accounts, game: _game)
          : MainGameShell(
              game: _game,
              preferences: _preferences,
              customSprites: _customSprites,
              customEggs: _customEggs,
              spriteRating: _spriteRating,
              referenceOverlay: _referenceOverlay,
            ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000823),
      body: ColoredBox(
        color: const Color(0xFF000823),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final logoSize = (constraints.biggest.shortestSide * 0.72).clamp(
              180.0,
              440.0,
            );

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/ui/app_logo.png',
                      width: logoSize,
                      height: logoSize,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      semanticLabel: 'Egg Hatchers',
                    ),
                    const SizedBox(height: 24),
                    const SizedBox.square(
                      dimension: 30,
                      child: CircularProgressIndicator(
                        color: Color(0xFFFFC247),
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
