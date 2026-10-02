# Visual, audio and accessibility audit

Audited: 2026-10-02

This audit records release evidence for the visual, audio and accessibility
roadmap gate. It is based on the current candidate and the targeted verification
run:

`flutter test test\animal_sprite_theme_test.dart test\audio_assets_test.dart test\animal_motion_test.dart test\boss_battle_motion_test.dart test\boss_attack_telegraph_test.dart test\battle_ability_effect_test.dart test\battle_ability_button_test.dart test\battle_fighter_switcher_test.dart test\battle_health_bar_test.dart test\battle_impact_overlay_test.dart test\battle_resume_countdown_test.dart test\arena_screen_test.dart test\account_onboarding_screen_test.dart test\first_player_journey_test.dart test\tutorial_target_visibility_test.dart test\unsaved_progress_test.dart`

Result: 86 tests passed.

Additional accessibility verification:

`flutter test test\accessibility_release_audit_test.dart`

Result: 3 tests passed.

## Completed evidence

### Animal style coverage

Every built-in animal has Classic, Retro Pixel and Realistic release artwork:

- Classic animal and boss art decodes as transparent PNG art.
- Realistic animal art covers every animal ID and mapped boss ID.
- The Ultimate Nest has ten transparent head assets for each style.
- Crossword Beast and DayGull-specific assets are present in all required
  styles.

### Retro Pixel replacement

The Retro Pixel catalog is no longer a set of unfinished or low-quality scaled
fallbacks:

- Every built-in animal has a Retro Pixel sprite.
- Every built-in animal resolves to native 64x64 Retro Pixel art.
- Native sprites are tested against legacy 32x32 art to prevent pure 2x
  upscales.
- Every built-in animal also has exported transparent Retro Pixel PNG art.

### Eggs, bosses, backgrounds and battle effects

The current art tests cover the release-critical battle and hatch visuals:

- Every built-in egg has Classic, Retro Pixel and Realistic egg art.
- Every Classic egg uses polished transparent v2 artwork.
- Realistic boss backgrounds exist for each boss route and stay under the
  release size budget.
- Retro Pixel boss sprites and boss projectile art exist for every supported
  boss type.
- Battle motion, ability effects, fighter switching, health feedback, impact
  overlays and attack telegraphs render in normal and reduced-effects modes.

### Phone, tablet, desktop and reduced-effects evidence

The targeted run confirms several layout and reduced-effects paths:

- Account onboarding and recovery controls fit narrow phone, tablet-sized and
  desktop-width layouts, including high text scale cases.
- The first-player journey completes and reopens at 320x568 and 390x844.
- Arena lobby and battle flows fit compact layouts.
- Long tutorial prompts stay visible on short screens.
- Reduced battle effects keep motion, readiness, health, impact and countdown
  widgets stable.
- Theme app bar/action foregrounds meet release contrast thresholds.
- Primary navigation labels are present and keep at least 48x48 touch targets
  on phone and desktop widths.

### Audio asset registration

The audio asset audit confirms:

- Every registered music and SFX asset exists.
- Registered music tracks and effects are complete audio files, not tiny tone
  placeholders.
- Every shipped audio file under the music and SFX folders is registered.
- Key recorded effects have cooldowns to avoid obvious self-overlap.

## Remaining release work

These items still need separate approval or platform evidence:

- Final Nestarium logo approval and regenerated platform branding assets.
- Boss phase music loop approval in real gameplay.
- Music and SFX volume normalization by listening pass.
- Audio unlock, pause/resume and background/foreground behavior on each selected
  release platform.
- Full contrast review and final touch-target pass across the whole app.
- Music source/license confirmation for the three shipped music files listed in
  `docs/ASSET_RIGHTS_RELEASE_AUDIT.md`.
