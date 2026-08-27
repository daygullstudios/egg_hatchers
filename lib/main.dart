import 'dart:async';

import 'package:flutter/material.dart';

import 'models/background_theme.dart';
import 'screens/account_onboarding_screen.dart';
import 'screens/hatchery_screen.dart';
import 'services/account_service.dart';
import 'services/audio_service.dart';
import 'services/custom_egg_service.dart';
import 'services/custom_sprite_service.dart';
import 'services/game_service.dart';
import 'services/preferences_service.dart';
import 'services/sprite_rating_service.dart';
import 'services/sprite_reference_overlay_service.dart';
import 'widgets/animal_sprite_theme_scope.dart';
import 'widgets/account_scope.dart';
import 'widgets/app_theme_background.dart';
import 'widgets/audio_scope.dart';
import 'widgets/tutorial_host.dart';
import 'navigation/app_page_route.dart';

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
  final PreferencesService _preferences = PreferencesService();
  final CustomSpriteService _customSprites = CustomSpriteService();
  final CustomEggService _customEggs = CustomEggService();
  final SpriteRatingService _spriteRating = SpriteRatingService();
  final SpriteReferenceOverlayService _referenceOverlay =
      SpriteReferenceOverlayService();
  final AudioService _audio = AudioService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
    _game.addListener(_onGameChanged);
    _accounts.addListener(_onGameChanged);
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
      _game.initialize(),
      _accounts.initialize(),
      _preferences.initialize(),
      _customSprites.initialize(),
      _customEggs.initialize(),
      _spriteRating.initialize(),
      _referenceOverlay.initialize(),
    ]);
    if (mounted) setState(() {});
  }

  void _onGameChanged() {
    if (mounted) setState(() {});
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
    _accounts.removeListener(_onGameChanged);
    _preferences.removeListener(_onGameChanged);
    _customSprites.removeListener(_onGameChanged);
    _customEggs.removeListener(_onGameChanged);
    _spriteRating.removeListener(_onGameChanged);
    _referenceOverlay.removeListener(_onGameChanged);
    _audio.removeListener(_onGameChanged);
    _audio.dispose();
    _game.dispose();
    super.dispose();
  }

  bool get _isReady =>
      _game.isInitialized &&
      _accounts.isInitialized &&
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
        if (!_isReady) {
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
        );
      },
      home: !_isReady
          ? const _LoadingScreen()
          : !_accounts.hasAccount
          ? AccountOnboardingScreen(accounts: _accounts)
          : HatcheryScreen(
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
