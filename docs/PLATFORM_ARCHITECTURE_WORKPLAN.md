# Nestarium Platform Architecture Workplan

The 2026-09-06 product rebrand is recorded in `NESTARIUM_MIGRATION.md`.
`playnestarium.com` is selected; its protected playtest hostname is staged but
unrouted until provider branding and origin-recovery acceptance. Technical
save/project/bundle identities below remain compatibility contracts.

Updated: 2026-09-06

## Goal

Ship Nestarium as one Flutter game across iOS, Android, desktop web, and
mobile web without risking existing local progress. Use Railcade as the model
for account linking, offline-first saves, web delivery, diagnostics, and mobile
web policy. Use Grids & Aces as the model for durable multiplayer identity,
sessions, reconnects, transactions, and preset-only player communication.

## Standing priority: usability and player trust

The owner explicitly identifies usability as a major personal and project pain
point. It is a first-class roadmap workstream and release criterion, not polish
deferred until after features. Confirmed intended players include ages 8–12,
teens and adults; advanced child testers are not representative acceptance.
Keep the approachable core loop and gradually introduce deeper systems.

Every touched player flow must make clear: where am I, what can I do next,
what will it cost/change, can I cancel, and where is my progress saved?
Automated passes are necessary but are not proof of player comprehension.

### Next priorities, in order

1. **Save/account trust:** first patch corrects the misleading local Delete
   Account action to Remove local player with exact scope, backup and
   guest-recovery warnings. Follow with an audit of account startup, cloud
   recovery, import/conflict
   comparisons and trusted cloud deletion. Do not erase real players for QA.
   Completed patches fix autosaves repeatedly dismissing the cloud-save
   choice: unresolved decisions suspend automatic sync, not local saving; failed
   choices remain actionable. Settings now offers read-only device/cloud summaries,
   then an explicit replacement confirmation; a changed cloud revision requires a
   fresh review. Neither source is recommended or merged. The player picker now
   shares accurate local-removal confirmation, distinguishes new local progress
   from recovery/sign-in, and fits narrow layouts with named 48px avatar targets.
   **Immediate next: resolve the observed player-switch loading stall.** Final
   live return to the same guest remained on the loading logo; refresh restored
   progress. Diagnose the awaited switch stages and add app-level failure,
   overlap and completion coverage; no clearing data or changing identity.
   **Then: import safety before more recovery UI.** Current transfer rewrites
   preferences while the old game remains active. Add validated read-only preview,
   coordinated writer pause/drain, checked replacement/rollback and restart, plus
   file-picker cancellation handling. Cover nested malformed progress, failures,
   guest-slot continuity and old exports with mocked data; never replace real QA
   saves. Then continue truthful startup/recovery status and trusted cloud erasure.
2. **Child-compatible account release:** use the confirmed family audience to
   review startup collection and SDK eligibility before enabling provider links.
   Design minimal age handling, parent access/consent where needed, retention,
   deletion and a complete non-Google experience. No automatic Crashlytics,
   analytics, public profiles or social release before that review. See
   `PUBLIC_SITE.md`; owner intent is recorded, legal classification remains open.
3. **First-session comprehension:** walk through first hatch, income, quests,
   Collection, upgrades, fusion and rebirth. Keep tutorial steps continuous and
   tied to visible controls; introduce unfamiliar terms at their point of use.
   Verify replay, exit and resume, not just first launch.
4. **Whole-app navigation and accessibility:** audit remaining long pages,
   search/filter discoverability, notification routes, focus, keyboard access,
   text scaling and empty/locked/error states. Preserve the shared portrait
   shell, coin strip, navigation selection and per-destination scroll position.
5. **Consequential actions:** preview what fusion, rebirth, imports, trades and
   resets consume, preserve and may lose. Explain probabilities plainly; do
   not rely on color, icons or hover-only help. Review streak/time pressure and
   any future monetization for the intended ages before adding it.
6. **Finish external rebrand:** approve truthful public-site policies/support,
   complete provider/identity/recovery acceptance, then coordinate the protected
   hostname cutover. Display-name mail polish follows data safety. Keep store
   actions at the authorized release boundary and legacy save/infra IDs intact.
7. **Durable multiplayer:** proceed after identity, child-safety and progress
   boundaries are sound. Retain Bot Arena and preset-only communication.

### Usability acceptance for each relevant implementation

- Test 320px/390px/430px widths, short-height windows and the wide-desktop
  portrait surround; include normal and 200% text. Do not shrink text to hide
  overflows. Long dialog content must scroll while decisions remain reachable.
- Use at least 48 logical-pixel action targets for newly touched controls,
  visible keyboard focus, readable labels, and a safe cancel path for loss.
- Check that the player can reach the task without traversing an entire catalog
  and can return without losing navigation/scroll state.
- For destructive/account changes, test cancel, exact target/scope, other-player
  preservation and truthful recovery claims using disposable mocked data.
- Record automated versus browser/device versus human-comprehension evidence
  separately. Family usability testing needs deliberate parent-approved setup;
  this roadmap does not authorize recruiting or collecting child data.
- Deploy completed verified user-facing work to the existing protected
  playtest, then verify the live control without performing a destructive action.

## Architecture reference authority

Nestarium is the migration source and gameplay sandbox, not the reference
architecture. Its existing behavior is authoritative only where compatibility
or game-specific product rules require preservation. For new systems:

- Railcade is the primary reference for guest-to-protected accounts,
  offline-first progress, account recovery, settings presentation, mobile-web
  capability messaging, diagnostics, and Cloudflare delivery.
- Grids & Aces is the primary reference for identity separation, namespaced
  preferences, guest-slot handoff, multiplayer lifecycle, reconnects,
  transactions, player codes, and preset communication.
- When both have a relevant implementation, choose the safer and more mature
  behavior rather than reproducing Nestarium's current structure.
- Adapt concepts and contracts to Nestarium; do not blindly copy project
  branding, game-specific fields, or unnecessary complexity.

The old local keys and account slots are compatibility inputs. They do not
dictate the eventual service boundaries, settings model, or user experience.

## Non-negotiable migration rules

- Existing browser/device accounts and imported JSON saves must keep working.
- A new account starts empty and cannot overwrite an older local account.
- Guest play remains available. Linking a guest protects that same progress;
  it does not silently create or select a different save.
- Local data remains the immediate gameplay cache. Cloud sync must not make the
  core game dependent on a healthy network connection.
- Server-owned rewards, trades, ratings, and multiplayer results cannot be
  accepted solely because a client submitted them.
- Bot Arena stays until production multiplayer is complete and its removal is
  explicitly approved.
- Player communication remains preset-message only.

## Data ownership model

### Device-local

- Account picker state and the last locally active account
- Audio, accessibility, graphics, and control preferences
- Cached player progress and an automatically retained previous snapshot
- Unsynced operations and sync diagnostics

### Protected player account

- Authentication provider links and stable player ID
- Private progress document, save revision, and sync timestamps
- Entitlements, inventory, currencies, quests, mastery, and unlocks
- Recovery metadata needed to merge a guest with a linked account safely

### Public player profile

- Vetted display name and immutable/public lookup code
- Chosen avatar and intentionally shared collection information
- Presence summary appropriate for invitations

### Live session

- Room membership, ready state, heartbeats, reconnect leases, and match state
- Preset messages and ephemeral trade negotiation state

### Trusted server results

- Transactional trade completion
- Match outcomes, ratings, rewards, and anti-replay identifiers
- Audit records for sensitive economy changes

## Current persistence inventory

The existing keys remain unchanged during migration. Legacy unscoped variants
are retained only for backward-compatible first-account migration.

### Account directory and device session

- `playerAccounts`: device-local account-picker directory. It must eventually
  contain links to protected IDs but is not itself the authoritative profile.
- `playerAccountId`, `playerAccountDisplayName`, `playerAccountUsername`,
  `playerAccountAvatarColor`, `playerAccountCreatedAt`: legacy local profile
  fields; read for migration and do not upload as independent truth.
- `eggHatchersActiveAccountId`: web session storage only; selects the account
  for the current browser tab/session.

### Account-owned data to protect and sync

- `egg_hatchers_player_state_account_<id>` and `_backup`: versioned progress
  and its previous valid snapshot.
- `customEggs.account.<id>`: player-created eggs.
- `customSprite.account.<id>.<animalId>`: player-created sprites.
- `spriteRatingClaims.account.<id>`: claimed sprite-rating rewards. Reward
  grants become server-owned before competitive/public release.
- `spriteReferenceOverlayUnlocks.account.<id>`: purchased/unlocked overlays.
- `customSpriteMigrationComplete.account.<id>`: local migration marker only;
  never uploaded as player progress.

### Device-owned preferences

- Canonical settings now use versioned `egg_hatchers.settings.*.v1` keys behind
  `DeviceSettingsStore`, grouped by audio, visual, accessibility, and feedback.
- `audioMusicEnabled`, `audioSfxEnabled`, `audioMusicVolume`, `audioSfxVolume`,
  `selectedBackgroundThemeId`, `animalSpriteTheme`, `showBattleBackgrounds`,
  `reducedBattleEffects`, `hapticsEnabled`, and `showCustomSprites` remain
  read-only fallbacks for upgrades from the sandbox settings format.
- `rottenShellFinalBattleTutorialCompleted` now lives in account progress. The
  old device-wide key is migrated once into every existing save (including the
  unscoped legacy save) and then removed so newly created accounts do not
  inherit another player's onboarding choice.

### Development-only device state

- `devForceSlot1AnimalId`, `devForceSlot1MutationId`
- `devForceSlot2AnimalId`, `devForceSlot2MutationId`
- `devForceSlot3AnimalId`, `devForceSlot3MutationId`

These keys must never be uploaded or trusted by a production backend.

## Protected cloud contract

- `users/<authUid>/products/egg_hatchers`: the implemented private progress
  document, containing canonical progress, a monotonic cloud revision, local
  revision, SHA-256 content fingerprint, schema version, owner UID, and server
  timestamp.
- Future protected profile metadata can live separately from the product save;
  authentication identity is not inferred from display names or local account
  IDs.
- `players/<authUid>/customEggs/<eggId>` and
  `players/<authUid>/customSprites/<animalId>`: player-created content with
  independent revisions so large sprites do not rewrite the core save.
- `publicPlayers/<publicPlayerId>`: intentionally public display name, lookup
  code, avatar, and explicitly shareable collection summary. It contains no
  email, provider identifier, local account ID, or private inventory.
- Trusted economy mutations use callable server operations with idempotency
  keys. Clients do not write balances, trade results, rewards, or ratings
  directly.

## Guest-link and sync conflict policy

- Local progress with no cloud progress uploads and becomes the protected save.
- Cloud progress with no local progress downloads to the selected local slot.
- A failed, offline, timed-out, or permission-denied cloud read remains
  `unknown` and defers sync. It is never interpreted as an empty cloud account.
- Identical fingerprints are acknowledged without replacing either copy.
- When both copies differ on first link, show a comparison and require the
  player to choose. Never infer that the newer timestamp is the desired save.
- After a common revision is recorded, a change on only one side can sync
  automatically. Changes on both sides require explicit conflict resolution.
- Keep the unchosen snapshot as a recoverable backup until the chosen result is
  confirmed by both local storage and the server.
- Linking one local profile cannot absorb, rename, or delete another local
  profile on the same device.

## Delivery architecture

- Flutter remains the shared client for iOS, Android, and web.
- Cloudflare serves the web build and can protect early playtests with Access.
- Firebase Authentication supplies guest/anonymous identity and Google/Apple
  linking. Firestore stores durable player data; Functions enforce sensitive
  mutations. App Check, diagnostics and any Crashlytics adoption require the
  mixed-audience data/SDK review before public testing; they are not auto-enabled.
- Firestore is the durable system of record, not a high-frequency game loop.
  The live battle transport will be selected after measuring the current
  protocol. Cloudflare Durable Objects with WebSockets are the leading option
  when an authoritative low-latency room host is needed.

## Rollout phases

### 1. Stabilize the local contract

- Version the local progress payload while retaining current storage keys.
- Read both legacy raw saves and versioned saves.
- Add monotonic revisions and timestamps for later sync conflict handling.
- Keep backup recovery and JSON save transfer compatible.
- Document ownership, invariants, and migration tests.
- Define and test conservative sync/link decisions independently of Firebase.

Exit gate: legacy, current, backup, account-switch, and transfer tests pass.

### 2. Add identity without changing gameplay

- Add Firebase configuration per platform and emulator/dev environments.
- Create an anonymous auth user behind each guest account.
- Add Google and Apple linking with explicit merge/replace review when a linked
  account already has progress.
- Separate display name from unique public player code and auth identity.

Exit gate: guest progress survives linking, reinstall recovery works, and no
new identity can overwrite another account without an explicit resolution.

The isolated `egg-hatchers-dev` Firebase project now contains Web, Android, and
iOS registrations for the existing development identifiers. Firebase Core is
initialized fail-open on those three platforms; unsupported desktop targets and
bootstrap failures continue in local-only mode. Anonymous Authentication and
Firestore progress sync are active in development; provider linking and account
merging remain disabled at this checkpoint.

The one-durable-device-guest boundary is now explicit. Device-owned slot
metadata designates at most one local guest as eligible for a future anonymous
Firebase UID. Named legacy profiles are never inferred as that guest, ambiguous
multi-guest imports fail closed, replacing a guest rotates its identity
generation and clears any old UID binding, and slot metadata is excluded from
JSON save transfer. This preserves the existing profile picker without allowing
multiple local profiles or copied saves to share one anonymous identity.

Anonymous Firebase identity is now connected to that boundary in the client.
Only the active designated device guest may restore or create an anonymous
user. The Firebase UID is recorded in non-transferable device metadata; an
unexpected missing or mismatched persisted identity fails closed instead of
silently rebinding progress. Switching to a named local profile bypasses
Firebase identity entirely. Anonymous identity remains labeled **Not
protected** because its credential cannot yet be recovered after browser-data
clearing or uninstall. The Anonymous provider is enabled in the isolated
`egg-hatchers-dev` Firebase project; a live disposable identity create/delete
smoke test passed on 2026-09-05.

The Google protection client is now staged for Web. A first-time link uses
Firebase account linking so the anonymous UID and cloud document remain
unchanged. An existing Google-owned Nestarium identity is treated as an
account switch: the prior sync checkpoint is cleared and the ordinary
cloud/device conflict gate must resolve the selected save. Canceled or failed
provider flows retain the guest identity and local progress. The UI is exposed
only where provider configuration is known complete; Android and iOS stay
fail-closed until their native OAuth registrations are provisioned and tested.

### 3. Add offline-first cloud progress

- Introduce a progress repository above local storage and Firestore sync.
- Upload revisioned snapshots, record the last acknowledged cloud revision,
  and surface pending/synced/conflict/error status in Settings.
- Resolve common conflicts automatically only when ancestry is known. Require a
  preview and explicit choice for divergent valuable progress.
- Keep JSON export as a user-controlled recovery path.

Exit gate: offline play, reconnect, two-device conflicts, corrupted local data,
and interrupted writes are covered by automated and manual tests.

The development implementation is now active. The `(default)` Firestore
database is Standard edition in `nam5`, matching Railcade and Grids & Aces.
Authenticated users may access only
`users/<uid>/products/egg_hatchers`. Deployed rules require the exact schema,
matching owner UID, server write time, a 64-character SHA-256 fingerprint, and
monotonic one-step cloud revisions; deletion and cross-user access are denied.
The rules have dedicated emulator coverage in `firestore-rules-tests`.

`ProgressSyncService` keeps gameplay local-first and coalesces frequent saves
onto a bounded cloud-write cadence. Server-only reads fail closed to `unknown`;
they never authorize a destructive first upload. Confirmed empty cloud saves
receive local progress, cloud-only saves restore locally, and known one-sided
changes use the last acknowledged fingerprint/revision as ancestry. Divergence
surfaces an explicit Settings choice between **Use Cloud** and **Keep Device**,
with a revalidated read/transaction before either result is accepted. Settings
also exposes pending, syncing, current, conflict, and retry-safe error states.

This checkpoint protects the guest save against ordinary local corruption and
keeps a server copy for the current anonymous credential. It intentionally does
not claim cross-install recovery: Google/Apple provider linking is the next
identity milestone that makes the same UID recoverable across installations
and platforms.

The first hosted implementation shipped in commit `38838e4` as Cloudflare
playtest version `0ebef879-3b8b-4b4c-be93-7176e109696c`. External-Chrome QA
confirmed the existing local save remained intact and its owner-scoped
Firestore document advanced to cloud revision 44.

### 4. Establish web delivery and platform policy

- Deploy release web builds through Cloudflare with separate preview and
  production environments.
- Protect pre-release environments with Cloudflare Access.
- Add install/open-in-app guidance and platform capability messaging.
- Test audio latency and frame pacing on representative iOS Safari and Android
  Chrome devices. If sound materially harms mobile-web play, default it off and
  clearly advertise full audio on iOS, Android, and desktop web.

Exit gate: narrow-phone controls, auth redirects, save sync, audio policy, and
desktop/mobile web performance pass the release checklist.

The private delivery boundary is now scaffolded in `cloudflare/playtest` as a
Workers Static Assets application. It deliberately has no public preview URL or
public preview route. The selected temporary hostname is
`egg-hatchers-playtest.daygullstudios.com`, protected by a dedicated Cloudflare
Access application that reuses Railcade's approved-tester policy. The Flutter
web build also ships private-cache, no-index, and baseline browser hardening
headers. This permits private release verification without committing to the
final product name. Nestarium is now selected; the original origin is retained
for save continuity until the staged hostname's migration gates pass.

The first routed release is deployed. Unauthenticated checks against both the
app shell and compiled JavaScript are redirected to Cloudflare Access, while
Workers preview URLs remain disabled. Approved-browser gameplay verification
follows once the newly attached custom hostname has propagated through the
local DNS resolver.

The private web client also distinguishes its expected missing multiplayer
backend from a missing local development server. Until the durable multiplayer
service ships, hosted players are directed to the retained Bot Arena instead of
being told to start a server on their own device.

### 5. Make multiplayer durable and authoritative

- Replace process-memory presence and rooms with durable session state.
- Add reconnect leases, idempotent commands, server clocks, match IDs, and
  replay protection.
- Put trades, rewards, and rating changes behind trusted transactions.
- Retain preset-only messages, reporting controls, rate limits, and moderation
  hooks.

Exit gate: server restart, dropped connection, duplicate command, concurrent
trade, and malicious-client tests pass. Bot Arena remains until separately
approved for removal.

### 6. Production hardening

- Enable App Check enforcement gradually and monitor rejected legitimate users.
- Add crash, sync, auth, match, and economy diagnostics without collecting open
  player text.
- Establish backup/restore drills, schema migration policy, retention policy,
  and staged rollout/rollback procedures.

## External setup gates

These do not block phase 1. They are needed before their respective later
phases can ship:

- Firebase project access and iOS/Android/web app registrations
- Google and Apple provider credentials and verified redirect domains
- Cloudflare zone/project access, DNS choice, and Access policy decisions
- Final public product name and domains before production-facing identifiers

## Original foundation sequence (historical; use priorities above for next work)

1. Land the versioned local progress envelope and migration tests.
2. Inventory all SharedPreferences keys and classify each by ownership.
3. Define the cloud document schema and guest-link conflict rules in tests.
4. Add Firebase to a development environment without enabling destructive sync.
5. Add anonymous identity and then explicit provider linking.
6. Add cloud sync status and conflict-safe progress synchronization.
7. Establish Cloudflare preview deployment and mobile-web qualification.
8. Migrate live multiplayer only after identity and durable progress are stable.

## Adopted improvements over the sandbox

- Replace the mandatory local “player name + username before play” concept with
  immediate guest play, an editable display name, and a server-issued immutable
  public player code once the account is protected.
- Present account state as `Guest`, `Syncing`, `Protected`, or `Sync issue`, with
  “Protect progress” as the primary guest action.
- Keep account/progress management distinct from ordinary presentation and
  gameplay settings.
- Move toward immutable settings values plus a dedicated persistence store,
  clamped numeric inputs, versioned namespaced keys, a safe reset-to-defaults,
  and explicit ownership of identity-adjacent preferences.
- Preserve separate music and SFX levels, reduced effects, haptics, art style,
  and background choices. Add platform capability messaging when audio or
  another feature is intentionally unavailable.
- Maintain local JSON export as recovery tooling even after cloud sync exists.

The immutable device settings value and versioned store are implemented. The
existing services retain their public APIs while reading legacy values and
writing the canonical namespaced format.

The versioned progress envelope now records a deterministic SHA-256 content
fingerprint and exposes revision/save metadata through `ProgressSaveSnapshot`.
Canonical hashing ignores the local save timestamp and sorts map keys, so
equivalent progress compares equal across devices. A fingerprint mismatch is
treated as corruption and recovers the retained previous snapshot.

Each local account also has a versioned `ProgressSyncCheckpointStore`. It holds
only the last content fingerprint and cloud revision confirmed by both sides,
which lets the conservative planner recognize a shared ancestor. The
checkpoint is account-scoped device metadata, is discarded with that local
account, and never grants authority to modify gameplay progress.

`ProgressSyncAssessmentService` now joins the local envelope, checkpoint, and a
provider-neutral protected-cloud read into one read-only assessment. Remote
exceptions and invalid remote fingerprints are reduced to `unknown`, which can
only produce `waitForCloud`. Actual upload, download, and conflict resolution
remain separate revalidated operations for the future Firebase adapter.

`AccountProtectionService` now provides the app-wide state seam used by the
mature Railcade model: starting, local-only, guest, syncing, protected, and
error. Until a Firebase gateway is configured, Settings explicitly identifies
every Nestarium profile as **Device only**. A local display name or username
is never presented as proof that progress is protected across devices.

Immediate guest entry is also implemented locally. Fresh installs receive a
persistent `Guest Hatcher` slot without completing a form, and a pre-account
legacy save is adopted by that slot through the existing guarded migration.
The internal generated username remains protocol compatibility data only and is
not presented as the guest's public identity. Existing named profiles retain
their original identity and behavior.
