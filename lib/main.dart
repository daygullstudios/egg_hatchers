import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'models/background_theme.dart';
import 'models/multiplayer.dart';
import 'models/online_lobby.dart';
import 'screens/account_onboarding_screen.dart';
import 'screens/saved_player_recovery_screen.dart';
import 'screens/unsaved_progress_screen.dart';
import 'screens/main_game_shell.dart';
import 'screens/multiplayer_lobby_screen.dart';
import 'screens/online_trading_screen.dart';
import 'services/account_service.dart';
import 'services/account_protection_service.dart';
import 'services/audio_service.dart';
import 'services/custom_egg_service.dart';
import 'services/custom_sprite_service.dart';
import 'services/firebase_anonymous_auth_gateway.dart';
import 'services/firebase_bootstrap.dart';
import 'services/cloud_connection_service.dart';
import 'widgets/cloud_connection_scope.dart';
import 'services/firebase_progress_repository.dart';
import 'services/game_service.dart';
import 'services/online_lobby_service.dart';
import 'services/preferences_service.dart';
import 'services/progress_sync_service.dart';
import 'services/save_storage_lease.dart';
import 'services/save_transfer_service.dart';
import 'services/saved_player_directory.dart';
import 'services/save_service.dart';
import 'services/progress_recovery_service.dart';
import 'services/unsaved_exit_guard.dart';
import 'widgets/save_import_bootstrap.dart';
import 'widgets/save_import_scope.dart';
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
import 'widgets/progress_sync_scope.dart';
import 'widgets/tutorial_host.dart';
import 'navigation/app_page_route.dart';
import 'utils/arena_logic.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    SaveImportBootstrap(
      appBuilder: (cloud) => NestariumApp(cloudConnection: cloud),
      initializeCloud: FirebaseBootstrap.initialize,
    ),
  );
}

class NestariumApp extends StatefulWidget {
  const NestariumApp({
    super.key,
    this.accounts,
    this.game,
    this.accountProtection,
    this.onlineLobby,
    this.progressSync,
    this.cloudConnection,
  });

  // The app owns these services, including injected instances (except the
  // bootstrap-owned cloudConnection). Keeping the
  // composition root injectable lets tests exercise real player transitions.
  final AccountService? accounts;
  final GameService? game;
  final AccountProtectionService? accountProtection;
  final OnlineLobbyService? onlineLobby;
  final ProgressSyncService? progressSync;
  final CloudConnectionService? cloudConnection;

  @override
  State<NestariumApp> createState() => _NestariumAppState();
}

class _NestariumAppState extends State<NestariumApp>
    with WidgetsBindingObserver {
  late final GameService _game = widget.game ?? GameService();
  late final AccountService _accounts = widget.accounts ?? AccountService();
  late final AccountProtectionService _accountProtection =
      widget.accountProtection ??
      AccountProtectionService(gateway: FirebaseAnonymousAuthGateway());
  late final ProgressSyncService _progressSync =
      widget.progressSync ?? ProgressSyncService();
  final PreferencesService _preferences = PreferencesService();
  final CustomSpriteService _customSprites = CustomSpriteService();
  final CustomEggService _customEggs = CustomEggService();
  final SpriteRatingService _spriteRating = SpriteRatingService();
  final SpriteReferenceOverlayService _referenceOverlay =
      SpriteReferenceOverlayService();
  final AudioService _audio = AudioService();
  late final OnlineLobbyService _onlineLobby =
      widget.onlineLobby ?? OnlineLobbyService();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  String? _loadedAccountId;
  String? _configuredProgressPlayerId;
  String? _configuredProgressAccountId;
  var _switchingAccount = false;
  var _importFrozen = false;
  var _saveAttentionHeld = false;
  var _checkingAccounts = false;
  AccountStartupFailure? _accountStartupFailure;
  ProgressReadException? _progressFailure;
  var _startingUp = false;
  var _rootInitialized = false;
  Timer? _localLoadTimer;
  bool _localLoadSlow = false;
  var _playerSwitchFailed = false;
  var _accountSelectionRevision = 0;
  var _legacyMigrationPending = false;
  String? _legacyMigrationAccountId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game.onProgressSaved = _progressSync.localProgressSaved;
    _initialize();
    _game.addListener(_onGameChanged);
    _accounts.addListener(_onAccountsChanged);
    _accountProtection.addListener(_onProtectionChanged);
    _preferences.addListener(_onGameChanged);
    _customSprites.addListener(_onGameChanged);
    _customEggs.addListener(_onGameChanged);
    _spriteRating.addListener(_onGameChanged);
    _referenceOverlay.addListener(_onGameChanged);
    _audio.addListener(_onGameChanged);
    widget.cloudConnection?.addListener(_onCloudConnectionChanged);
  }

  Future<void> _initialize() async {
    if (_startingUp || _importFrozen || !mounted) return;
    _startingUp = true;
    _watchLocalLoad();
    try {
      _checkingAccounts = true;
      try {
        await _accounts.initialize();
      } catch (error) {
        if (mounted) {
          setState(
            () => _accountStartupFailure = error is AccountStartupException
                ? error.failure
                : AccountStartupFailure.storageUnavailable,
          );
        }
        return;
      } finally {
        _checkingAccounts = false;
      }
      if (!mounted) return;
      setState(() => _accountStartupFailure = null);
      _loadedAccountId = _accounts.account?.id;
      if (_loadedAccountId == null) {
        _legacyMigrationPending = _accounts.accounts.isNotEmpty;
        _progressFailure = null;
        return;
      }
      try {
        await _game.initialize(
          accountId: _loadedAccountId,
          migrateLegacySave: _loadedAccountId != null,
        );
        _progressFailure = null;
        unawaited(_audio.initialize());
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
      } catch (error) {
        _holdProgress(
          error is ProgressReadException
              ? error
              : ProgressReadException(
                  failure: ProgressReadFailure.storageUnavailable,
                  accountId: _loadedAccountId,
                ),
        );
        return;
      }
      _rootInitialized = true;
      _syncOnlinePresence();
      if (mounted) setState(() {});
      _startIdentityCheck();
    } finally {
      _localLoadTimer?.cancel();
      _startingUp = false;
      if (mounted) setState(() {});
    }
  }

  void _watchLocalLoad() {
    _localLoadTimer?.cancel();
    _localLoadSlow = false;
    _localLoadTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _localLoadSlow = true);
    });
  }

  void _onCloudConnectionChanged() {
    if (widget.cloudConnection?.isAvailable == true) _startIdentityCheck();
    if (mounted) setState(() {});
  }

  void _startIdentityCheck() {
    if (_importFrozen ||
        _game.saveNeedsAttention ||
        !mounted ||
        !_isReady ||
        _switchingAccount ||
        _playerSwitchFailed ||
        _accounts.account?.id != _loadedAccountId ||
        widget.cloudConnection != null &&
            !widget.cloudConnection!.isAvailable) {
      return;
    }
    final accountId = _loadedAccountId;
    unawaited(
      _accountProtection
          .initialize(accountId: accountId)
          .then((_) async {
            if (mounted && !_importFrozen && accountId == _loadedAccountId) {
              await _configureProgressSync();
            }
          })
          .catchError((Object _) {
            // Optional identity work cannot turn a valid local save into a recovery
            // failure. Its service owns connection status and retry.
          }),
    );
  }

  void _onGameChanged() {
    if (_saveAttentionHeld != _game.saveNeedsAttention) {
      _saveAttentionHeld = _game.saveNeedsAttention;
      setUnsavedExitGuard(_saveAttentionHeld);
      _progressSync.setLocalPersistencePaused(_saveAttentionHeld);
      if (_saveAttentionHeld) unawaited(_onlineLobby.disconnect());
    }
    if (!_startingUp &&
        !_switchingAccount &&
        _accounts.hasAccount &&
        _loadedAccountId != null &&
        _game.progressReadFailure != null &&
        !identical(_progressFailure, _game.progressReadFailure)) {
      _holdProgress(_game.progressReadFailure!);
    }
    _syncOnlinePresence();
    if (mounted) setState(() {});
  }

  void _onAccountsChanged() {
    if (_importFrozen || _game.saveNeedsAttention) return;
    if (!_rootInitialized) {
      if (!_startingUp) {
        _progressFailure = null;
        unawaited(_initialize());
      }
      if (mounted) setState(() {});
      return;
    }
    final accountId = _accounts.account?.id;
    if (accountId == _loadedAccountId &&
        !_switchingAccount &&
        !_playerSwitchFailed &&
        accountId != null) {
      _onGameChanged();
      return;
    }
    _accountSelectionRevision++;
    _playerSwitchFailed = false;
    _progressFailure = null;
    _loadedAccountId = null;
    _configuredProgressPlayerId = null;
    _configuredProgressAccountId = null;
    unawaited(_accountProtection.selectAccount(null));
    // Revoke old cloud/presence context before any async transition or income
    // notification can associate the new profile with the old player's save.
    unawaited(
      _progressSync.selectAccount(accountId: null, protectedPlayerId: null),
    );
    unawaited(_onlineLobby.disconnect());
    if (accountId == null) {
      unawaited(_accountProtection.selectAccount(null));
      if (mounted) setState(() {});
      return;
    }
    if (!_switchingAccount) unawaited(_switchGameAccount());
  }

  void _onProtectionChanged() {
    if (mounted) setState(() {});
    final protectedPlayerId = _accountProtection.state.protectedPlayerId;
    if (_isReady &&
        !_switchingAccount &&
        !_playerSwitchFailed &&
        _accounts.account?.id == _loadedAccountId &&
        protectedPlayerId != _configuredProgressPlayerId) {
      unawaited(_configureProgressSync());
    }
  }

  Future<void> _switchGameAccount() async {
    if (_importFrozen || _switchingAccount || !mounted) return;
    _switchingAccount = true;
    _watchLocalLoad();
    _playerSwitchFailed = false;
    setState(() {});
    try {
      // Only one load owns mutable game/custom services. If selection changes
      // while awaiting, finish that operation, then load the latest selection.
      while (mounted) {
        final accountId = _accounts.account?.id;
        if (accountId == null) break;
        final revision = _accountSelectionRevision;
        bool stillSelected() =>
            mounted && revision == _accountSelectionRevision;
        var stage = 'local progress';
        try {
          final migrateLegacyData =
              _legacyMigrationPending &&
              (_legacyMigrationAccountId == null ||
                  _legacyMigrationAccountId == accountId);
          // An interrupted migration belongs to its original local player;
          // never copy the same legacy progress into a second selection.
          if (migrateLegacyData) _legacyMigrationAccountId = accountId;
          stage = 'local progress';
          await _game.switchAccount(
            accountId,
            migrateLegacySave: migrateLegacyData,
          );
          if (!stillSelected()) continue;
          _progressFailure = null;
          stage = 'local customizations';
          await _loadPlayerCustomizations(accountId, migrateLegacyData);
          if (migrateLegacyData) _legacyMigrationPending = false;
          if (!stillSelected()) continue;
          _loadedAccountId = accountId;
          break;
        } catch (error) {
          if (!stillSelected()) continue;
          debugPrint(
            'Player switch failed during $stage (${error.runtimeType}).',
          );
          // Do not expose a partly loaded player or create a replacement save.
          _loadedAccountId = null;
          _playerSwitchFailed = true;
          if (error is ProgressReadException) _holdProgress(error);
          break;
        }
      }
    } finally {
      _localLoadTimer?.cancel();
      _switchingAccount = false;
      if (mounted) {
        setState(() {});
        if (!_playerSwitchFailed) {
          _syncOnlinePresence();
          _startIdentityCheck();
        }
      }
    }
  }

  void _holdProgress(ProgressReadException error) {
    // Also stop a runtime that loaded valid progress before a later startup
    // dependency failed. Do not flush its in-memory state on this path.
    unawaited(_game.suspendProgressWrites().catchError((Object _) {}));
    _progressFailure = error;
    _loadedAccountId = null;
    _configuredProgressPlayerId = null;
    _configuredProgressAccountId = null;
    unawaited(_accountProtection.selectAccount(null));
    unawaited(
      _progressSync.selectAccount(accountId: null, protectedPlayerId: null),
    );
    unawaited(_onlineLobby.disconnect());
    if (mounted) setState(() {});
  }

  Future<void> _retryProgress() =>
      _rootInitialized ? _switchGameAccount() : _initialize();

  Future<void> _stageBackupRestore(ProgressReadException review) async {
    if (_importFrozen ||
        _startingUp ||
        _switchingAccount ||
        !identical(review, _progressFailure)) {
      throw StateError('Review this backup again');
    }
    _importFrozen = true;
    await _accountProtection.pauseForSaveImport().timeout(
      const Duration(seconds: 20),
    );
    await _progressSync.pauseForSaveImport().timeout(
      const Duration(seconds: 20),
    );
    await _game.suspendProgressWrites().timeout(const Duration(seconds: 20));
    final release = await acquireSaveImportStagingLease();
    try {
      await ProgressRecoveryService().stage(review);
    } finally {
      await release();
    }
  }

  Future<void> _loadPlayerCustomizations(
    String accountId,
    bool migrateLegacyData,
  ) async {
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
  }

  Future<void> _configureProgressSync() {
    if (_importFrozen ||
        _game.saveNeedsAttention ||
        _accountProtection.isChecking ||
        !mounted ||
        !_isReady ||
        _switchingAccount ||
        _playerSwitchFailed ||
        _accounts.account?.id != _loadedAccountId) {
      return Future<void>.value();
    }
    final accountId = _loadedAccountId;
    final protectedPlayerId = _accountProtection.state.protectedPlayerId;
    if (_configuredProgressAccountId == accountId &&
        _configuredProgressPlayerId == protectedPlayerId) {
      return Future.value();
    }
    final cloud = Firebase.apps.isEmpty
        ? null
        : FirebaseProgressRepository(FirebaseFirestore.instance);
    _configuredProgressPlayerId = protectedPlayerId;
    _configuredProgressAccountId = accountId;
    return _progressSync.selectAccount(
      accountId: accountId,
      protectedPlayerId: protectedPlayerId,
      cloud: cloud,
      applyCloud: accountId == null
          ? null
          : (state) => _game.replaceProgressFromCloud(accountId, state),
    );
  }

  void _syncOnlinePresence() {
    final account = _accounts.account;
    if (_importFrozen ||
        _game.saveNeedsAttention ||
        !_isReady ||
        _switchingAccount ||
        _playerSwitchFailed ||
        account == null ||
        account.id != _loadedAccountId) {
      return;
    }
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
    if (_importFrozen || _game.saveNeedsAttention) return;
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
    // Even a background event during failed startup must not save the default
    // in-memory player over an unreadable pre-account save.
    if (_importFrozen || !_isReady) return;
    if (state == AppLifecycleState.resumed &&
        _isReady &&
        !_switchingAccount &&
        !_playerSwitchFailed) {
      final cloud = widget.cloudConnection;
      if (cloud != null && !cloud.isAvailable) unawaited(cloud.connect());
      _startIdentityCheck();
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _game.save();
    }
  }

  @override
  Future<bool> didPopRoute() async => _game.saveNeedsAttention;

  @override
  void dispose() {
    setUnsavedExitGuard(false);
    _localLoadTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _game.removeListener(_onGameChanged);
    _accounts.removeListener(_onAccountsChanged);
    _accountProtection.removeListener(_onProtectionChanged);
    widget.cloudConnection?.removeListener(_onCloudConnectionChanged);
    _preferences.removeListener(_onGameChanged);
    _customSprites.removeListener(_onGameChanged);
    _customEggs.removeListener(_onGameChanged);
    _spriteRating.removeListener(_onGameChanged);
    _referenceOverlay.removeListener(_onGameChanged);
    _audio.removeListener(_onGameChanged);
    _game.onProgressSaved = null;
    _audio.dispose();
    _accountProtection.dispose();
    _progressSync.dispose();
    _onlineLobby.dispose();
    _game.dispose();
    super.dispose();
  }

  bool get _isReady =>
      _rootInitialized &&
      _progressFailure == null &&
      _game.isInitialized &&
      _accounts.isInitialized &&
      _preferences.isInitialized &&
      _customSprites.isInitialized &&
      _customEggs.isInitialized &&
      _spriteRating.isInitialized &&
      _referenceOverlay.isInitialized;

  Future<void> _stageImport(SaveImportPreview preview) async {
    if (_game.saveNeedsAttention) {
      throw StateError('Save or export held progress before importing');
    }
    final recoveringProgress =
        _progressFailure != null && !_startingUp && !_switchingAccount;
    final recoveringAccounts =
        _accountStartupFailure != null &&
        !_checkingAccounts &&
        !_accounts.isInitialized &&
        !_game.isInitialized;
    if (_importFrozen ||
        (!_isReady && !recoveringAccounts && !recoveringProgress) ||
        _switchingAccount ||
        (_playerSwitchFailed && !recoveringProgress)) {
      throw const SaveTransferException(
        'The game must restart before importing.',
      );
    }
    // From this point the confirmation stays modal and permits only restart,
    // including on failure. No old runtime resumes over a pending import.
    _importFrozen = true;
    if (!recoveringAccounts) {
      await _accountProtection.pauseForSaveImport().timeout(
        const Duration(seconds: 20),
      );
      await _progressSync.pauseForSaveImport().timeout(
        const Duration(seconds: 20),
      );
      if (recoveringProgress) {
        await _game.suspendProgressWrites().timeout(
          const Duration(seconds: 20),
        );
      } else {
        await _game.pauseForSaveImport().timeout(const Duration(seconds: 20));
      }
    }
    unawaited(_onlineLobby.disconnect());
    final release = await acquireSaveImportStagingLease();
    try {
      await SaveTransferService().stageImport(preview);
    } finally {
      await release();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _isReady
        ? _preferences.selectedTheme
        : BackgroundThemes.defaultTheme;

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Nestarium',
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
        Widget guardProgress(Widget surface) => Stack(
          fit: StackFit.expand,
          children: [
            Offstage(
              offstage: _game.saveNeedsAttention,
              child: TickerMode(
                enabled: !_game.saveNeedsAttention,
                child: ExcludeFocus(
                  excluding: _game.saveNeedsAttention,
                  child: surface,
                ),
              ),
            ),
            if (_game.saveNeedsAttention)
              Positioned.fill(
                child: UnsavedProgressScreen(
                  game: _game,
                  account: _accounts.accounts
                      .where((a) => a.id == _game.activeAccountId)
                      .firstOrNull,
                  onRetry: () async {
                    await _game.retryProgressSave();
                    if (!mounted || _game.saveNeedsAttention) return;
                    if (_accounts.account?.id != _loadedAccountId) {
                      _onAccountsChanged();
                    } else {
                      _startIdentityCheck();
                    }
                  },
                ),
              ),
          ],
        );
        final content = CloudConnectionScope(
          notifier: widget.cloudConnection,
          child: SaveImportScope(
            stageImport: _stageImport,
            child: child ?? const SizedBox.shrink(),
          ),
        );
        if (!_isReady ||
            (_switchingAccount || _playerSwitchFailed) &&
                !_game.saveNeedsAttention) {
          return PortraitAppShell(
            child: guardProgress(
              AppThemeBackground(theme: theme, child: content),
            ),
          );
        }
        return PortraitAppShell(
          child: guardProgress(
            AppThemeBackground(
              theme: theme,
              child: AudioScope(
                audio: _audio,
                child: AudioUnlockListener(
                  audio: _audio,
                  child: AccountScope(
                    accounts: _accounts,
                    child: AccountProtectionScope(
                      protection: _accountProtection,
                      child: ProgressSyncScope(
                        sync: _progressSync,
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
              ),
            ),
          ),
        );
      },
      home: _accountStartupFailure != null
          ? SavedPlayerRecoveryScreen(
              failure: _accountStartupFailure!,
              onRetry: _initialize,
              stageImport: _stageImport,
            )
          : _progressFailure != null
          ? SavedPlayerRecoveryScreen(
              failure: AccountStartupFailure.storageUnavailable,
              progressFailure: _progressFailure,
              onRetry: _retryProgress,
              stageImport: _stageImport,
              stageBackup: _stageBackupRestore,
              onChoosePlayer: _accounts.chooseAnotherAccount,
            )
          : _accounts.isInitialized && !_accounts.hasAccount && !_startingUp
          ? AccountOnboardingScreen(accounts: _accounts, game: _game)
          : _playerSwitchFailed
          ? _PlayerSwitchFailureScreen(
              onRetry: () => unawaited(_switchGameAccount()),
              onChoosePlayer: _accounts.chooseAnotherAccount,
            )
          : !_isReady || _switchingAccount
          ? _LoadingScreen(slow: _localLoadSlow)
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

class _PlayerSwitchFailureScreen extends StatelessWidget {
  const _PlayerSwitchFailureScreen({
    required this.onRetry,
    required this.onChoosePlayer,
  });

  final VoidCallback onRetry;
  final VoidCallback onChoosePlayer;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 40),
              const SizedBox(height: 16),
              Text(
                'Couldn’t open this player',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Your saved players have not been removed. Try again or '
                'return to your local players.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
                onPressed: onChoosePlayer,
                icon: const Icon(Icons.people_outline),
                label: const Text('Choose local player'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({this.slow = false});
  final bool slow;

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
              child: SingleChildScrollView(
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
                      semanticLabel: 'Nestarium',
                    ),
                    const SizedBox(height: 24),
                    const SizedBox.square(
                      dimension: 30,
                      child: CircularProgressIndicator(
                        color: Color(0xFFFFC247),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      slow
                          ? 'Local player is taking longer to load.'
                          : 'Loading local player…',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (slow) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Keep app/browser data. This local check must finish before play can start. Do not reset your save to fix a loading delay.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
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
