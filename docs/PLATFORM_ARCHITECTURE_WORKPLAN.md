# Egg Hatchers Platform Architecture Workplan

Updated: 2026-09-04

## Goal

Ship Egg Hatchers as one Flutter game across iOS, Android, desktop web, and
mobile web without risking existing local progress. Use Railcade as the model
for account linking, offline-first saves, web delivery, diagnostics, and mobile
web policy. Use Grids & Aces as the model for durable multiplayer identity,
sessions, reconnects, transactions, and preset-only player communication.

## Design authority

Egg Hatchers is the migration source and gameplay sandbox, not the reference
architecture. Its existing behavior is authoritative only where compatibility
or game-specific product rules require preservation. For new systems:

- Railcade is the primary reference for guest-to-protected accounts,
  offline-first progress, account recovery, settings presentation, mobile-web
  capability messaging, diagnostics, and Cloudflare delivery.
- Grids & Aces is the primary reference for identity separation, namespaced
  preferences, guest-slot handoff, multiplayer lifecycle, reconnects,
  transactions, player codes, and preset communication.
- When both have a relevant implementation, choose the safer and more mature
  behavior rather than reproducing Egg Hatchers' current structure.
- Adapt concepts and contracts to Egg Hatchers; do not blindly copy project
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

- `audioMusicEnabled`, `audioSfxEnabled`, `audioMusicVolume`, `audioSfxVolume`
- `selectedBackgroundThemeId`, `animalSpriteTheme`, `showBattleBackgrounds`
- `reducedBattleEffects`, `hapticsEnabled`, `showCustomSprites`
- `rottenShellFinalBattleTutorialCompleted` is currently device-wide. It should
  move into account progress before cloud sync because it affects onboarding.

### Development-only device state

- `devForceSlot1AnimalId`, `devForceSlot1MutationId`
- `devForceSlot2AnimalId`, `devForceSlot2MutationId`
- `devForceSlot3AnimalId`, `devForceSlot3MutationId`

These keys must never be uploaded or trusted by a production backend.

## Proposed protected cloud contract

- `players/<authUid>`: private account metadata, schema version, creation time,
  provider summary, and active progress pointer.
- `players/<authUid>/progress/current`: canonical progress content, monotonic
  server revision, content fingerprint, client revision, server timestamp, and
  last accepted operation ID.
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
  mutations. App Check and Crashlytics are enabled before public testing.
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

### 3. Add offline-first cloud progress

- Introduce a progress repository above local storage and Firestore sync.
- Upload revisioned snapshots, record the last acknowledged cloud revision,
  and surface pending/synced/conflict/error status in Settings.
- Resolve common conflicts automatically only when ancestry is known. Require a
  preview and explicit choice for divergent valuable progress.
- Keep JSON export as a user-controlled recovery path.

Exit gate: offline play, reconnect, two-device conflicts, corrupted local data,
and interrupted writes are covered by automated and manual tests.

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

## Immediate implementation sequence

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
