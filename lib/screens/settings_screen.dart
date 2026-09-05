import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/realistic_animal_sprites.dart';
import '../models/animal_sprite_theme.dart';
import '../models/account_protection_state.dart';
import '../models/background_theme.dart';
import '../models/player_account.dart';
import '../navigation/app_page_route.dart';
import '../services/custom_sprite_service.dart';
import '../services/game_service.dart';
import '../services/preferences_service.dart';
import '../services/save_transfer_file.dart';
import '../services/save_transfer_service.dart';
import '../services/sprite_rating_service.dart';
import '../services/sprite_reference_overlay_service.dart';
import '../services/tutorial_service.dart';
import '../theme/game_theme.dart';
import '../utils/snackbar_utils.dart';
import '../utils/ui_sound.dart';
import '../widgets/audio_scope.dart';
import '../widgets/account_scope.dart';
import '../widgets/account_protection_scope.dart';
import '../widgets/audio_settings_card.dart';
import '../widgets/game_background.dart';
import '../widgets/phone_width_layout.dart';
import '../widgets/retro_pixel_animal_sprite.dart';
import 'custom_sprites_screen.dart';

/// Player settings: tutorials, visuals, audio, and custom animal entry points.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
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

  static final SaveTransferService _saveTransfer = SaveTransferService();

  Future<void> _replayBasics(
    BuildContext context,
    BackgroundTheme theme,
  ) async {
    final tutorial = TutorialService.instance;
    tutorial.attach(game: game, theme: theme);
    await returnToHatcheryWithTransition(context, theme: theme);
    tutorial.showWelcome(isReplay: true);
  }

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

  void _switchAccount(BuildContext context) {
    final accounts = AccountScope.of(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    accounts.chooseAnotherAccount();
  }

  Future<void> _deleteAccount(
    BuildContext context,
    PlayerAccount account,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: Text(
          'Delete ${account.displayName} and all progress saved for this account? This cannot be undone.',
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(dialogContext, false),
            icon: const Icon(Icons.close_rounded),
            label: const Text('CANCEL'),
          ),
          FilledButton.icon(
            key: const ValueKey('settings-confirm-delete-account'),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_forever),
            label: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final accounts = AccountScope.of(context);
    await game.deleteAccountSave(account.id);
    await accounts.deleteAccount(account.id);
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _exportSave(BuildContext context) async {
    try {
      await game.save();
      if (!context.mounted) return;
      final accountId = AccountScope.of(context).account?.id;
      final contents = await _saveTransfer.exportSave(
        activeAccountId: accountId,
      );
      final date = DateTime.now().toIso8601String().split('T').first;
      await downloadSaveFile(contents, 'egg-hatchers-save-$date.json');
      if (context.mounted) {
        UiSound.confirm(context);
        showGameSnackBar(
          context,
          message: 'Save exported successfully!',
          backgroundColor: preferences.selectedTheme.primaryColor,
        );
      }
    } catch (error) {
      if (context.mounted) {
        showGameSnackBar(
          context,
          message: 'Save export failed: $error',
          backgroundColor: Colors.redAccent,
        );
      }
    }
  }

  Future<void> _copySave(BuildContext context) async {
    try {
      await game.save();
      if (!context.mounted) return;
      final contents = await _saveTransfer.exportSave(
        activeAccountId: AccountScope.of(context).account?.id,
      );
      await copySaveText(contents);
      if (context.mounted) {
        UiSound.confirm(context);
        showGameSnackBar(
          context,
          message: 'Save code copied!',
          backgroundColor: preferences.selectedTheme.primaryColor,
        );
      }
    } catch (error) {
      if (context.mounted) {
        showGameSnackBar(
          context,
          message: 'Could not copy save: $error',
          backgroundColor: Colors.redAccent,
        );
      }
    }
  }

  Future<void> _importSave(BuildContext context) async {
    try {
      final contents = await pickSaveFile();
      if (contents == null || !context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Replace local save?'),
          content: const Text(
            'This will replace every Egg Hatchers account, all progress, settings, custom eggs, and custom animals on this device.',
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(dialogContext, false),
              icon: const Icon(Icons.close_rounded),
              label: const Text('CANCEL'),
            ),
            FilledButton.icon(
              key: const ValueKey('settings-confirm-import-save'),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.restore_rounded),
              label: const Text('IMPORT'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;

      final accountCount = await _saveTransfer.importSave(contents);
      if (!context.mounted) return;
      UiSound.confirm(context);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Import complete'),
          content: Text(
            accountCount == 1
                ? '1 account was restored. Restart the game to load it.'
                : '$accountCount accounts were restored. Restart the game to load them.',
          ),
          actions: [
            FilledButton.icon(
              key: const ValueKey('settings-restart-after-import'),
              onPressed: reloadAfterSaveImport,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('RESTART GAME'),
            ),
          ],
        ),
      );
    } on SaveTransferException catch (error) {
      if (context.mounted) {
        showGameSnackBar(
          context,
          message: error.message,
          backgroundColor: Colors.redAccent,
        );
      }
    } catch (error) {
      if (context.mounted) {
        showGameSnackBar(
          context,
          message: 'Save import failed: $error',
          backgroundColor: Colors.redAccent,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: preferences,
      builder: (context, _) {
        final selected = preferences.selectedTheme;
        final selectedAnimalTheme = preferences.animalSpriteTheme;
        final account = AccountScope.of(context).account;
        final protection =
            AccountProtectionScope.maybeOf(context)?.state ??
            const AccountProtectionState.localOnly();

        return ReturnToHatcheryPopScope(
          theme: selected,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: PhoneWidthAppBar(
              title: 'Settings',
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
                    if (account != null) ...[
                      _SettingsSection(
                        theme: selected,
                        title: 'Account',
                        child: _AccountSettings(
                          account: account,
                          protection: protection,
                          theme: selected,
                          onSwitch: () => _switchAccount(context),
                          onDelete: () => _deleteAccount(context, account),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _SettingsSection(
                      theme: selected,
                      title: 'Save Transfer',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Move every local account and its progress to another computer.',
                            style: TextStyle(
                              color: selected.cardTextSecondaryColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            key: const ValueKey('settings-export-save'),
                            onPressed: kIsWeb
                                ? () => _exportSave(context)
                                : null,
                            icon: const Icon(Icons.download_rounded),
                            label: const Text(
                              'Export Save',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: GameTheme.filledButton(
                              selected,
                              color: selected.secondaryColor,
                              height: 48,
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            key: const ValueKey('settings-copy-save'),
                            onPressed: kIsWeb ? () => _copySave(context) : null,
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text(
                              'Copy Save Code',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: selected.primaryColor,
                              minimumSize: const Size.fromHeight(46),
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            key: const ValueKey('settings-import-save'),
                            onPressed: kIsWeb
                                ? () => _importSave(context)
                                : null,
                            icon: const Icon(Icons.upload_file_rounded),
                            label: const Text(
                              'Import Save',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: selected.primaryColor,
                              minimumSize: const Size.fromHeight(46),
                            ),
                          ),
                          if (!kIsWeb) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Save transfer is currently available in the web game.',
                              style: TextStyle(
                                color: selected.cardTextSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SettingsSection(
                      theme: selected,
                      title: 'Tutorials',
                      child: FilledButton.icon(
                        onPressed: () => _replayBasics(context, selected),
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text(
                          'Replay Basic Tutorial',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: GameTheme.filledButton(
                          selected,
                          color: selected.secondaryColor,
                          height: 52,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AudioSettingsCard(
                      theme: selected,
                      audio: AudioScope.of(context),
                    ),
                    const SizedBox(height: 14),
                    _SettingsSection(
                      theme: selected,
                      title: 'Visual Effects',
                      child: Column(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: SwitchListTile.adaptive(
                              key: const ValueKey(
                                'settings-reduced-battle-effects',
                              ),
                              contentPadding: EdgeInsets.zero,
                              value: preferences.reducedBattleEffects,
                              onChanged: preferences.setReducedBattleEffects,
                              title: Text(
                                'Reduced Battle Effects',
                                style: TextStyle(
                                  color: selected.cardTextPrimaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Removes screen shake and softens bright flashes',
                                style: TextStyle(
                                  color: selected.cardTextSecondaryColor,
                                ),
                              ),
                            ),
                          ),
                          Divider(color: selected.cardBorderColor),
                          Material(
                            color: Colors.transparent,
                            child: SwitchListTile.adaptive(
                              key: const ValueKey('settings-haptics-enabled'),
                              contentPadding: EdgeInsets.zero,
                              value: preferences.hapticsEnabled,
                              onChanged: preferences.setHapticsEnabled,
                              title: Text(
                                'Haptic Feedback',
                                style: TextStyle(
                                  color: selected.cardTextPrimaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Adds vibration feedback to battle actions',
                                style: TextStyle(
                                  color: selected.cardTextSecondaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SettingsSection(
                      theme: selected,
                      title: 'Backgrounds',
                      child: Column(
                        children: [
                          for (var i = 0; i < BackgroundThemes.all.length; i++)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: i == BackgroundThemes.all.length - 1
                                    ? 0
                                    : 10,
                              ),
                              child: _ThemeOptionCard(
                                activeTheme: selected,
                                theme: BackgroundThemes.all[i],
                                isSelected:
                                    BackgroundThemes.all[i].id == selected.id,
                                onTap: () => _selectTheme(
                                  context,
                                  BackgroundThemes.all[i],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SettingsSection(
                      theme: selected,
                      title: 'Animal Style',
                      child: Column(
                        children: [
                          for (
                            var i = 0;
                            i < AnimalSpriteThemes.all.length;
                            i++
                          )
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: i == AnimalSpriteThemes.all.length - 1
                                    ? 0
                                    : 10,
                              ),
                              child: _AnimalSpriteThemeCard(
                                activeTheme: selected,
                                animalTheme: AnimalSpriteThemes.all[i],
                                isSelected:
                                    AnimalSpriteThemes.all[i].id ==
                                    selectedAnimalTheme.id,
                                onTap: () => _selectAnimalSpriteTheme(
                                  context,
                                  AnimalSpriteThemes.all[i],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
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

class _AccountSettings extends StatelessWidget {
  const _AccountSettings({
    required this.account,
    required this.protection,
    required this.theme,
    required this.onSwitch,
    required this.onDelete,
  });

  final PlayerAccount account;
  final AccountProtectionState protection;
  final BackgroundTheme theme;
  final VoidCallback onSwitch;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: account.avatarColor,
              child: Text(
                account.displayName.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.cardTextPrimaryColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    account.identityLabel,
                    style: TextStyle(
                      color: theme.cardTextSecondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          key: const ValueKey('settings-account-protection-status'),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.scaffoldColor.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.cardBorderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                protection.isProtected
                    ? Icons.verified_user_rounded
                    : Icons.phonelink_lock_outlined,
                size: 20,
                color: protection.isProtected
                    ? Colors.greenAccent.shade400
                    : theme.primaryColor,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      protection.label,
                      style: TextStyle(
                        color: theme.cardTextPrimaryColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      protection.message ??
                          'Progress protection status is unavailable.',
                      style: TextStyle(
                        color: theme.cardTextSecondaryColor,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const ValueKey('settings-switch-account-button'),
          onPressed: onSwitch,
          icon: const Icon(Icons.switch_account),
          label: const Text(
            'Switch Account',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: GameTheme.filledButton(
            theme,
            color: theme.secondaryColor,
            height: 48,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const ValueKey('settings-delete-account-button'),
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          label: const Text(
            'Delete Account',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            minimumSize: const Size.fromHeight(46),
          ),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.theme,
    required this.title,
    required this.child,
  });

  final BackgroundTheme theme;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: GameTheme.cardDecoration(theme),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: GameTheme.sectionTitle(theme, size: 18)),
          const SizedBox(height: 12),
          child,
        ],
      ),
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
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
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
                          errorBuilder: (_, _, _) => const Text(
                            'Chicken',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animalTheme.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: activeTheme.cardTextPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      animalTheme.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: activeTheme.cardTextSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: activeTheme.primaryColor,
                  size: 26,
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
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: theme.gradient,
                  border: Border.all(
                    color: theme.cardBorderColor.withValues(alpha: 0.7),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withValues(alpha: 0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      theme.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: activeTheme.cardTextPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      theme.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: activeTheme.cardTextSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: theme.primaryColor,
                  size: 26,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
