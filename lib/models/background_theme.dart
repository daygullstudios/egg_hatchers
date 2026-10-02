import 'package:flutter/material.dart';

/// A selectable background gradient theme with matching UI colors.
class BackgroundTheme {
  const BackgroundTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.colors,
    required this.cardColor,
    required this.cardBorderColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.appBarColor,
    required this.panelColor,
    required this.panelAccentColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
    required this.cardTextPrimaryColor,
    required this.cardTextSecondaryColor,
    required this.disabledColor,
    this.isDark = false,
  });

  final String id;
  final String name;
  final String description;
  final List<Color> colors;
  final Color cardColor;
  final Color cardBorderColor;
  final Color primaryColor;
  final Color secondaryColor;
  final Color appBarColor;
  final Color panelColor;
  final Color panelAccentColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;
  final Color cardTextPrimaryColor;
  final Color cardTextSecondaryColor;
  final Color disabledColor;
  final bool isDark;

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: colors,
  );

  Color get appBarForegroundColor => readableOn(appBarColor);
  Color get primaryForegroundColor => readableOn(primaryColor);
  Color get secondaryForegroundColor => readableOn(secondaryColor);
  Color get previewStart => colors.first;
  Color get previewEnd => colors.last;

  Color get scaffoldColor => colors.first;

  static Color readableOn(Color background) {
    const light = Colors.white;
    const dark = Colors.black;
    return _contrastRatio(background, light) >= _contrastRatio(background, dark)
        ? light
        : dark;
  }
}

double _contrastRatio(Color a, Color b) {
  final aLum = a.computeLuminance();
  final bLum = b.computeLuminance();
  final light = aLum > bLum ? aLum : bLum;
  final dark = aLum > bLum ? bLum : aLum;
  return (light + 0.05) / (dark + 0.05);
}

/// All available background themes.
class BackgroundThemes {
  BackgroundThemes._();

  static const hatcheryDefault = BackgroundTheme(
    id: 'hatchery_default',
    name: 'Hatchery Default',
    description: 'Soft pastel egg hatchery look',
    colors: [Color(0xFFFFF3C4), Color(0xFFFFF8F0), Color(0xFFFFE8D6)],
    cardColor: Color(0xFFFFFFF5),
    cardBorderColor: Color(0xFFFFB74D),
    primaryColor: Color(0xFF4DB6AC),
    secondaryColor: Color(0xFFFFB74D),
    appBarColor: Color(0xFF4DB6AC),
    panelColor: Color(0xFFFFFFF0),
    panelAccentColor: Color(0xFFFFB300),
    textPrimaryColor: Color(0xFF5D4037),
    textSecondaryColor: Color(0xFF795548),
    cardTextPrimaryColor: Color(0xFF5D4037),
    cardTextSecondaryColor: Color(0xFF795548),
    disabledColor: Color(0xFF9E9E9E),
  );

  static const sunnyMeadow = BackgroundTheme(
    id: 'sunny_meadow',
    name: 'Sunny Meadow',
    description: 'Light green and yellow outdoor vibes',
    colors: [Color(0xFFE8F5E9), Color(0xFFFFF9C4), Color(0xFFC8E6C9)],
    cardColor: Color(0xFFFFFFF8),
    cardBorderColor: Color(0xFF66BB6A),
    primaryColor: Color(0xFF43A047),
    secondaryColor: Color(0xFFFFCA28),
    appBarColor: Color(0xFF43A047),
    panelColor: Color(0xFFFFFFF5),
    panelAccentColor: Color(0xFF81C784),
    textPrimaryColor: Color(0xFF33691E),
    textSecondaryColor: Color(0xFF558B2F),
    cardTextPrimaryColor: Color(0xFF33691E),
    cardTextSecondaryColor: Color(0xFF558B2F),
    disabledColor: Color(0xFF9E9E9E),
  );

  static const candyClouds = BackgroundTheme(
    id: 'candy_clouds',
    name: 'Candy Clouds',
    description: 'Pink, purple, and sky-blue fun',
    colors: [Color(0xFFFCE4EC), Color(0xFFE1BEE7), Color(0xFFE3F2FD)],
    cardColor: Color(0xFFFFFFF8),
    cardBorderColor: Color(0xFFEC407A),
    primaryColor: Color(0xFFAB47BC),
    secondaryColor: Color(0xFFEC407A),
    appBarColor: Color(0xFFAB47BC),
    panelColor: Color(0xFFFFFFF5),
    panelAccentColor: Color(0xFFF06292),
    textPrimaryColor: Color(0xFF6A1B5D),
    textSecondaryColor: Color(0xFF8E24AA),
    cardTextPrimaryColor: Color(0xFF6A1B5D),
    cardTextSecondaryColor: Color(0xFF8E24AA),
    disabledColor: Color(0xFF9E9E9E),
  );

  static const oceanBreeze = BackgroundTheme(
    id: 'ocean_breeze',
    name: 'Ocean Breeze',
    description: 'Cool light blue and teal waves',
    colors: [Color(0xFFE1F5FE), Color(0xFFB2EBF2), Color(0xFF80DEEA)],
    cardColor: Color(0xFFFFFFF8),
    cardBorderColor: Color(0xFF26C6DA),
    primaryColor: Color(0xFF00ACC1),
    secondaryColor: Color(0xFF29B6F6),
    appBarColor: Color(0xFF00ACC1),
    panelColor: Color(0xFFFFFFF5),
    panelAccentColor: Color(0xFF4DD0E1),
    textPrimaryColor: Color(0xFF006064),
    textSecondaryColor: Color(0xFF00838F),
    cardTextPrimaryColor: Color(0xFF006064),
    cardTextSecondaryColor: Color(0xFF00838F),
    disabledColor: Color(0xFF9E9E9E),
  );

  static const starrySpace = BackgroundTheme(
    id: 'starry_space',
    name: 'Starry Space',
    description: 'Deep cosmic blue and purple',
    colors: [Color(0xFF0D1B2A), Color(0xFF1B263B), Color(0xFF3D348B)],
    cardColor: Color(0xFF243B55),
    cardBorderColor: Color(0xFF5C6BC0),
    primaryColor: Color(0xFF7C4DFF),
    secondaryColor: Color(0xFF536DFE),
    appBarColor: Color(0xFF3949AB),
    panelColor: Color(0xFF1E2A3A),
    panelAccentColor: Color(0xFF7986CB),
    textPrimaryColor: Color(0xFFE8EAF6),
    textSecondaryColor: Color(0xFFB0BEC5),
    cardTextPrimaryColor: Color(0xFFECEFF1),
    cardTextSecondaryColor: Color(0xFFB0BEC5),
    disabledColor: Color(0xFF607D8B),
    isDark: true,
  );

  static const goldenGlow = BackgroundTheme(
    id: 'golden_glow',
    name: 'Golden Glow',
    description: 'Warm cream and golden shimmer',
    colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3), Color(0xFFFFE082)],
    cardColor: Color(0xFFFFFFF5),
    cardBorderColor: Color(0xFFFFB300),
    primaryColor: Color(0xFFFFA000),
    secondaryColor: Color(0xFFFFB300),
    appBarColor: Color(0xFFFF8F00),
    panelColor: Color(0xFFFFFFF0),
    panelAccentColor: Color(0xFFFFCA28),
    textPrimaryColor: Color(0xFF6D4C41),
    textSecondaryColor: Color(0xFF8D6E63),
    cardTextPrimaryColor: Color(0xFF6D4C41),
    cardTextSecondaryColor: Color(0xFF8D6E63),
    disabledColor: Color(0xFF9E9E9E),
  );

  static const shadowNight = BackgroundTheme(
    id: 'shadow_night',
    name: 'Shadow Night',
    description: 'Mysterious purple and midnight tones',
    colors: [Color(0xFF1A1025), Color(0xFF2D1B4E), Color(0xFF0D0D0D)],
    cardColor: Color(0xFF2A1F3D),
    cardBorderColor: Color(0xFF7E57C2),
    primaryColor: Color(0xFF9575CD),
    secondaryColor: Color(0xFF5E35B1),
    appBarColor: Color(0xFF5E35B1),
    panelColor: Color(0xFF221833),
    panelAccentColor: Color(0xFF7E57C2),
    textPrimaryColor: Color(0xFFEDE7F6),
    textSecondaryColor: Color(0xFFB39DDB),
    cardTextPrimaryColor: Color(0xFFF3E5F5),
    cardTextSecondaryColor: Color(0xFFB39DDB),
    disabledColor: Color(0xFF6A6A6A),
    isDark: true,
  );

  static const all = <BackgroundTheme>[
    hatcheryDefault,
    sunnyMeadow,
    candyClouds,
    oceanBreeze,
    starrySpace,
    goldenGlow,
    shadowNight,
  ];

  static const defaultTheme = hatcheryDefault;

  static BackgroundTheme byId(String id) {
    for (final theme in all) {
      if (theme.id == id) return theme;
    }
    return defaultTheme;
  }
}
