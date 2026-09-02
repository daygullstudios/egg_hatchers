import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/animal_sprite_theme.dart';
import '../models/background_theme.dart';

/// Persists visual preferences separately from gameplay save data.
class PreferencesService extends ChangeNotifier {
  static const _backgroundKey = 'selectedBackgroundThemeId';
  static const _animalSpriteThemeKey = 'animalSpriteTheme';
  static const _showBattleBackgroundsKey = 'showBattleBackgrounds';
  static const _reducedBattleEffectsKey = 'reducedBattleEffects';
  static const _hapticsEnabledKey = 'hapticsEnabled';

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
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_backgroundKey);
    _selectedTheme = savedId != null
        ? BackgroundThemes.byId(savedId)
        : BackgroundThemes.defaultTheme;
    _animalSpriteTheme = AnimalSpriteThemes.byId(
      prefs.getString(_animalSpriteThemeKey),
    );
    _showBattleBackgrounds = prefs.getBool(_showBattleBackgroundsKey) ?? true;
    _reducedBattleEffects = prefs.getBool(_reducedBattleEffectsKey) ?? false;
    _hapticsEnabled = prefs.getBool(_hapticsEnabledKey) ?? true;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setBackgroundTheme(BackgroundTheme theme) async {
    if (_selectedTheme.id == theme.id) return;

    _selectedTheme = theme;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backgroundKey, theme.id);
  }

  Future<void> setAnimalSpriteTheme(AnimalSpriteTheme theme) async {
    if (_animalSpriteTheme.id == theme.id) return;

    _animalSpriteTheme = theme;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_animalSpriteThemeKey, theme.id);
  }

  Future<void> setShowBattleBackgrounds(bool value) async {
    if (_showBattleBackgrounds == value) return;

    _showBattleBackgrounds = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showBattleBackgroundsKey, value);
  }

  Future<void> setReducedBattleEffects(bool value) async {
    if (_reducedBattleEffects == value) return;

    _reducedBattleEffects = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reducedBattleEffectsKey, value);
  }

  Future<void> setHapticsEnabled(bool value) async {
    if (_hapticsEnabled == value) return;

    _hapticsEnabled = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsEnabledKey, value);
  }
}
