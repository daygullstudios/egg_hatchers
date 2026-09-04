# Egg Hatchers Platform Architecture Workplan

Updated: 2026-09-04

## Goal

Ship Egg Hatchers as one Flutter game across iOS, Android, desktop web, and
mobile web without risking existing local progress. Use Railcade as the model
for account linking, offline-first saves, web delivery, diagnostics, and mobile
web policy. Use Grids & Aces as the model for durable multiplayer identity,
sessions, reconnects, transactions, and preset-only player communication.

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
