# Egg Hatchers Project Handoff

Updated: 2026-09-06

## Project status

Egg Hatchers is a Flutter idle collection and battle game. It currently includes local multi-account saves, hatching and mutations, rebirths, quests, collections, fusions, custom eggs and sprites, three visual styles, manual boss fights, Bot Arena, live multiplayer battles, live trading, player invitations, collection viewing, and preset trade messages.

Recent polish includes projectile trails, staged boss music that layers intensity without restarting, pause-resume countdowns, improved boss backgrounds, a hidden DayGull Egg unlock path, DayGull animals with animated glitch effects, and a live coin balance that remains in the shared app bar throughout navigation. The hatchery labels its Rebirth-scoped animal-income total as `earned` and explains the total on hover or tap; misleading player-facing `lifetime` terminology has been removed.

The entire app now runs inside one root-level 430px portrait surface on wide displays, with a neutral dark desktop surround and the themed game background contained inside the surface. The constrained `MediaQuery` is inherited by the Navigator, routes, dialogs, tutorial overlays, app bars, and persistent navigation, so new UI cannot accidentally stretch across the desktop viewport; phone-sized displays remain edge-to-edge and vertically scroll normally. The major game screens share persistent navigation with Hatchery, Shop, Battles, Collection, and More, and tabs remain mounted so scroll and screen state survive switching. More opens an anchored, tab-styled secondary menu immediately beneath the navigation rather than a disconnected bottom sheet; it contains Quests, Custom Animals, and Settings. All three are mounted shell destinations with the same coin/navigation header and preserved screen state; Settings no longer pushes a visually inconsistent standalone route from More. The Quests screen uses a single-open accordion, a pinned category jump control, a unified Ready to Claim section with Claim All for ordinary rewards, intelligent progress sorting, and hidden claimed quests.

The Battles screen now keeps Battle Tokens plus the Rival Arena, Online Arena, and Trading launchers visible, then uses a single-open accordion for Battle Upgrades, all seven bosses, and Egg Shard Upgrades. Collapsed boss headers show identity, lock/progression status, wins, and the best available difficulty; locked bosses no longer consume full-card height. Upgrade headers surface affordable-action counts, the first Slime Boss section defaults open for onboarding continuity, and the selected section persists while the shell tab remains mounted.

The Egg Shop now uses a persistent three-way Hatchery/Battle/Custom category switcher above its catalog. Only the selected catalog is rendered, each category surfaces a useful availability summary, Hatchery remains the default for tutorial continuity, and each catalog keeps its own scroll position while the shell remains mounted. Custom egg creation and management live within the Custom category; the former redundant Shop app-bar shortcut has been removed.

Claimable quest cards use the theme's primary action color for their Claim Reward/Claim buttons. This keeps the button silhouette and white label legible inside the gold secondary-color Ready to Claim treatment; the secondary color remains the reward-card accent rather than serving as both surface and action.

Hatchery is now a dashboard rather than a duplicate full inventory: it shows a three-stack Production Snapshot, keeps the tutorial's first upgrade target visible, and links directly to full Collection management. Collection separates Animals and Fusion into persistent modes; Animals provides pinned search, Normal/Mutated filtering, and rarity/name/income/level/quantity sorting, while the Fusion tutorial automatically opens and focuses the Fusion mode.

Settings now opens as a compact set of four collapsed destinations: Account & Saves, Tutorial, Sound & Feedback, and Appearance. Only one can be expanded at a time. Appearance uses a Background/Animal Style switch so the two visual catalogs are never rendered as one long stack. Custom Animals is available only through the persistent More menu, avoiding a redundant Settings shortcut.

Custom Animals keeps visibility guidance and Reset All in a compact tools accordion at the top instead of burying destructive management below the full catalog. Search plus All/Customized/Original filtering and Rarity/Name/Progression sorting stay above the independently scrolling results, making any of the 48 animals directly reachable without a page-length traversal.

Custom Eggs keeps Create pinned above an independently scrolling library. Saved eggs are searchable, filterable by Enabled/Disabled/Needs Attention, sortable by Newest/Name/Price, and render as single-open summaries; only the selected egg exposes animal previews plus Edit/Delete actions.

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

Phase 2 has started with an isolated `egg-hatchers-dev` Firebase project and
registered Web, Android, and iOS development apps. Firebase Core initializes
fail-open on those platforms, and anonymous Firebase Authentication is active
for the designated device guest. Provider linking and account merging are not
active yet. The
proven one-durable-device-guest boundary is now implemented as device-owned
metadata: exactly one unambiguous guest may later receive an anonymous Firebase
UID, named profiles are never inferred, replacement rotates the identity
generation and clears the old binding, and imports/exports cannot transfer this
metadata. Cloud writes are enabled only for that authenticated guest and are
guarded by the revision and conflict gates described below.

The client-side anonymous-auth adapter is now implemented for that designated
slot. It waits for persisted Firebase authentication to restore, creates a new
anonymous user only when no binding exists, verifies stored UID continuity on
later starts, and refuses to bind named profiles or mismatched identities.
Anonymous identity is still shown as **Not protected** because clearing browser
data or uninstalling the app can lose its unlinked credential. Anonymous
sign-in is enabled in the isolated `egg-hatchers-dev` project, and a live
disposable create/delete smoke test passed on 2026-09-05 without leaving the
test identity behind.

Offline-first progress sync is now active for the designated anonymous guest.
The `(default)` Firestore database uses the same `nam5` multi-region and
Standard edition as the two reference development projects. Each UID owns one
revisioned document at `users/<uid>/products/egg_hatchers`; deployed Security
Rules require authentication, exact ownership, a strict document shape,
server timestamps, valid SHA-256 fingerprints, and one-step cloud revision
increments. Deletes and cross-user access are denied.

The client keeps local progress authoritative during play, reads Firestore from
the server, and uploads on a bounded cadence. Unknown/offline reads never count
as an empty cloud save. Known one-sided changes sync automatically; divergent
device and cloud saves stop for an explicit **Use Cloud** or **Keep Device**
choice in Settings. The last mutually confirmed fingerprint and cloud revision
remain account-scoped device metadata. JSON export remains the user-controlled
recovery path. Rules are covered by emulator tests; sync planning, repository
decoding, continuous-save throttling, restore, and conflict behavior are
covered by Flutter tests.

The first hosted sync release is commit `38838e4`, deployed to the protected
Cloudflare playtest as version `0ebef879-3b8b-4b4c-be93-7176e109696c`. An
external-Chrome smoke test loaded the existing local save and confirmed its
owner-scoped Firestore document was actively advancing revisions (revision 44
at inspection) on 2026-09-05.

`playnestarium.com` was purchased through the existing Daygull Studios
Cloudflare account on 2026-09-06 as the selected public-facing Nestarium
domain. It is active, auto-renew is enabled, and it expires on 2027-09-06.
No DNS, Worker route, email, Firebase, game-title, or public-site change has
been made yet. Configure its public hostname deliberately and add it to
Firebase Authentication's authorized domains before it is used for live
sign-in or play.

The next identity slice is implemented locally but not released yet. The
device guest can link Google on Web while preserving the anonymous UID and its
Firestore document. If the selected Google credential already belongs to an
Egg Hatchers identity, the client opens that UID, clears the old local sync
ancestry, and requires the normal cloud/device comparison before accepting a
save. Cancellation and errors leave the guest save unchanged. Native Google
buttons remain fail-closed because the Android OAuth/SHA registration and iOS
client configuration are not provisioned yet. Firebase's Google provider form
is prepared with the public app name but still requires the owner-approved
public support email and final Save; the playtest hostname must then be added
to Firebase Authentication's authorized domains before live QA.

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
