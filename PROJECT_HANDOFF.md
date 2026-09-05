# Egg Hatchers Project Handoff

Updated: 2026-09-05

## Project status

Egg Hatchers is a Flutter idle collection and battle game. It currently includes local multi-account saves, hatching and mutations, rebirths, quests, collections, fusions, custom eggs and sprites, three visual styles, manual boss fights, Bot Arena, live multiplayer battles, live trading, player invitations, collection viewing, and preset trade messages.

Recent polish includes projectile trails, staged boss music that layers intensity without restarting, pause-resume countdowns, improved boss backgrounds, a hidden DayGull Egg unlock path, DayGull animals with animated glitch effects, and a live coin balance that remains in the shared app bar throughout navigation. The hatchery labels its Rebirth-scoped animal-income total as `earned` and explains the total on hover or tap; misleading player-facing `lifetime` terminology has been removed.

The entire app now runs inside one root-level 430px portrait surface on wide displays, with a neutral dark desktop surround and the themed game background contained inside the surface. The constrained `MediaQuery` is inherited by the Navigator, routes, dialogs, tutorial overlays, app bars, and persistent navigation, so new UI cannot accidentally stretch across the desktop viewport; phone-sized displays remain edge-to-edge and vertically scroll normally. The major game screens share persistent navigation with Hatchery, Shop, Battles, Collection, and More, and tabs remain mounted so scroll and screen state survive switching. More opens an anchored, tab-styled secondary menu immediately beneath the navigation rather than a disconnected bottom sheet; it contains Quests, Custom Animals, and Settings. The Quests screen uses a single-open accordion, a pinned category jump control, a unified Ready to Claim section with Claim All for ordinary rewards, intelligent progress sorting, and hidden claimed quests.

The Battles screen now keeps Battle Tokens plus the Rival Arena, Online Arena, and Trading launchers visible, then uses a single-open accordion for Battle Upgrades, all seven bosses, and Egg Shard Upgrades. Collapsed boss headers show identity, lock/progression status, wins, and the best available difficulty; locked bosses no longer consume full-card height. Upgrade headers surface affordable-action counts, the first Slime Boss section defaults open for onboarding continuity, and the selected section persists while the shell tab remains mounted.

The Egg Shop now uses a persistent three-way Hatchery/Battle/Custom category switcher above its catalog. Only the selected catalog is rendered, each category surfaces a useful availability summary, Hatchery remains the default for tutorial continuity, and each catalog keeps its own scroll position while the shell remains mounted.

Hatchery is now a dashboard rather than a duplicate full inventory: it shows a three-stack Production Snapshot, keeps the tutorial's first upgrade target visible, and links directly to full Collection management. Collection separates Animals and Fusion into persistent modes; Animals provides pinned search, Normal/Mutated filtering, and rarity/name/income/level/quantity sorting, while the Fusion tutorial automatically opens and focuses the Fusion mode.

Settings now opens as a compact set of four collapsed destinations: Account & Saves, Tutorial, Sound & Feedback, and Appearance. Only one can be expanded at a time. Appearance uses a Background/Animal Style switch so the two visual catalogs are never rendered as one long stack, while Custom Animals remains a direct action.

Quest-completion notification actions now select the persistent shell's Quests destination, matching More > Quests and preserving the current navigation UI and mounted quest state. The standalone Quests route remains only as a fallback for contexts outside the main shell.

Secret Hatchery discovery is now persisted separately from collection mastery. Three taps on the Hatchery coin can still reveal it early, but the one-time protected-animal badge is held in the Collector's Vault until the 48-animal collection quest is claimed. Existing saves that already claimed the former clue or badge migrate to an unlocked vault.

Tutorial entry copy is replay-safe (`Tutorial`, `Start Tutorial`, and `Exit Tutorial`). Spotlight steps scroll their entire target into the visible viewport and reject partially off-screen measurements. Standard text buttons across the app now include contextual icons; compact ability controls and hatchery navigation retain their existing embedded pictograms.

The repository is owned by the `daygullstudios` GitHub organization. The main development branch is `main`. Work should be committed and pushed after every completed patch.

## Local data

Accounts, game progress, settings, custom eggs, and custom sprites are stored locally through Flutter `SharedPreferences`; they are not stored in GitHub. The Settings screen includes Save Transfer controls:

1. On the old computer, open Settings and choose **Export Save**.
2. Move the downloaded `egg-hatchers-save-YYYY-MM-DD.json` file to the new computer.
3. On the new computer, open Settings and choose **Import Save**.
4. Confirm replacement and restart the game when prompted.

Import replaces all Egg Hatchers local data on the destination browser. Keep the exported file as a backup until migration is verified.

## Known unfinished production work

- Multiplayer rooms and presence are held in server memory. Production needs authenticated server accounts, durable database storage, transactional trades, reconnect handling, moderation controls, and abuse protection.
- Browser accounts are local profiles, not secure remote authentication.
- Android release signing is not configured. Follow `README.md` before store publishing.
- Render configuration exists for later beta hosting, but the user does not want to release yet.
- Bot Arena remains intentionally available until multiplayer is finished.
- Continue checking remaining Retro Pixel assets for consistency as new art is added.

The staged cross-platform, account, cloud-save, Cloudflare, and multiplayer
architecture plan is maintained in `docs/PLATFORM_ARCHITECTURE_WORKPLAN.md`.
Phase 1 has begun by versioning local progress without changing existing save
keys or the JSON transfer format. The persistence inventory, proposed protected
cloud contract, and conservative guest-link conflict policy are documented in
that plan and represented by Firebase-independent sync-planning tests.
Egg Hatchers is explicitly treated as the legacy migration source rather than
the architecture authority; new systems follow the stronger proven Railcade or
Grids & Aces pattern where applicable.

Device settings now pass through an immutable `DeviceSettings` value and a
versioned `DeviceSettingsStore`. Existing sandbox keys are still read as
migration fallbacks; new changes use namespaced keys. Resetting that store is
tested to leave accounts and progress untouched.

Fresh installs now enter through an automatically created, persistent guest
slot instead of requiring a player name and username before play. Existing
named profiles and imports remain compatible, and legacy pre-account progress
is safely claimed by the new guest slot.

## Art rules

Every new animal needs Classic, Retro Pixel, and Realistic versions. Classic should be cartoony, Retro Pixel should be intentionally pixel-built, and Realistic should match the detailed transparent sprite set. DayGull animals may also need the established animated side-slice glitch treatment.

## Future event concepts

Planned order: Halloween, Christmas, Easter, Corruption.

- Halloween: themed bosses award pumpkins; pumpkins purchase a Halloween Egg; a final Vampire or Cerberus boss awards a one-time character; Haunted mutation chance.
- Christmas: reindeer, snowman, gingerbread, and similar bosses award snowflakes; snowflakes buy presents containing money or Christmas animals; final Santa boss awards a Santa animal.
- Easter: egg-hunt minigame; exchange collected eggs for Easter Eggs; end-of-event shop directly sells animals instead of using chance.
- Corruption: temporary high-value Corrupted mutation; event countdown on login and in the hatchery; final request to fight The Corrupted after beating Rotten Shell and paying about 25 Egg Shards. The proposed 3D fight stays private during beta and initially supports only the chicken to limit animation scope.

## Development and testing

Install Flutter stable, fetch packages, then run:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build web --release
```

For the combined local web and multiplayer service, see `README.md`. Temporary Cloudflare tunnels are disposable and do not need to be migrated. Do not copy Codex `auth.json`, caches, sandbox directories, or temporary databases between computers.
