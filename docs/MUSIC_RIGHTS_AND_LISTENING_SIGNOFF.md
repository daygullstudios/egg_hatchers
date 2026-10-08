# Nestarium music rights and listening signoff

Updated: 2026-10-08

Use this packet for the final music-rights and listening pass. It does not confirm commercial rights,
approve shipped audio, or close the roadmap audio items by itself. The release
owner must fill this for the exact release candidate after the music source
records, platform listening pass, and audio behavior checks exist.

## Signoff identity

- Candidate commit: TBD
- Release owner: TBD
- Audio reviewer: TBD
- Rights/source reviewer: TBD
- Selected launch platforms: TBD
- Review date: TBD

## Music source records to fill

Record the source, license, export, and approval for every shipped music file:

| File | Tool/source | Project/export link | Creation/export date | Account/license note | Commercial game use approved |
| --- | --- | --- | --- | --- | --- |
| `assets/sounds/music/hatchery_chill_loop.mp3` | TBD | TBD | TBD | TBD | TBD |
| `assets/sounds/music/boss_music.wav` | TBD | TBD | TBD | TBD | TBD |
| `assets/sounds/music/final_boss_music.mp3` | TBD | TBD | TBD | TBD | TBD |

If a track came from Suno, BandLab, or another music tool, record the account,
subscription/license status, exported file name, export date, and any project or post link
that proves the source and commercial game use. Do not ship a replacement or edited track
without updating `docs/ASSET_RIGHTS_RELEASE_AUDIT.md`.

## Normal boss listening pass

Use a fresh app start and a normal manual boss fight:

- First user tap unlocks audio on web without requiring a reload.
- Phase 1 starts at `0:00.000`, then loops from `0:01.667` to `0:13.333`.
- First boss-life hit moves to phase 2 instead of restarting the track.
- Phase 2 starts at `0:13.333`, then loops from `0:16.667` to `0:26.667`.
- Second boss-life hit moves to phase 3 instead of restarting the track.
- Phase 3 starts at `0:26.667`, then loops from `0:30.000` to `0:40.000`.
- Third boss-life hit moves to phase 4 instead of restarting the track.
- Phase 4 starts at `0:40.000`, then loops from `0:40.000` to `1:06.667`.
- Each loop sounds smooth enough for release on the selected platforms.

## Whole-game listening pass

Check the default mix with music and SFX both enabled:

- Hatchery music starts, loops, and stops cleanly when leaving the hatchery.
- Normal boss music transitions do not restart at `0:00` after each hit.
- Rotten Shell final boss music starts and stops at the correct moments.
- Reward, hit, finisher, purchase, hatch, fusion, UI, and cinematic sounds are
  comfortable relative to music.
- Music and SFX sliders change volume without a reload.
- Music and SFX mute toggles persist after refresh.
- Pause/resume does not stack duplicate music.
- App background/foreground behavior is acceptable on every selected release
  platform.
- Reduced Battle Effects does not hide critical audio feedback.

## Required technical evidence

Attach or cite:

- `node tool/audit_audio_release.mjs`
- `node tool/audit_asset_rights.mjs`
- `test/audio_assets_test.dart`
- `test/manual_battle_test.dart`
- `docs/AUDIO_RELEASE_ACCEPTANCE.md`
- `docs/PLATFORM_AUDIO_BEHAVIOR_MATRIX.md`
- `docs/ASSET_RIGHTS_RELEASE_AUDIT.md`
- `docs/VISUAL_AUDIO_ACCESSIBILITY_AUDIT.md`

## Stop conditions

Do not close the release audio or asset-rights roadmap items if any of these are
true:

- A shipped music file lacks source/license confirmation.
- Commercial game use is not approved for a shipped music file.
- A boss phase restarts at `0:00` after a life hit.
- A boss phase loops outside its approved BandLab red range.
- Any music or SFX is painfully loud at default volume.
- Mute or slider settings do not persist.
- Platform background/foreground behavior breaks music playback.
- The shipped bundle contains an unregistered audio file.
- The release candidate record does not cite the final music signoff.
