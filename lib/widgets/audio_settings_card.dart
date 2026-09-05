import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../theme/game_theme.dart';
import '../models/background_theme.dart';

/// Music/SFX toggles and volume sliders for the style/settings screen.
class AudioSettingsCard extends StatelessWidget {
  const AudioSettingsCard({
    super.key,
    required this.theme,
    required this.audio,
    this.embedded = false,
    this.showTitle = true,
  });

  final BackgroundTheme theme;
  final AudioService audio;
  final bool embedded;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: embedded ? null : GameTheme.cardDecoration(theme),
        padding: embedded
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showTitle) ...[
                Text('Audio', style: GameTheme.sectionTitle(theme, size: 18)),
                const SizedBox(height: 4),
              ],
              Text(
                'Music and sound effects. Tap anywhere in the game to enable audio on web.',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.cardTextSecondaryColor,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Music',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.cardTextPrimaryColor,
                  ),
                ),
                subtitle: Text(
                  audio.musicEnabled ? 'Background music on' : 'Music muted',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.cardTextSecondaryColor,
                  ),
                ),
                value: audio.musicEnabled,
                activeThumbColor: theme.primaryColor,
                onChanged: audio.setMusicEnabled,
              ),
              if (audio.musicEnabled) ...[
                Row(
                  children: [
                    Icon(
                      Icons.music_note_rounded,
                      size: 18,
                      color: theme.cardTextSecondaryColor,
                    ),
                    Expanded(
                      child: Slider(
                        value: audio.musicVolume,
                        onChanged: audio.setMusicVolume,
                        activeColor: theme.primaryColor,
                      ),
                    ),
                    Text(
                      '${(audio.musicVolume * 100).round()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.cardTextSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Sound Effects',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.cardTextPrimaryColor,
                  ),
                ),
                subtitle: Text(
                  audio.sfxEnabled ? 'Gameplay sounds on' : 'SFX muted',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.cardTextSecondaryColor,
                  ),
                ),
                value: audio.sfxEnabled,
                activeThumbColor: theme.primaryColor,
                onChanged: audio.setSfxEnabled,
              ),
              if (audio.sfxEnabled) ...[
                Row(
                  children: [
                    Icon(
                      Icons.graphic_eq_rounded,
                      size: 18,
                      color: theme.cardTextSecondaryColor,
                    ),
                    Expanded(
                      child: Slider(
                        value: audio.sfxVolume,
                        onChanged: audio.setSfxVolume,
                        activeColor: theme.primaryColor,
                      ),
                    ),
                    Text(
                      '${(audio.sfxVolume * 100).round()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.cardTextSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
