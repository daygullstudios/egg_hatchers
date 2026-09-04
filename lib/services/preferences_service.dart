import 'package:flutter/foundation.dart';
import '../models/animal_sprite_theme.dart';
import '../models/background_theme.dart';
import 'device_settings_store.dart';

/// Persists visual preferences separately from gameplay save data.
class PreferencesService extends ChangeNotifier {
  PreferencesService({DeviceSettingsStore? store})
    : _store = store ?? const DeviceSettingsStore();

  final DeviceSettingsStore _store;

  BackgroundTheme _selectedTheme = BackgroundThemes.defaultTheme;
  AnimalSpriteTheme _animalSpriteTheme = AnimalSpriteThemes.defaultTheme;
  var _showBattleBackgrounds = true;
  var _reducedBattleEffects = false;
  var _hapticsEnabled = true;
  bool _isInitialized = false;

  BackgroundTheme get selectedTheme => _selectedTheme;
  AnimalSpriteTheme get animalSpriteTheme => _animalSpriteTheme;
  bool get showBattleBackgrounds => _showBattleBackgrounds;
  bool get reducedBattleEffects => _reducedBattleEffects;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    final settings = await _store.read();
    final savedId = settings.backgroundThemeId;
    _selectedTheme = savedId != null
        ? BackgroundThemes.byId(savedId)
        : BackgroundThemes.defaultTheme;
    _animalSpriteTheme = AnimalSpriteThemes.byId(settings.animalSpriteThemeId);
    _showBattleBackgrounds = settings.showBattleBackgrounds;
    _reducedBattleEffects = settings.reducedBattleEffects;
    _hapticsEnabled = settings.hapticsEnabled;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setBackgroundTheme(BackgroundTheme theme) async {
    if (_selectedTheme.id == theme.id) return;

    _selectedTheme = theme;
    notifyListeners();

    await _store.writeBackgroundTheme(theme.id);
  }

  Future<void> setAnimalSpriteTheme(AnimalSpriteTheme theme) async {
    if (_animalSpriteTheme.id == theme.id) return;

    _animalSpriteTheme = theme;
    notifyListeners();

    await _store.writeAnimalSpriteTheme(theme.id);
  }

  Future<void> setShowBattleBackgrounds(bool value) async {
    if (_showBattleBackgrounds == value) return;

    _showBattleBackgrounds = value;
    notifyListeners();

    await _store.writeShowBattleBackgrounds(value);
  }

  Future<void> setReducedBattleEffects(bool value) async {
    if (_reducedBattleEffects == value) return;

    _reducedBattleEffects = value;
    notifyListeners();

    await _store.writeReducedBattleEffects(value);
  }

  Future<void> setHapticsEnabled(bool value) async {
    if (_hapticsEnabled == value) return;

    _hapticsEnabled = value;
    notifyListeners();

    await _store.writeHapticsEnabled(value);
  }
}
