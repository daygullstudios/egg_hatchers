import 'package:flutter/material.dart';

import '../data/realistic_animal_sprites.dart';
import '../models/animal_sprite_theme.dart';
import '../models/background_theme.dart';
import '../navigation/app_page_route.dart';
import '../services/custom_sprite_service.dart';
import '../services/game_service.dart';
import '../services/preferences_service.dart';
import '../services/sprite_rating_service.dart';
import '../services/sprite_reference_overlay_service.dart';
import '../theme/game_theme.dart';
import '../utils/snackbar_utils.dart';
import '../utils/ui_sound.dart';
import '../widgets/audio_settings_card.dart';
import '../widgets/game_background.dart';
import '../widgets/phone_width_layout.dart';
import '../widgets/audio_scope.dart';
import '../widgets/retro_pixel_animal_sprite.dart';
import 'custom_sprites_screen.dart';

/// Lets the player pick and preview background themes.
class BackgroundsScreen extends StatelessWidget {
  const BackgroundsScreen({
    super.key,
    required this.preferences,
    required this.customSprites,
    required this.game,
    required this.spriteRating,
    required this.referenceOverlay,
  });

  final PreferencesService preferences;
  final CustomSpriteService customSprites;
  final GameService game;
  final SpriteRatingService spriteRating;
  final SpriteReferenceOverlayService referenceOverlay;

  Future<void> _selectTheme(BuildContext context, BackgroundTheme theme) async {
    await preferences.setBackgroundTheme(theme);
    if (context.mounted) {
      UiSound.confirm(context);
      showGameSnackBar(
        context,
        message: 'Background changed to ${theme.name}!',
        backgroundColor: theme.primaryColor,
      );
    }
  }

  Future<void> _selectAnimalSpriteTheme(
    BuildContext context,
    AnimalSpriteTheme theme,
  ) async {
    await preferences.setAnimalSpriteTheme(theme);
    if (context.mounted) {
      UiSound.confirm(context);
      showGameSnackBar(
        context,
        message: 'Animal style changed to ${theme.name}!',
        backgroundColor: preferences.selectedTheme.primaryColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: preferences,
      builder: (context, _) {
        final selected = preferences.selectedTheme;
        final selectedAnimalTheme = preferences.animalSpriteTheme;

        return ReturnToHatcheryPopScope(
          theme: selected,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: PhoneWidthAppBar(
              title: '🎨 Backgrounds',
              titleStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
              backgroundColor: selected.appBarColor,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              leading: ReturnToHatcheryBackButton(
                theme: selected,
                color: Colors.white,
              ),
            ),
            body: GameBackground(
              theme: selected,
              child: PhoneWidthLayout(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Text(
                      'Pick a cozy background for your hatchery!',
                      style: GameTheme.sectionTitle(selected, size: 16),
                    ),
                    const SizedBox(height: 16),
                    for (final theme in BackgroundThemes.all) ...[
                      _ThemeOptionCard(
                        activeTheme: selected,
                        theme: theme,
                        isSelected: theme.id == selected.id,
                        onTap: () => _selectTheme(context, theme),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 12),
                    AudioSettingsCard(
                      theme: selected,
                      audio: AudioScope.of(context),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Animal Style',
                      style: GameTheme.sectionTitle(selected, size: 18),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose how built-in animals look. Custom animals always override this.',
                      style: TextStyle(
                        fontSize: 13,
                        color: selected.cardTextSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final animalTheme in AnimalSpriteThemes.all) ...[
                      _AnimalSpriteThemeCard(
                        activeTheme: selected,
                        animalTheme: animalTheme,
                        isSelected: animalTheme.id == selectedAnimalTheme.id,
                        onTap: () =>
                            _selectAnimalSpriteTheme(context, animalTheme),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => pushThemedAppRoute(
                          context,
                          theme: selected,
                          settings: const RouteSettings(
                            name: kCustomSpritesRouteName,
                          ),
                          builder: (_) => CustomSpritesScreen(
                            preferences: preferences,
                            customSprites: customSprites,
                            game: game,
                            spriteRating: spriteRating,
                            referenceOverlay: referenceOverlay,
                          ),
                        ),
                        icon: const Icon(Icons.brush_rounded),
                        label: const Text(
                          'Custom Animals',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: GameTheme.filledButton(
                          selected,
                          color: selected.secondaryColor,
                          height: 52,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimalSpriteThemeCard extends StatelessWidget {
  const _AnimalSpriteThemeCard({
    required this.activeTheme,
    required this.animalTheme,
    required this.isSelected,
    required this.onTap,
  });

  final BackgroundTheme activeTheme;
  final AnimalSpriteTheme animalTheme;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const previewAnimalId = 'chicken';
    const previewSize = 48.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GameTheme.cardRadius),
        child: Container(
          decoration: GameTheme.cardDecoration(
            activeTheme,
            borderColor: isSelected
                ? activeTheme.primaryColor
                : activeTheme.cardBorderColor,
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withValues(alpha: 0.85),
                  border: Border.all(
                    color: activeTheme.cardBorderColor.withValues(alpha: 0.7),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: animalTheme.id == AnimalSpriteThemes.retroPixel.id
                      ? RetroPixelAnimalSprite(
                          animalId: previewAnimalId,
                          size: previewSize,
                        )
                      : Image.asset(
                          animalTheme.id == AnimalSpriteThemes.realistic.id
                              ? RealisticAnimalSprites.assetPathFor(
                                  previewAnimalId,
                                )!
                              : 'assets/images/animals/chicken.png',
                          width: previewSize,
                          height: previewSize,
                          fit: BoxFit.contain,
                          filterQuality:
                              animalTheme.id == AnimalSpriteThemes.realistic.id
                              ? FilterQuality.high
                              : FilterQuality.none,
                          errorBuilder: (_, _, _) =>
                              const Text('🐔', style: TextStyle(fontSize: 32)),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animalTheme.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: activeTheme.cardTextPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      animalTheme.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: activeTheme.cardTextSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: activeTheme.primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: activeTheme.primaryColor),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: activeTheme.primaryColor,
                    size: 22,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.activeTheme,
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  final BackgroundTheme activeTheme;
  final BackgroundTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GameTheme.cardRadius),
        child: Container(
          decoration: GameTheme.cardDecoration(
            activeTheme,
            borderColor: isSelected
                ? theme.primaryColor
                : theme.cardBorderColor,
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: theme.gradient,
                  border: Border.all(
                    color: theme.cardBorderColor.withValues(alpha: 0.7),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      theme.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: activeTheme.cardTextPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      theme.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: activeTheme.cardTextSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.primaryColor),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: theme.primaryColor,
                    size: 22,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
