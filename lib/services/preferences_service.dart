import 'package:flutter/foundation.dart';
import '../models/animal_sprite_theme.dart';
import '../models/background_theme.dart';
import 'device_settings_store.dart';

/// Persists visual preferences separately from gameplay save data.
class PreferencesService extends ChangeNotifier {
  PreferencesService({DeviceSettingsStore? store})
    : _store = store ?? DeviceSettingsStore();

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
  bool get hasUnsavedSettings => _store.hasUnsavedChanges || _store.isSaving;

  Future<void> initialize() async {
    final settings = await _store.read(includePending: true);
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

  Future<bool> setBackgroundTheme(BackgroundTheme theme) async {
    _selectedTheme = theme;
    notifyListeners();

    return await _store.writeBackgroundTheme(theme.id) &&
        _selectedTheme.id == theme.id;
  }

  Future<bool> setAnimalSpriteTheme(AnimalSpriteTheme theme) async {
    _animalSpriteTheme = theme;
    notifyListeners();

    return await _store.writeAnimalSpriteTheme(theme.id) &&
        _animalSpriteTheme.id == theme.id;
  }

  Future<bool> setShowBattleBackgrounds(bool value) async {
    _showBattleBackgrounds = value;
    notifyListeners();

    return _store.writeShowBattleBackgrounds(value);
  }

  Future<bool> setReducedBattleEffects(bool value) async {
    _reducedBattleEffects = value;
    notifyListeners();

    return _store.writeReducedBattleEffects(value);
  }

  Future<bool> setHapticsEnabled(bool value) async {
    _hapticsEnabled = value;
    notifyListeners();

    return _store.writeHapticsEnabled(value);
  }
}
