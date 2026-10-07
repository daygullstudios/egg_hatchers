# Audio Release Acceptance

Updated: 2026-10-07

This checklist supports the roadmap items for boss phase music, volume
normalization, and platform audio behavior. It does not close those items by
itself because final release audio still needs a listening pass on the selected
platforms.

## Registered release tracks

- Hatchery: `assets/sounds/music/hatchery_chill_loop.mp3`
- Normal boss battle: `assets/sounds/music/boss_music.wav`
- Rotten Shell final boss: `assets/sounds/music/final_boss_music.mp3`

`test/audio_assets_test.dart` verifies that every registered music/SFX asset is
present, complete, release-sized, and that every shipped audio file is
registered in `lib/data/audio_assets.dart`.

## Normal boss phase music

Normal manual boss fights use `AudioService.battleMusicSections`, which stores
the BandLab section starts and loop ranges. Each lost boss life moves to the
next section without intentionally restarting the whole track.

Current section ranges:

- Phase 1: starts at `0:00.000`, loops `0:01.667` to `0:13.333`.
- Phase 2: starts at `0:13.333`, loops `0:16.667` to `0:26.667`.
- Phase 3: starts at `0:26.667`, loops `0:30.000` to `0:40.000`.
- Phase 4: starts at `0:40.000`, loops `0:40.000` to `1:06.667`.

`test/manual_battle_test.dart` verifies those exact markers and confirms boss
music advances as lives are removed.

## Listening pass

Before release, play a normal manual boss fight from a fresh app start and
confirm:

- First user tap unlocks audio on web without needing a second reload.
- Phase 1 starts at the beginning, then loops smoothly inside its red BandLab
  range.
- Each boss-life hit moves to the next phase section instead of restarting at
  `0:00`.
- Each phase loops inside its own range until the next hit.
- Hatchery, normal boss, final boss, reward, hit, finisher, and UI sounds sit at
  comfortable relative volume with the default settings.
- Music and SFX sliders in Settings change volume without needing a reload.
- Music/SFX mute toggles persist after refresh.
- Pause/resume and app background/foreground behavior are acceptable on every
  selected release platform.

## Remaining release-candidate work

- Owner listening approval for the normal boss phase loops.
- Listening approval for hatchery and final boss music transitions.
- Volume normalization approval for music and SFX.
- Platform audio behavior checks for every selected launch target.
- Source/license confirmation for the three music files in
  `docs/ASSET_RIGHTS_RELEASE_AUDIT.md`.

