# Nestarium Platform Architecture Workplan

The 2026-09-06 product rebrand is recorded in `NESTARIUM_MIGRATION.md`.
`playnestarium.com` is selected; its protected playtest hostname is staged but
unrouted until provider branding and origin-recovery acceptance. Technical
save/project/bundle identities below remain compatibility contracts.

Updated: 2026-09-07

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

## Approved six-milestone v1 finish line — 2026-09-07

This is the current execution order, approved by Tony after the credit/scope
discussion. It supersedes historical "next" work below. Do not turn an open
hardening inventory into an indefinite pre-release project.

1. **First-player journey:** fresh guest, tutorial, first hatch, visible income,
   upgrade, Collection/Quests and save/reopen. Fix demonstrated obstacles only.
   Automated acceptance now passes at 320x568 and 390x844; representative human
   comprehension remains part of milestone 5, not a claim made by widget tests.
2. **Family-audience requirements:** close the child-compatible identity,
   data-collection, privacy and necessary consent decisions for the confirmed
   ages 8–12 plus teens/adults. Record exact owner/professional review gates;
   do not infer compliance or enable new SDK collection from a generic approval.
   Requirements/source review is recorded in `FAMILY_AUDIENCE_V1.md`. A hosted
   capability issuance/revocation enforcement seam is implemented but inactive;
   the actual consent/guardian decision and local/cloud gating remain open.
   Tony selected Roblox as the age/parent-control product model;
   classification/territories and consent/retention implementation
   remain open. This milestone is not complete.
3. **Multiplayer completion and continuity/platform acceptance:** multiplayer
   remains a v1 target; its proposed deferral was not approved. Complete the four
   bounded packages under phase 5 below, then verify account/save and delivery
   behavior of the actual v1 launch platforms. Use existing valid evidence;
   native/physical-device steps require the appropriate host and human checks.
4. **Public Nestarium readiness:** finish provider/support/policy readiness and
   the coordinated protected hostname/origin-recovery gates. Keep the new public
   domain unrouted until those gates pass together.
5. **One consolidated release candidate:** freeze the candidate, run the launch
   platform/release checks once, and do representative child/teen/adult and device
   playtesting. Recheck only surfaces invalidated by subsequent corrections.
6. **Release decision and stop:** resolve only remaining launch blockers, obtain
   required owner publication/store decisions, publish the approved ready scope,
   and stop. Optional enhancements go to post-v1, not another automatic workstream.

During implementation use focused checks and sensible related batches. Run the
repository's required analyze/test/web-build/playtest sequence once at a completed
user-facing integration checkpoint, not after each small edit. No automatic
version bumps, tags, native rebuilds or release-candidate dossiers for micro-fixes.
Auxiliary reward/reference writers and speculative extra robustness are deferred
unless a demonstrated release-blocking defect makes a specific repair necessary.
Finish existing multiplayer for release; additional multiplayer modes/social
features and future events do not silently enlarge this finish line. This
clarifies required work inside the six milestones, not a claim that all six are
equally sized or that the remaining work is only a few small patches.

## Four delivery batches — owner-requested execution cadence

Tony requested grouping the estimated 12–16 remaining implementation units into
larger coherent batches, without stopping for another "proceed" between small
changes. This changes execution cadence, not product scope or release authority.
The six milestones above remain acceptance gates; these four batches package the
remaining work across those gates. Estimates are planning ranges, not a promise
of a fixed number of commits or turns. Do not count this planning update as a
completed implementation unit.

1. **Accounts, family controls and hosted foundation (about 4–5 units).** Close
   the reviewed age/guardian capability contract; implement the corresponding
   account, cloud-recovery and consent/revocation boundaries; connect verified
   identity to protected hosted sessions. Preserve existing saves and UIDs.
   Done: permitted test accounts recover progress and join the same hosted test
   session; restricted/unknown accounts cannot bypass their capabilities. Work
   on the isolated hosted foundation while external consent decisions are open,
   but do not present test allowlisting as parental consent or enable child cloud/
   social access prematurely. No economy-bearing online rewards/trades yet.
2. **Complete multiplayer gameplay and its shared economy (about 4–5 units).**
   Integrate existing battles/invites/preset messages with server-owned inventory,
   match results, ratings and atomic trades. Finish safe peer disclosure,
   block/report/abuse controls and disconnect/restart/retry handling.
   Done: two permitted players complete battles and trades with consistent saved
   outcomes; forged inventory, replayed results, simultaneous offers and connection
   loss cannot duplicate rewards or cause one-sided loss. Keep Bot Arena.
3. **Platform and public Nestarium readiness (about 3–4 units).** Finish the
   actual launch-platform account/provider and recovery acceptance, mobile-web
   behavior, accurate policies/support and coordinated protected hostname cutover.
   Reuse existing mail/domain/build evidence where it remains valid. Apple work
   stays on the Mac; request one concise human/device sequence when necessary.
   Done: the selected platforms and protected Nestarium origin pass the stated
   continuity/protection gates and public release materials match the runtime.
   This is readiness, not automatic public launch or a store submission.
4. **One release candidate, blocker fixes and release decision (about 1–2 units).**
   Freeze the candidate, run the consolidated required release checks and
   representative child/teen/adult/device QA. Fix demonstrated launch blockers
   only and recheck affected surfaces. Obtain required final owner publication/
   store decisions; publish only the authorized scope, then stop. Optional polish,
   new modes/events and speculative hardening remain outside the release batch.

Execution rules:

- Continue through related implementation, focused tests and corrections without
  asking for approval already given. A small commit is not a conversational stop.
  Batch checkpoints are concise progress reports, not automatic permission asks.
- Keep reviewable commits and automatically push verified intended changes under
  the Git rules. Use focused checks during development and the required Flutter/
  protected-deployment sequence at a completed user-facing integration boundary,
  normally once per coherent batch. Dependency-sensitive backend deployments may
  need their own focused checkpoint; do not deploy unverified partial behavior
  just to satisfy a count or skip necessary verification to force one deployment.
- Stop for a genuine missing owner decision/credential interaction, required
  professional or physical-device acceptance, meaningful scope/cost expansion,
  or the final release-authority gate. Exhaust safe independent in-scope work
  before treating an external dependency as a complete development blocker.
- Track completed batches and remaining acceptance, not lines changed. Explain
  any material increase to the 12–16-unit estimate before extending the scope.
  Do not rerun the full RC matrix for each internal unit.

Current status: **0/4 delivery batches complete.** Batch 1's authenticated hosted
foundation is deployed on the legacy protected playtest route, while reviewed
family consent/retention/deletion remains externally gated. Protected direct
matchmaking is active; server-run battles, a 30-second reconnect window and
authoritative replay-safe result settlement are deployed as safe independent
Batch 2 progress. A server-owned Online Roster now gates hosted battle teams;
atomic hosted trades exchange only extra roster copies and retain one battle
copy. Automatic global presence and discovery/invites remain off. Preset-only
trade messages and trading are enabled only in the Access-protected capability
mode; this is test access, not parental consent or a public capability decision.
Live two-browser matching, authoritative damage, reconnect/pause, no-result
expiry, confirmed forfeit, exact-once reward acceptance and a reciprocal atomic
trade now pass on the protected deployment. Hosted online rating and win/loss/
streak history remain isolated from Rival Arena. Each UID's first completed
hosted match per UTC day now grants one server-owned roster copy to both players
from a rating-gated pool; a unique daily grant row prevents repeat farming.
Preset-only report/block controls, two-way match exclusion, Durable Object
eviction/hibernation and duplicate-session replacement now pass automated
acceptance. A versioned trusted-claim seam now fails closed for missing or stale
family-policy decisions and independently enforces battle, trading and preset-
message permissions. Preferred future `trusted_registry` mode now reads time-
limited, revocable, pseudonymous D1 decisions; no decision has been issued and
the protected configuration remains unchanged. Reports are centralized in D1
with 180-day retention while local shard copies support retry. The protected
compatibility pool accepts 32 simultaneous sessions, forms 16 isolated matches
in automated acceptance and returns a
recoverable `503` at the explicit guardrail. This closes basic protected-pool
load behavior. A deterministic versioned shard router is now implemented with
a fail-closed activation interlock: the live `protected-v1` compatibility pool
still maps to its exact existing Durable Object, while any future multi-shard
topology requires a new immutable generation and an explicit migration-ready
mode. Private Durable Object RPC now supplies explicit drain/read-only controls,
paginated per-player export and transactional idempotent import with SHA-256
checksums and manifest receipts. No roster data or public route has moved. An
encrypted local operator now orchestrates those primitives through an internal
remote service binding and requires an exact generation confirmation for writes.
Its live status-only acceptance changed no data. The isolated Access-protected
two-shard canary is now deployed on a dedicated non-public hostname; both empty
shards pass private status acceptance and anonymous requests are denied by
Access. Authenticated multi-client behavior and 32-session per-shard saturation
now pass on the live canary, with measured burst WebSocket-open p95 below 4.6
seconds and full cleanup back to two pre-test Firebase accounts. The reviewed
family consent/decision process and representative human/device/network acceptance
remain open. See `MULTIPLAYER_SHARD_MIGRATION.md` and
`PROJECT_HANDOFF.md` for exact versions/evidence.

The final two-unit engineering burn-down is complete as of September 7: central
safety/capability authority, then consolidated public-origin readiness and
accurate policy copy. No further implementation unit is authorized before the
remaining external review, provider, representative device/person/network
and final-publication gates. This does not mark the four delivery batches or six
release milestones complete; it records the requested stopping point and keeps
open acceptance work from becoming an indefinite automatic coding backlog.

Web lifecycle acceptance now includes a versioned selective resume coordinator:
restore meaningful route/substate and safe local drafts/scroll position; use a
server match ID/reconnect token for multiplayer; reject expired/incompatible
checkpoints and fall back to Hatchery. Do not serialize process memory or sync
transient menus through Firestore. Firestore/server storage owns durable player
and economy truth, Router/URL history owns meaningful browser location, and
device-local storage owns low-risk presentation state. Validate refresh, crash,
tab suspension and back/forward behavior across the major launch flows.

### Historical implementation inventory (not an instruction to continue in order)

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
   Player-switch recovery removes the reproduced wait on unfinished lobby close,
   retires stale connections, serializes selection and prevents cloud/presence
   publication before the selected save loads. Failure offers retry or the local
   picker; whole-app tests cover the actual route, overlap and untouched local
   data. `PROJECT_HANDOFF.md` owns release/live acceptance; no data reset or new
   identity is a workaround. Full offline bootstrap/recovery remains separate.
   Import safety now reviews nested payloads before an explicit two-step local
   replacement confirmation, pauses/drains runtime writers and applies only at
   restart before Firebase/game initialization. Checked recovery journaling and
   exclusive updated-tab coordination protect interrupted replacement; chooser
   cancellation releases its pending operation. Device guest identity and sync
   ancestry never transfer in a file. Mock tests cover failures and old formats;
   no real QA save is replaced. `PROJECT_HANDOFF.md` records the current gates.
   Unreadable account metadata now pauses startup before guest creation,
   migrations, identity or game initialization. Retry reloads/coalesces; backup
   preserves readable raw values, and reviewed file restore uses checked restart
   bootstrap without flushing a default player. Lifecycle saves cannot run before
   initialization. Valid legacy profiles and pre-account migration remain supported.
   Primary/backup progress loading now fails closed instead of treating unreadable
   copies as a new game or silently restoring a backup. Selected progress is read
   before identity startup; failed reads/switches/runtime saves pause writers and
   cloud publication. Web backup review uses two-step confirmation and checked
   exclusive bootstrap recovery with a retained raw-pair archive, not a full import
   or identity rotation. Progress reads avoid replacing the shared settings cache.
   Local-first startup now opens valid local gameplay without waiting for Firebase
   core or identity restoration. SDK/identity retries are single-flight; delayed
   results recheck player/slot ownership. Mandatory local checks remain fail-closed,
   with slow-loading guidance rather than reset/bypass. Import staging drains
   identity too; same-identity resume retains unresolved cloud decisions. This is
   not a promise of cold offline web asset delivery or child-auth acceptance.
   Gameplay writes now serialize and verify primary/backup backend acceptance and
   read-back. Failed or slow writes hold the current progress behind a recovery
   screen, pause play/income/cloud changes and offer checked retry plus a read-only
   full backup when storage is readable. A memory-only emergency snapshot remains
   available when reads hang; it is not a normal import and may need support.
   Pending cloud choices survive without choosing a winner. Updated-tab locks and
   loaded-save baselines reject unexpected copies; exit warnings are best-effort.
   Cloud-sync checkpoint writes/removals now verify backend acceptance and fresh
   read-back under serialized key ownership. Failure preserves locally saved play
   but pauses automatic cloud changes. Explicit confirmation retry does not replay
   an earlier replacement; fresh divergence requires review. Slow writes stay
   single-flight and late confirmations cannot publish into another player's UI.
   Device settings now share checked, serialized writes and fresh backend reads.
   Failed/slow operations retain session choices and show a persistent recovery
   action across routes without pausing gameplay. Retry verifies uncertain writes
   without repeating them; mute does not wait for storage. Pending settings block
   normal save transfer before writer pause/staging, with safe cancellation.
   Custom egg/sprite writes and removals now verify backend acceptance/read-back
   before publishing. Editors retain drafts after failures, offer non-overlapping
   retry and ask before discarding; reset confirms its scope and reports partial
   results. Egg records preserve unknown fields and the new-player empty namespace;
   account tokens prevent stale editors writing to the next player. Art reset keeps
   rating-claim history. Draft exit warnings compose with progress/settings warnings;
   import preflight and quest notices respect the active editor. These are memory
   drafts, not durable autosaves or automatic conflict replacement.
   **Deferred inventory: auxiliary writers**, especially rating claims/reference unlocks and
   preference-like metadata, followed by checked profile/directory writes/removal.
   Native recovery and representative human acceptance
   remain open. `PROJECT_HANDOFF.md` owns exact validation/live evidence. Trusted cloud erasure
   and child-compatible identity remain separate, deliberately authorized work.
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
   text scaling and empty/locked/error states. Preserve the compact phone
   composition, adaptive game-shell boundary, coin strip, navigation selection
   and per-destination scroll position.
5. **Consequential actions:** preview what fusion, rebirth, imports, trades and
   resets consume, preserve and may lose. Explain probabilities plainly; do
   not rely on color, icons or hover-only help. Review streak/time pressure and
   monetization for the intended ages before activating it.
   The owner has now approved free core play, bounded banners and a $2.99
   account-scoped lifetime ad-removal product. Its fail-closed code boundary is
   implemented but activation remains part of the family/provider/platform
   release batch. See `MONETIZATION_AND_AD_OPERATIONS.md` for placement and
   activation acceptance; interstitials, rewarded ads and paid random eggs are
   outside the current release scope.
6. **Finish external rebrand:** approve truthful public-site policies/support,
   complete provider/identity/recovery acceptance, then coordinate the protected
   hostname cutover. Display-name mail polish follows data safety. Keep store
   actions at the authorized release boundary and legacy save/infra IDs intact.
7. **Durable multiplayer:** proceed after identity, child-safety and progress
   boundaries are sound. Retain Bot Arena and preset-only communication.

### Usability acceptance for each relevant implementation

- Test 320px/390px/430px compact widths, 600–800px tablet widths, 900px and
  1200px-plus expanded widths, short-height windows and the wide-desktop
  surround; include normal and 200% text. Do not shrink text to hide overflows.
  Long dialog content must scroll while decisions remain reachable. Resizing
  must retain the active destination and meaningful scroll/selection/draft state.
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

**September 7 source assessment:** existing matchmaking, direct invitations,
server-run combat, preset messages and confirmed trade flows are implemented.
`test/multiplayer_service_test.dart` exercises two clients against the real local
Dart server, including shared energy/damage state and invalid-animal rejection;
`test/online_lobby_service_test.dart` covers invitations/messages and confirmed
trades. These are part of the preceding passing 786-test checkpoint, not evidence
of a production multiplayer deployment. No repeat full suite is needed for this
documentation assessment.

The actual gaps are bounded into four completion packages:

1. **Hosted authenticated sessions:** the playtest Wrangler configuration serves
   static assets only; it does not deploy `tool/multiplayer_server.dart`. That
   server upgrades WebSockets without Firebase-token verification and accepts
   client-supplied player IDs. Connect the hosted backend to canonical verified
   identity and server-checked capabilities, preserving current UIDs/save owners.
   Acceptance: two authorized remote clients can match; forged/expired identity
   or disallowed capability cannot join, and old-client paths cannot bypass it.
2. **Trusted inventory and settlement:** the server recalculates battle power,
   but trusts supplied animals/levels/rating/inventory after shape/range checks.
   Battles calculate/apply rewards in the Flutter screen; trade completion sends
   separate messages for clients to apply locally. Implement authoritative,
   replay-safe match results and atomic trades over an approved inventory
   baseline. Reading an otherwise client-writable cloud save does not make it
   authoritative. Preserve existing progress; do not reset players to solve this.
   Acceptance: forged inventory, duplicate result delivery and concurrent offers
   cannot mint rewards/animals or cause one-sided loss.
   Server-issued battle settlement, receipt redelivery/acknowledgement and
   separate online ratings are complete. Fixed hosted coin rewards do not trust
   submitted team power. Hosted battles now validate teams against a Durable
   Object Online Roster, and atomic SQLite trades move only extra roster copies,
   preserve one battle copy, increment both revisions and redeliver completion
   receipts until acknowledged. The local Hatchery Collection remains separate
   because its offline/client-writable saves are not safe trade authority.
   The first completed match per server day grants both participants one roster
   copy from a rating-gated pool inside the same settlement transaction. Unique
   grant IDs prevent replay/farming, and the scrollable mobile result overlay
   identifies the drop. The protected vertical slice now passes this package's
   inventory/settlement/trade acceptance; production-scale partitioning and
   economy balancing remain launch-capacity/RC checks rather than client trust.
3. **Family-safe participation:** integrate the Roblox-informed capability/parent
   model in `FAMILY_AUDIENCE_V1.md`; separate gameplay from public discovery,
   profile disclosure, messaging and trading. Enforce safe names, minimum peer
   disclosure, block/report handling and practical abuse limits. No free-text
   chat/voice, public-art expansion or new social modes. Acceptance: restricted
   accounts cannot bypass capabilities through lobby startup, invites, deep links,
   reconnects or another profile; allowed family play works with preset messages.
   The isolated safety slice is complete: the server derives the current peer,
   accepts only four preset report reasons, deduplicates/rate-limits reports and
   enforces blocks across both future battle and trade matchmaking. Active trade
   blocks cancel before inventory moves; battle outcomes are unchanged. Final
   age/guardian capabilities, review/deletion operations and a user-managed
   blocked-player list remain open.
4. **Failure recovery and one integrated acceptance:** hosted sessions, battles,
   inventories, trades and receipts are Durable Object SQLite state. Battle
   disconnects pause for 30 seconds and expiry creates no result; confirmed
   forfeits settle normally. A trade disconnect before both confirmations now has
   explicit test evidence that both rosters remain unchanged. Finish Durable
   Object eviction/hibernation and duplicate-session replacement now pass
   automated Worker acceptance, including a safety action processed after the
   active socket is hibernated and restored. Basic load/capacity and two-device
   play acceptance using disposable accounts remain open.
   Reuse focused checks while implementing; join the single consolidated RC
   milestone rather than repeating a full release matrix after every patch.

These are substantive backend/integration packages, not four tiny edits or a
calendar estimate. Next implementation starts with the hosted identity/session
contract and a protected two-client vertical slice, not more unrelated local-save
hardening. Verify the existing studio backend model before choosing the hosting
runtime; this assessment does not authorize or perform a provider migration.
Exit gate: all four package acceptances pass for the defined launch scope. Bot
Arena remains until separately approved for removal. Any proposal to defer
multiplayer or trading must be an explicit owner scope decision, not a silent cut.

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
