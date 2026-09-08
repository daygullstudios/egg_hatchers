# Nestarium Project Handoff

Updated: 2026-09-08

## Legacy Daygull playtest hostname retired

At the owner's direction on 2026-09-08,
`egg-hatchers-playtest.daygullstudios.com` was retired rather than retained as a
compatibility origin. The static and `/ws*` Wrangler routes were removed and
deployed. Cloudflare public DNS then returned NXDOMAIN and HTTPS could no longer
resolve the hostname. `playtest.playnestarium.com` remains healthy behind Access
(anonymous HTTP 302). Current versions are static Worker
`addf225a-6d3f-4d19-9201-11d9d8a7db9c` and multiplayer Worker
`7e5a1674-7389-40d8-aefb-0bdce354fdec`.

The retired hostname was also removed from Firebase Authentication's authorized
domains by a narrow Identity Toolkit update; read-back preserves localhost, the
two Firebase defaults, `playtest.playnestarium.com`, and `playnestarium.com`.
Worker resource/package/Firebase IDs and all Durable Object/D1 data remain
unchanged. There is no redirect, and browser storage, anonymous identity and
Access cookies from the old origin did not migrate.

One control-plane cleanup remains: Cloudflare Access application
`2ed23c5f-4d30-42e9-83c4-90b4e24c2135` still lists the dead legacy hostname as
a destination. Its dashboard edit was staged but deliberately not saved because
the UI action required a final confirmation, and the browser connection then
ended. Remove only that destination; preserve `playtest.playnestarium.com`,
`nestarium-mp-canary.daygullstudios.com`, policy `Tony — Google access`, the
24-hour session and all other settings. The stale Access entry does not make the
NXDOMAIN hostname reachable.

## Disposable Firestore QA reset

On 2026-09-08, with the owner's explicit confirmation that all current
Nestarium cloud progress was disposable test data, the `users` collection in
the dedicated `egg-hatchers-dev` `(default)` Firestore database was recursively
cleared. The client-owned documents affected were the recreatable progress
records at `users/<uid>/products/egg_hatchers`. A separate authenticated,
read-only Firestore REST query after the operation returned no documents in
`users`.

The reset did **not** delete Firebase Authentication users or provider links,
RevenueCat/store purchases or entitlements, Cloudflare multiplayer Durable
Object/D1 authority and safety records, Firebase configuration, Security Rules,
indexes, or credentials. The Samsung Nestarium install was already absent, and
no Nestarium localhost or playtest browser tab was open on this PC when the
reset ran, preventing an old local save from immediately repopulating the
collection.

For future owner requests, **“clear all disposable test data from Firestore”**
means: first verify the named development project and current repository-owned
progress paths, stop active clients that could re-upload old state, then remove
only recreatable Firestore test progress and verify the result. It never implies
deleting Auth identities, purchase/entitlement records, multiplayer authority or
safety data, production data, or backend configuration. Ask for clarification
instead of widening the scope if the project or disposable paths are ambiguous.

## Monetization decision and dormant implementation

The owner approved free core play, carefully placed anchored banners and a
**$2.99 lifetime Remove Ads** product. An honest, time-bounded $1.99 launch
promotion remains optional. Paid randomized eggs, premium currency,
interstitials and rewarded ads are not approved for launch.

The app now has a central default-off monetization boundary, per-Firebase-UID
RevenueCat `ad_free` ownership, native AdMob/UMP adaptive banners, exact shell
placement rules and conditional Settings purchase/restore controls. Unknown
audience treatment, uncertain entitlement, missing provider configuration,
consent failure or an owned entitlement suppresses ads. The web provider is
deliberately unavailable. Google sample app IDs are test-only; there are no real
ad units, store products, API keys, production requests or checkout in the
protected build. `docs/MONETIZATION_AND_AD_OPERATIONS.md` owns the price,
placement and activation contract. Family classification/capabilities,
provider-console work, real IDs/products, disclosures and sandbox acceptance
remain Batch 3 gates.

Integration evidence (2026-09-08): Flutter analysis is clean and all **819
Flutter tests** pass, including six dedicated price, activation, audience,
entitlement, ownership and placement checks. The protected hosted release and
Wasm dry run succeeded with monetization approval omitted, followed in order by
all **4 playtest tests**, Wrangler dry run and deployment. Both protected custom
domains serve Worker version **`54c1d07a-a4be-494e-9c31-f66fbd015674`** and
anonymous checks still receive Cloudflare Access 302. The playtest therefore
contains the dormant boundary but displays no ads, purchase UI or public
monetization claim.

The Android debug build also succeeds with the registered AdMob and RevenueCat
plugins, delayed measurement metadata and test-only Google application ID. iOS
linking and native sandbox purchase/ad acceptance still require the established
Mac release host at the later provider checkpoint.

**Android test scheduling (owner direction):** Grids & Aces currently has the
only physical Android device reserved for Google Play purchase testing. Do not
interrupt or replace that installation. Nestarium continues through family,
multiplayer, provider/store preparation, web QA and Android build work now; one
consolidated physical Google Play install/purchase/cancel/restore/reinstall/
account-recovery pass is queued for the Batch 4 candidate after the device is
released. This changes order, not the Android release requirement.

**Fresh Samsung QA install (owner override, 2026-09-08):** after Nestarium was
uninstalled and disposable Firestore progress was cleared, the owner explicitly
requested a new general-QA sideload on the connected SM-A166U. The existing
verified Android debug APK (`1.0.0+1`) installed successfully as a fresh package,
cold-launched into the foreground and retained a live process with no sampled
Flutter/Android fatal error. This deliberately supersedes the temporary device
reservation only for the requested Nestarium install. It is not Google Play
billing acceptance and does not satisfy the later purchase/cancel/restore/
reinstall gate.

## Public Nestarium preview is live

`https://playnestarium.com/` is now a public, indexable, non-playable preview
with approved Nestarium art, feature/creature previews, planned iOS/Android/web
availability, launch-notice mail actions, support, privacy, website terms and
account/data-request pages. The exact `launch@playnestarium.com` Email Routing
rule forwards to the existing verified studio destination. No form, tracker,
subscriber database, game bundle, Firebase configuration or playtest link is
published. Worker version: `d62054c3-09e5-46b7-8fa4-2c4dbbd0a8d4`.

Daygull Studios now says “Three worlds” and presents Nestarium as an equal
sibling beside Grids & Aces and Railcade, with a live preview link and matching
one-time launch-notice action. Daygull Worker version:
`459978b1-21c3-40b4-8c86-66adfdb2b949`. Its static-asset path was also corrected
to use a strict owned-asset allowlist; known product art returns 200 and unknown
assets remain 404. Public game access, child-account controls, stores and the
protected Nestarium hostname migration remain separate gates.

## Primary protected Nestarium hostname is live

`https://playtest.playnestarium.com/` is now the only routed private game
origin. The former Daygull compatibility hostname was retired as documented in
the current checkpoint above. The static Worker keeps its legacy resource
identity only for deployment and rollback continuity.

Cloudflare public DNS resolves the Nestarium host. Anonymous `/`,
`/main.dart.js` and `/ws/health` requests receive Access 302. This PC's ISP gateway
continued serving its prior negative DNS cache after OS flush, so authenticated
visual acceptance on the new host remains pending until that recursive cache
expires or the network resolver refreshes; direct public-resolver/live-origin
checks passed. Flutter analysis, all 807 Flutter tests, release web/Wasm dry
run, four playtest config tests, multiplayer typecheck/28 tests, public-site
isolation tests and both Wrangler dry runs/deployments passed.

## Adaptive tablet and desktop workspace

The former root-level 430px portrait clamp is superseded. The app surface is
now bounded at 1180 logical pixels with the neutral surround retained outside
that boundary. Compact screens preserve the established 430px phone layout;
600–899px screens use a wider single-column tablet workspace; and 900px-plus
screens use deliberate multi-pane compositions. Focused routes such as manual
battles, editors, recovery flows and tutorials still opt into phone-width
content instead of being stretched automatically.

Expanded Hatchery separates progression from its Production Snapshot. Shop,
Collection, Battles, Quests and Custom Animals separate navigation/tools from
their working catalogs or progression surfaces. Collection and Custom Animals
use two-column result grids where card width remains readable. Settings uses a
two-column collapsed dashboard and centers one focused 760px panel when a
section opens. Desktop navigation exposes all seven primary destinations;
compact and tablet navigation keeps the established four destinations plus
More. The shell's IndexedStack, PageStorage keys and existing state objects
preserve route selection, scroll, accordions, filters and drafts across tab
switches and live window resizing. Multiplayer invitations/notices now anchor
to the adaptive game workspace rather than the obsolete phone-column edge.

Integration evidence (2026-09-08): Flutter 3.47.2 analysis is clean and all
**813 Flutter tests** pass. The protected hosted release build completed with
the required playtest feature flags, followed in order by all **4 playtest
tests**, Wrangler 4.129.0 dry run and deployment. Both protected custom-domain
routes now serve static Worker version
**`dc6c13d9-ae3c-468c-bf73-a8815fcd9c72`**; anonymous requests to each origin
remain **302 to Cloudflare Access**. Authenticated external Chrome acceptance
verified the wide Hatchery, Battles, Custom Animals and Settings layouts,
including Settings' focused expanded panel. Compact 390px and tablet 760px
checks passed locally, and a live 1280→390→1280 resize retained the selected
Settings destination and open section. The browser console has no application
errors; only the pre-existing Noto fallback-font warning remains.

## Current execution cadence — four grouped delivery batches

Tony asked to combine the estimated 12–16 implementation units into coherent
batches without another "proceed" after every small change. The workplan now
defines four delivery batches with explicit done criteria:

1. Accounts, reviewed family controls and protected authenticated hosting.
2. Complete multiplayer, trusted results/inventory/trades and recovery/safety.
3. Launch-platform, provider, policy/support and protected Nestarium-origin readiness.
4. One consolidated release candidate, blocker fixes and authorized release/stop.

Keep the existing six milestone gates; grouping is not new feature scope or
permission to bypass consent, human/device QA, public-hostname protection or
final publication/store decisions. Continue through internal edits and focused
checks without repeated approval requests. Report meaningful batch checkpoints;
run normal integration/deployment gates for completed user-facing batches, not
a full RC matrix per small patch. Reviewable verified commits/pushes still apply.

**Status: 0/4 grouped batches complete.** Batch 1's hosted-identity foundation
is implemented and live on the protected playtest, while its reviewed family
identity/consent/retention decisions remain an external gate. Safe independent
Batch 2 work has begun: server-run battles and reconnect recovery are deployed,
and live two-browser multiplayer acceptance now passes. Authoritative,
replay-safe battle settlement, a server-owned Online Roster and atomic hosted
trades are deployed. The first completed hosted match per UTC day now grants
both participants one server-owned roster animal from a rating-gated pool.
Preset-only report/block controls and server-enforced matchmaking blocks are
also deployed. Durable Object eviction/hibernation and duplicate-session
acceptance now pass automatically. The versioned trusted-claim enforcement seam
and explicit protected-pool capacity behavior are implemented. The public shard
router/interlock, migration design, private per-player migration RPC, encrypted
local operator and isolated Access-protected two-shard canary are also complete.
Central report retention and a D1-backed family-capability issuance/revocation
boundary are now implemented without enabling public capabilities. Authenticated
two-client and bounded per-shard canary load/latency acceptance now pass. The
actual reviewed consent/guardian decision and representative human/device/network
acceptance remain open. Do not call either batch complete.

The capability/capacity tail now supports `trusted_registry` for a future public
Worker. It reads a versioned, time-limited server-side D1 decision keyed only by
a SHA-256 subject hash; missing, denied, expired, revoked or stale decisions fail
closed. `trusted_claims` remains a compatibility mode but is not the preferred
public authority.
Online battle and trading are separate permissions, and preset trade messages
remain independently gated. This is an enforcement contract, not a consent
system: the private operator can issue/revoke only the technical hosted-feature
decision after an approved review supplies its opaque reference. The existing
Access-protected mode remains deliberately permissive for approved testers and
is still not evidence of age or guardian permission. No live decision was issued.

The existing compatibility pool now admits at most 32 distinct live sessions.
A replacement socket for the same UID remains recoverable; a 33rd distinct
session receives `503` with `Retry-After: 3` instead of relying on eventual
Durable Object overload. Automated acceptance opens 32 sessions, forms 16
isolated matches with unique match IDs, and proves the guardrail. This closes
basic protected-pool behavior only. Cloudflare's current guidance describes one
Durable Object as single-threaded with horizontal scale across objects, so a
public release still needs an approved shard topology and migration that keeps
the existing roster namespace intact.

That public-scale routing foundation is now implemented without activating it.
The deployed configuration uses `protected-v1`, shard count `1` and
`single_compatibility`, so every existing player reaches the exact same Durable
Object as before. Deterministic FNV-1a UID routing is available only for a new
immutable generation in explicit `sharded_migration_ready` mode; the router
refuses to shard `protected-v1` and fails closed on invalid counts or modes.
`docs/MULTIPLAYER_SHARD_MIGRATION.md` defines the required private manifest,
drain, idempotent export/import, checksum, canary, cutover and rollback process.
No roster record, public hostname or Firebase identity moved in this checkpoint.

Private Durable Object RPC now enforces the operational boundary as well. A
generation moves explicitly from `active` to `draining` to `read_only`; entering
maintenance closes idle/queued sockets, rejects new connections and waits for
open battles/trades to drain. Only a drained read-only generation can list UIDs,
export player authority or import it. Exports include arena account, Online
Roster/revision/grants, unacknowledged battle/trade receipts and both directions
of block rows. SHA-256 checksums detect changed bundles; transactional import
receipts keyed by manifest ID and UID make a retry idempotent and reject a
conflicting replay. Sessions, active battles/trades, reports, display names,
tokens and credentials are not exported. There is no public HTTP admin route.

The local operator connects to a named `MultiplayerOperator` Worker entrypoint
through a Cloudflare remote service binding, not a public admin hostname. The
old header-guarded HTTP migration bridge was removed from the default Worker
handler, including the whole-host canary surface. It produces AES-256-GCM
encrypted, no-overwrite artifacts;
accepts the passphrase only through `NESTARIUM_MIGRATION_PASSPHRASE`; verifies
the aggregate manifest checksum; and requires the exact target generation name
on every mutating command. Its live status-only acceptance read `protected-v1`
as active with zero sockets, battles and trades. No drain, freeze, export, import
or activation command ran. The isolated `canary-v1` two-shard Worker is now live
at the dedicated custom domain `nestarium-mp-canary.daygullstudios.com`. The
existing Nestarium Access application lists it as a third destination. Public
DNS resolves, anonymous `/ws/health` receives Access 302, and private read-only
operator checks show both `canary-v1-shard-00` and `canary-v1-shard-01` active,
empty and drained. It has its own Worker/Durable Object namespace and cannot
read `protected-v1`; no player export/import or migration-mode mutation ran.

Live authenticated canary acceptance on 2026-09-07 used a temporary, undeployed
Flutter build pointed at the isolated hostname. Two distinct local browser origins
restored separate anonymous Firebase identities, connected through the existing
Cloudflare Access tester session, matched into one server-owned battle and appeared
only on `canary-v1-shard-00`. A bounded browser harness then created tokens only in
memory and targeted 33 disposable identities to each deterministic shard. Shard 0
already contained the two real clients, so it admitted 30 harness sockets for 32
total, formed 15 harness matches plus the existing match, and rejected the next
three. Shard 1 admitted 32, formed 16 matches and rejected the 33rd. Aggregate
WebSocket-open latency was p50 1,429 ms / p95 4,532 ms / max 4,670 ms on shard 0
and p50 1,425 ms / p95 4,134 ms / max 4,493 ms on shard 1 during the simultaneous
burst. All 71 harness identities and both Flutter app-test identities were deleted;
an Auth export confirmed the project returned to its two pre-test accounts. After
the 30-second reconnect window, private status showed both shards active, empty
and drained. The temporary harness and sensitive export were removed.

This run used 68 WebSocket upgrade attempts plus a bounded number of messages.
Under Cloudflare's current Standard pricing, Worker WebSocket upgrades count as
requests while routed messages do not; Durable Objects separately include one
million monthly requests and bill WebSocket messages at their documented ratio.
The run is far below the shared account's included allocations, so its modeled
incremental charge is zero if the account has not already exhausted those account-
wide inclusions. This is a bounded cost model, not an invoice or representative
public-traffic forecast. The Worker/canary versions, Access policy, routes, D1,
player authority and migration modes were unchanged.

The current settlement checkpoint persists one Durable Object receipt per UID
and match, server-owned online rating, fixed hosted rewards and an explicit
client acknowledgement only after the local/cloud-capable save path completes.
Unacknowledged receipts are redelivered; the PlayerState receipt ledger makes
reapplication idempotent. Online rating/wins/losses/streaks are separate from
Rival Arena history. The server reward intentionally does not scale from local
Hatchery Collection power. Hosted battles now accept only animals from each
Firebase UID's Durable Object Online Roster. A first connection mints two each
of Chicken, Mouse and Rabbit; this separate online baseline does not read,
replace or reset the client-writable Hatchery Collection. Hosted trades exchange
only extra Online Roster copies and retain one of each animal for battles.
The server moves both offered copies in one SQLite transaction, increments both
inventory revisions and redelivers unacknowledged completion receipts.

Live trade acceptance on 2026-09-07 used the same isolated Chrome and in-app
browser guest identities. Both received independent six-animal server rosters,
matched through the deployed Worker and completed Chicken for Mouse. Chrome's
tradeable roster became Mouse x3 and Rabbit x2 with its retained Chicken x1
hidden from the extra-copy picker; the isolated client became Chicken x3 and
Rabbit x2 with its retained Mouse x1 hidden. Both saw reciprocal completion
receipts and acknowledged them. Local Hatchery Collection cards and save payloads
were not used as trade authority or mutated by hosted completion.

The deployed daily-drop acceptance then completed one confirmed-forfeit match.
Chrome won at rating 1035 and received Mouse; the isolated client moved to 977
and received Fox despite the loss. Both result overlays named the daily Online
Roster drop, fit the mobile portrait frame, persisted the new roster revision
and acknowledged their settlement. A second same-day reward is denied by a
unique UID/day grant row; the Worker test covers that replay/farming boundary.

The multiplayer safety checkpoint adds one narrow-phone sheet to active and
just-completed hosted battles/trades. It accepts four preset reasons and no free
text or client-selected peer identity. The Durable Object records opaque UIDs,
reason, activity context and timestamps, deduplicates the same reason/peer/day,
caps each reporter at ten unique daily reports. Each accepted report is also
written to the shared `nestarium-safety-authority` D1 database with pseudonymous
subject hashes, source generation/pool and a 180-day expiry; raw UIDs remain only
in the gameplay shard recovery copy. A daily protected-Worker job centralizes
deferred shard copies and prunes expired central rows. Blocks apply in both
directions to battle and trade matchmaking. A trade block cancels before any
Online Roster mutation; a battle
block does not alter the result. Automated acceptance evicts the live Durable
Object with hibernated trade sockets, submits the safety action after restoration,
proves both match queues exclude the blocked pair, and proves a duplicate UID
socket retires the older session. A user-managed blocked-player list and final
moderation/deletion operations remain part of policy/operations review rather
than being falsely presented as complete.

Live acceptance on 2026-09-07 matched isolated Chrome and in-app-browser guest
identities. The in-app client used the new confirmed forfeit path and received
`-12`, `0` coins, `0` tokens and rating `988`; Chrome received `+18`, `250`
coins, `1` token and rating `1018`. Both reloaded from the deployed build,
restored Firebase identity without manual Retry, and retained exactly `988/0`
and `1018/1`; no settlement replay occurred. The test also found and fixed a
startup race where hosted WebSockets opened before Firebase finished restoring
identity, and a save-fingerprint migration regression caused by newly defaulted
PlayerState fields. Existing older progress now validates against either its
exact historical payload or its normalized current form without accepting a
tampered fingerprint.

Deployment safety was corrected after a live reload showed that the generic
Flutter web build silently compiled hosted playtest multiplayer out. `AGENTS.md`
now requires `cloudflare/playtest`'s `npm run build:web`, which preserves the
protected-only feature flags. Final static version
`d25ea84c-4ff9-47a7-a21d-5f7fc701f8d0` is routed only at the existing protected
custom domain. Multiplayer Worker version
`61597463-c8af-4af0-aa62-b8e41d51ce40` is routed only at `/ws*` there.
The last unchanged Flutter checkpoint remains clean at 805 tests. Twenty-six current
Worker tests and two Node operator tests pass, as do Worker typecheck/types and
both protected/canary dry-runs; the preceding release
web/Wasm and static tests/dry-run remain valid because no Flutter/static asset
changed in this tail. Anonymous
requests to both `/` and `/ws/health` still receive Cloudflare Access 302. The
compatibility Worker is version `61597463-c8af-4af0-aa62-b8e41d51ce40`;
isolated canary Worker version `f79e6564-f3cd-4db2-8477-2c103e257b59` owns only
its dedicated Access-protected custom domain. The Nestarium legacy-reference
audit classifies the retained compatibility occurrences with no unclassified
branding.

Desktop/web resilience is now an explicit follow-on acceptance item. Use a
versioned selective resume checkpoint (route and meaningful substate, safe
draft/selection/scroll state, match ID/reconnect token) rather than attempting
to serialize a Flutter process or placing transient menus in Firestore. Durable
account/economy/game truth belongs in Firestore/server storage; meaningful web
location belongs in Router/URL history; low-risk device UI state belongs in
local browser storage. Invalid/expired checkpoints must fall back cleanly.

Application commit `43f2344` adds a separate
`nestarium-multiplayer-playtest` Worker/Durable Object. `/ws` verifies Firebase
ID-token signature, Firebase project audience/issuer, expiry, issued/auth times
and UID before it reaches a session. The Worker replaces submitted player IDs
and names with a derived test alias, persists matched-session records in SQLite,
uses WebSocket hibernation attachments, rate/size limits commands and denies
profile discovery, messages, trades, rewards and other unsupported commands.
`protected_playtest` permits authenticated matchmaking because the entire legacy
playtest hostname is Access-protected; this is explicitly not parental consent.
Production capability mode defaults to trusted token claims and denies unknowns.

The Flutter client now has a read-only Firebase token provider and authenticated
WebSocket protocol contract. Commit `95024af` enables direct hosted test battles
only in the protected playtest build; normal builds remain fail-closed. The UI
locks hosted trading and replaces global discovery/invites with an accurate
protected-matchmaking notice. Local development multiplayer is unchanged.
Automatic root-level lobby presence was removed, so
loading/changing a player no longer attempts to publish their account/name/avatar,
team or collection. Global discovery/invites stay unavailable until their own
capability/safety package passes. Existing local saves, UIDs, Firebase project,
Firestore document and package/bundle IDs are unchanged.

Commit `eeb6730` moved combat timing, energy, validated catalog power, ability
effects, switching and outcomes into the Durable Object. Hosted outcomes still
cannot grant client-local coins, tokens or rating. Commit `a39b901` adds a
30-second authenticated reconnect window: both players' battle clock pauses,
the same Firebase UID resumes the persisted SQLite match state, and expiry
interrupts without choosing or rewarding a winner. The client preserves
the match and shows explicit Reconnect/return states.

Validation: Flutter analysis is clean, all **796 Flutter tests** pass, and the
release web build succeeds including Wasm dry run. Multiplayer Worker typecheck,
seven Worker/pure-battle tests and both Wrangler dry runs pass. Worker version
`15eeab13-094c-47b6-bfca-e3a35e7f8420` is routed only at the existing protected
`egg-hatchers-playtest.daygullstudios.com/ws*`; static version
`feffe8f6-f42c-4230-b291-513f00147f4f` contains the activated protected client.
Live protected acceptance used isolated Chrome and Codex in-app-browser storage,
creating two distinct disposable Firebase guest identities and private peer
aliases. Both three-animal teams matched through the deployed Worker, entered the
same hosted battle, and observed the same server-owned health after a 43-damage
ability. Reloading one client paused the opponent's battle; returning through
Battles > Online Arena inside 30 seconds restored the same 234/277 health state.
A second reload held past the grace window produced `MATCH ENDED` for the peer,
with rating still 1000 and battle tokens still 0: no false winner or reward was
created. This closes the functional two-client browser acceptance item.

The demonstrated reconnect UX defect is corrected: the battle hash is captured
before asynchronous app/bootstrap work can normalize it, recovery waits for the
verified Firebase player identity, and the Worker marks a restored match so the
client reopens the battle without a stale `Opponent found` prompt. A final live
cold-open replay closed one browser, observed the peer's paused state, reopened
the exact battle URL and landed directly in the same fight inside the grace
window. Representative people, physical devices and launch-platform networks
remain separate acceptance gates.
Anonymous requests to both `/` and `/ws/health` return Cloudflare Access 302.
`playnestarium.com` still resolves no public app record. The legal/operational
family controls remain an acceptance gate.

## Family-audience requirements — current decision checkpoint

Milestone 2 requirements are recorded in `docs/FAMILY_AUDIENCE_V1.md`, with
source evidence and current FTC (including May 2026 guidance), Google Play/API,
Firebase, Apple and ICO references. **This milestone is not cleared for release.**
Owner-confirmed ages 8–12 plus teens/adults are not the same as an approved legal
classification, consent process or set of launch territories.

Verified gaps: optional Firebase startup/anonymous identity/core sync still have
no age or guardian-permission boundary. The previous automatic lobby attempt was
removed in `43f2344`; loading a save no longer publishes a global profile. The
new protected backend accepts only authenticated matchmaking and derives peer
aliases, while its Flutter release switch stays off. No parent/consent/revocation
or cloud-erasure runtime was found. The later monetization checkpoint added
default-off AdMob/UMP and RevenueCat boundaries, but they remain unusable until
the same audience/guardian review plus provider, disclosure and release gates
pass. Analytics and Crashlytics remain absent. Dependency inspection is not
proof of zero provider processing or completed native/network acceptance.

Owner follow-up: use Roblox as the age/parent-control product model. The proposed
post-release multiplayer deferral was not approved; multiplayer remains a v1
target. Separate permission to play from discovery/profile/communication/trading
permissions, with stricter child defaults and linked parent controls. Keep preset-
only messages, Bot Arena and all compatibility/save/UID contracts. Do not copy
Roblox's biometric/ID collection or assume its legal classification applies here.
Local-only child saves or a solo-only launch require explicit scope decisions.
Owner/professional review must determine classification, territories, provider
eligibility, consent method, and retention/deletion operations before enabling
the new model. Ordinary Google sign-in is not proof of guardian consent.

Corrected the **unpublished** privacy/terms drafts to state confirmed audience
intent, actual automatic connection attempts, and missing child controls. All
draft markers, false policy/hostname approval gates and unrouted public config
remain intact; `audienceDecisionRecorded: true` records intent only. Ten focused
public-site tests pass, including continued refusal to publish. No Flutter/runtime
change, game rebuild/deploy, repeated RC matrix, cloud deletion, billing, provider,
store or public-hostname action. The preceding protected game version stays live.

**Multiplayer assessment:** the protected Worker now verifies Firebase identity,
owns roster inventory/ratings/results, runs battle state, persists reconnect and
receipt state, and commits roster trades atomically. The local Dart server remains
a development sandbox and does not define hosted trust. Global discovery/invites
stay off; protected trading uses only preset messages and private aliases.

**Implementation burn-down: 2/2 complete.** The final consolidation updated the
unpublished privacy draft to the actual central report retention and inactive
capability registry, then passed its exact allowlisted build, 11 public-site tests,
Wrangler dry run, and Chrome plus isolated-browser semantic review. The guarded
release check correctly still refuses publication. There is no remaining approved
engineering unit before the external gates: reviewed family identity/consent and
final policy, Google/provider cross-origin recovery, representative people/devices/
networks, and owner public/store release
authorization. These are acceptance or decision gates, not grounds to invent
another implementation batch or move current player data.
The workplan records four bounded multiplayer packages: authenticated hosting;
trusted inventory/results/trades; family-safe capabilities; failure recovery and
integrated acceptance. They fit inside the existing six-milestone finish line.
Do not declare milestone 2 complete, infer parental consent from generic owner
approval, or resume deferred auxiliary hardening.

## External acceptance continuation — 2026-09-07

The authenticated canary load gate is closed by the live evidence above. The
standard protected-playtest web build was regenerated afterward and checked to
contain no canary hostname, preventing the temporary acceptance target from
being deployed accidentally.

A fresh authenticated Google/Firebase read found no silent progress: Firebase
Authentication lists only Anonymous as enabled and Google remains disabled.
Google Auth Platform has zero OAuth clients, zero test users and no configured
scopes. The Nestarium name and `support@playnestarium.com` are still correct,
but Google marks the brand incomplete because homepage, privacy, terms and
authorized-domain fields remain blank. No provider switch, OAuth credential,
test-user permission, scope or brand field was changed. Guest-link/recovery
acceptance therefore correctly waits for approved public information pages and
domain verification, then a deliberate Web provider/client test release. Do not
enable the provider merely to bypass that dependency chain.

Physical Android acceptance now covers the wirelessly connected SM A166U on
Android 16. The phone is configured to stay awake only while charging; wireless
ADB control, screenshots, UI hierarchy inspection and filtered live app logs are
available from this PC. The debug APK preserves the legacy
`com.egghatchers.game` package identity. A fresh first-player tutorial completed
across Hatchery, Shop, Collection, Quests and Battles; its route transitions and
scrollable Fusion explanation remained operable at the device's normal 1080x2340
display/font settings. Shop categories, Collection, quest accordion/Claim All,
Custom Animals, Settings, battle accordion and manual-battle loss/return all
rendered and responded. Force-stop/relaunch and an in-place debug APK upgrade
preserved the original Guest Hatcher, tutorial completion, animal, level and
coins.

This device run found a real focused-route collision: starting the first manual
battle completed First Fight while the underlying Battles listener was still
active, so its large action banner covered the VS cinematic and its required
"Click to start" prompt. Focused manual-battle routes now hold quest notifications
from fighter selection through every rematch and release the pending banner only
after returning to Battles. A new service regression test covers the hold/release
contract. A temporary `QABattle` local profile physically proved the first-battle
banner absent during the cinematic and present after Back; that profile and only
its local test progress were then removed, and Guest Hatcher was reopened.

Validation is clean: Flutter analysis passes, all **806 Flutter tests** pass,
Android debug APK and release web builds pass, including the web Wasm dry run.
The three protected-playtest tests and Wrangler 4.129.0 dry run pass; deployment
kept the existing Access-protected custom domain and published version
`91a7cbe4-b5d3-4a1c-a0c5-f018d323c11f`. Hosted multiplayer remains deliberately
off in the native debug build because the current Access-cookie protected backend
is a Web test surface, not a native/public multiplayer endpoint. The native
Account & Saves panel continued to show `Cloud sync pending` during active idle
income, so native Firestore currency/settlement is not claimed by this checkpoint
and remains the next persistence investigation rather than being inferred from
local force-stop survival.

### Android cloud-backup cadence — completed continuation

The native persistence investigation found two separate problems. First, an
upload assessment captured one local revision, waited for the server read, and
then abandoned the upload whenever continuously accruing animal income had
advanced the local revision in the meantime. A slow connection could therefore
starve cloud uploads indefinitely. Uploads now commit the assessed immutable
snapshot with the expected cloud revision, record that exact snapshot as the
confirmed ancestor, and retain newer local progress for a following upload. A
regression test advances local progress during the cloud read and proves the
assessed snapshot still reaches the repository.

Second, the old `Cloud sync pending` label treated every few seconds of newer
idle income as a backup failure even while Firestore was healthy. Sync now
distinguishes `Cloud backup active`: a recent snapshot is safely stored and
newer device progress is queued for the next update. The app-level upload
cadence is 30 seconds, avoiding a Firestore write for every short idle-income
tick; focused service tests retain their fast injected cadence. Pending,
offline, conflict and error states remain explicit and cannot be overwritten by
an unrelated local save. If the selected player changes during a sync, the new
selection gets an immediate assessment rather than inheriting the former
player's wait.

Read-only live evidence closed the original Android uncertainty. The connected
SM A166U's existing anonymous Firebase UID owned
`users/<uid>/products/egg_hatchers`; its server `savedAt`, coins and revisions
were actively advancing, reaching cloud revision **1619** during inspection.
This proves the legacy owner-scoped Firestore path and anonymous identity remain
compatible. No UID, Firebase project, rule, schema, save key, package ID or
player data was changed. Debug builds now log sanitized Firestore read error
codes/messages to aid future device diagnosis; release behavior is unchanged.

Integration validation is clean: Flutter analysis passes, all **807 Flutter
tests** pass, and the release web build plus Wasm dry run pass. The three
protected-playtest tests and Wrangler dry run/deploy pass in the required
sequence. The existing Access-protected hostname remains the only route and now
serves version **`41d5948d-a7cb-415f-aa8c-3ef18f60b176`**. A fresh protected
Chrome load shows the Nestarium portrait shell and Settings route with the
existing browser save intact. That browser guest truthfully remains pending
because its cloud is unavailable; no reward, account, import or save choice was
performed. After wireless ADB returned, the latest Android debug APK installed
in place successfully and relaunched the original Guest Hatcher with its animal,
level, tutorial completion and progress intact. The rendered 1080x2340 Hatchery
retained the portrait shell and showed continuing +4/sec income. Live Firestore
then advanced from cloud revision **4284** at 7:13:09 PM Central to **4286** at
7:14:10 PM, with local revision and coins advancing. Two acknowledged snapshots
over 61 seconds verify the intended approximately 30-second app cadence. The
wireless transport dropped again after the evidence capture, but the installed
app and cloud writes continued; no reinstall, data clear, reward, account,
import or conflict choice was performed.

## First-player journey — preceding bounded implementation checkpoint

Tony approved the six-milestone v1 finish line in
`docs/PLATFORM_ARCHITECTURE_WORKPLAN.md`: first-player journey; family-audience
requirements; launch-platform continuity; public Nestarium readiness; one
consolidated release candidate/human QA; blocker-only fixes and release/stop.
This explicitly supersedes the earlier automatic auxiliary-writer roadmap.
Optional robustness/features are post-v1 unless a demonstrated launch blocker.

The new rendered whole-app journey reproduced a small-phone tutorial defect:
repeated route notifications consumed the sole auto-scroll before it ran, leaving
Buy & Hatch below the screen and allowing Next to skip the first purchase.
Scroll is now consumed only by an executing, mounted-target callback; an affordable
missing purchase target also has an explicit Buy & Hatch fallback. Purchase copy
states the 100-coin cost and immediate hatch; Shop and return instructions match
the persistent shell. Back steps no longer offer a second Next button that could
abandon the next step on another screen. The first Collection visit also exposed
a narrow Fusion heading overflow, corrected with wrapping title/help/summary.

Focused acceptance: 16 tutorial/journey/visibility tests pass, including complete
fresh-device journeys at 320x568 and 390x844. They use rendered controls rather
than service-driven tutorial advancement, buy/hatch one normal chicken, verify
idle income and upgrade, visit Collection/Quests/Battles, complete the tutorial,
then rebuild the app over the same disposable preferences. Player ID, animals,
level, coins and completion survive; welcome does not restart. No real player,
cloud copy or device settings are changed for these tests. Existing storage/
identity compatibility and tutorial completion version are unchanged.

Final integration validation: Flutter 3.47.2 analysis is clean (41.1s), all
**786 Flutter tests** pass, and the release web build passes (45.4s, including
Wasm dry run). Bundle SHA-256:
`208d849330ef3607845dfee8a57af6b40a5f3c7c2bca04b41d8aebd863c8b387`.
All three playtest tests and the pinned Wrangler 4.129.0 dry run pass after the
build; brand audit has 744 classified references and no unclassified branding.
Implementation **`849fcbd`** is committed/pushed on main. The unchanged protected
playtest custom-domain route now serves **100% version
`c6913615-bb77-49d2-9065-8f61f0b9b19c`**, deployment
`2026-09-07T08:00:01.629655Z`. Anonymous requests remain **302 to Cloudflare
Access**. Live Chrome refresh preserves two normal chickens, one golden chicken,
level 1 and +4/sec income (514,966 coins first refreshed read). Collection/Fusion
opens with the repaired header fitting the portrait shell; no fusion, purchase,
reward claim, save choice or player change was performed. Returned to Hatchery.
Human comprehension, native/browser platform acceptance and family-audience
readiness are not claimed by this widget test. Previous storage failure matrices
remain valid and were not rerun separately; no native build/version/tag/RC dossier.

**Historical next (addressed by the decision checkpoint above):** family-audience requirements: a bounded gap/decision list for
the intended 8–12, teen and adult audience, followed by only necessary v1 work.
Stop the current batch after its verified protected deployment. Do not resume
auxiliary writers or repeat storage failure matrices by default.

## Custom-editor draft recovery and checked content — preceding implementation checkpoint

Custom egg/sprite save, delete and reset now check backend acceptance and fresh
read-back before publishing saved lists or success feedback. The installed
preference backend, account keys and existing empty-player/migration boundaries
are retained. Per-key queues and supported-browser leases reject changed loaded
baselines. An uncertain already-applied write is checked before another mutation;
egg edits merge against that checked copy without dropping another custom egg,
unknown fields or malformed list entries. Unreadable whole egg documents cannot
be replaced by an empty parsed list; wrong stored types still enter the existing
player-load recovery. Legacy copying and its completion marker are checked too.

Editors retain drawings/form text after failures, with scrollable Retry / Return
to screen guidance. An eight-second watch explains a slow operation; it does not
cancel or duplicate the actual write. Header and system Back share an explicit
discard confirmation, including Back immediately after typing. Draft exit warnings
compose with settings/progress warnings. Quest navigation notices wait while an
editor is open; import preflight rejects open unsaved drafts/in-flight custom
writes before freezing runtime writers. Operations capture their original player
namespace; stale editor tokens and late account-switch results cannot publish into
the next player. Sprite reset now asks before removing a saved drawing or draft.

Bulk sprite reset publishes each verified removal and stops with a partial-result
message on failure. Retrying checks remaining entries, not an atomic rollback.
Resetting art no longer clears rating-claim history: already-earned rewards are
kept and cannot be claimed again merely by resetting/recreating the same art.
The separate rating/reward writer is not yet a verified transaction.

Validation: clean Flutter 3.47.2 analysis (47.6s), full **784-test** Flutter suite,
including **27 custom-content failure/UX tests**, and **twelve isolated Chrome
tests** pass. Coverage includes rejected/thrown/uncertain/lying writes and removals,
read outages, stale copies, partial reset, retained text/drawing, rapid Back,
account switching, legacy adoption boundaries and unknown-field preservation.
Recovery controls fit 320x360, 390x844 and 1440x900 at 200% text. Browser tests use
the actual installed storage backend and verify no duplicate uncertain retry.
Release web build passes (61.8s; Wasm dry run); bundle SHA-256
`b8dfcc170226d19da5af27482dac4ca832a6d69e9438f99792bfa595b3ccaac9`.
The required three playtest tests and Wrangler 4.129.0 dry run pass after the
release build. Brand audit: **729 classified**, none unclassified. Implementation
**`92ff02f`** is committed/pushed on main. Protected playtest deployment is
**100% version `96cb9eba-925e-46fa-9bbd-74d9873c1e6e`**, created
`2026-09-07T07:33:37.927Z`, on the unchanged protected custom-domain route.
Unauthenticated requests remain **302 to Cloudflare Access**. External Chrome
refresh preserves two normal chickens, one golden chicken and +4/sec income
(508,674 coins first Hatchery read, increasing), Music off / SFX on,
Hatchery Default / Classic and unresolved **Choose progress / Compare saves**.
The custom list still shows 0/54 customized. The untouched Shadow Phoenix editor
opens the new readable portrait reset confirmation; Cancel preserves it and Back
returns to the persistent custom list. No art was drawn/saved/reset, no reward
was claimed and no real save was selected. The tab is returned to Hatchery.
Failure injection uses disposable mocks/browser storage only.
Drafts are held in memory, not durable autosaves: force-close, refresh, eviction
or hardware failure can still lose them. An external-edit conflict is blocked,
not silently merged or overwritten. Old builds do not honor the new leases.

**Historical next (superseded by the six-milestone plan above):** remaining auxiliary writers (sprite-rating claims/reference unlocks
and preference-like metadata), then checked player-directory/profile writes and
removal. Keep failure recovery understandable before further infrastructure work.
Representative child/teen/adult usability, native full-disk/offline/device QA,
child-compatible identity, policy/provider readiness, trusted cloud erasure and
the coordinated protected new-hostname cutover remain open. No public hostname,
Firebase/provider/credentials, billing/mail, store or sibling-app changes.

## Checked device settings and session recovery — preceding implementation checkpoint

All ten device settings now check backend acceptance and fresh read-back using
the installed preference backend, not its optimistic cache. The app shares one
store across visual, audio and custom-visibility services. Writes serialize by
key across store instances, use supported-browser leases, skip superseded queued
choices, and retain the latest failed intent in memory. Explicit retry first
checks whether an uncertain operation already applied. Runtime reads preserve
pending choices and re-read if a choice completes during the read. Legacy keys,
fallbacks, preference backend/prefix, account identities and saves are unchanged.

Failed or eight-second-pending operations expose a persistent **Settings unsaved**
action across game screens. The scrollable review identifies affected settings,
offers non-overlapping retry and lets players keep playing. Session choices stay
applied; mute and volume changes do not wait on storage. Theme success messages
require verified saving. Browser exit warnings now cover pending settings as
well as held gameplay progress, but cannot guarantee survival of force-close or
eviction. Closing/refreshing can still lose unsaved choices; the dialog says so.

Normal Settings export/copy/import asks players to finish settings saves first.
The composition-root import preflight also rejects pending settings before any
writer pause or staging. Its typed rejection preserves Cancel in the review
instead of forcing a restart that would discard the pending choices. The unused
multi-key settings reset now reports partial failure and retains individual keys
for retry; it is not an atomic reset. This does not change emergency gameplay
recovery exports or claim that custom-content/delete writers are checked.

Validation: clean Flutter 3.47.2 analysis (13.3s), full **756-test** Flutter suite,
final **25-test** settings failure/UX suite (including one additional read-race
regression after the full run), and **eleven isolated Chrome tests** pass.
Coverage includes rejected/thrown/uncertain/lying writes, read outages, partial
removals, rapid/coalesced changes, same-key serialization, slow writes, immediate
mute, late disposal, player-switch visibility, import preflight and retained
gameplay. Recovery fits 320x360, 390x844 and 1440x900 at 200% text. Chrome verifies
fresh settings reads and no duplicate uncertain retry using disposable storage.
Release web build passes (40.8s; Wasm dry run succeeds); main bundle SHA-256
`b71c071eb392f9fc0ec4c734fedce7224476121a598c4e06431d2d808ad0613b`.
Required playtest three tests and Wrangler 4.129.0 dry run pass after the build.
Brand audit: **711 classified** compatibility references, none unclassified.
Implementation **`0826c5a`** is committed/pushed to main. The verified build is
deployed at **100%** current version **`85c69ebe-f05c-4ad0-8113-8e4d203fc7df`**,
deployment `2026-09-07T06:55:17.315Z`, on the unchanged protected custom-domain
route. Unauthenticated requests remain **302 to Cloudflare Access**. External
Chrome refresh preserves two normal chickens, one golden chicken and +4/sec
income (499,494 coins on first Hatchery read, increasing). Settings retains
Music off / SFX on, Hatchery Default / Classic and **Choose progress / Compare
saves**. No real choice, preference or player data was changed for QA. Portrait
layout remains constrained and readable; the tab is returned to Hatchery.
Injected failure acceptance is disposable/mock-only, not a real quota outage.

**Next: custom-editor draft recovery and checked custom-data writes.** Custom
egg/sprite save/delete/reset still publish before unchecked persistence; bulk
sprite reset can partially apply. Preserve drafts and truthful partial results
before success feedback. Auxiliary preferences, profile/directory deletion,
native full-disk/eviction and representative human QA remain open. Settings are
device-local, explicit last-choice wins, not conflict-protected progress or a
new cloud-sync contract. Old builds do not honor the new write leases. No public
hostname, Firebase/provider/credential, billing/mail, store or sibling-app changes.

## Checked cloud-sync confirmations — preceding implementation checkpoint

Cloud-sync ancestry reads now use the installed preference backend directly,
without accepting optimistic cache values or reloading the shared settings cache.
Checkpoint writes/removals serialize by player key across store instances, use
the existing supported-browser write lease, verify acceptance and fresh read-back,
and reject changes to a loaded baseline. An uncertain operation already present
in the backend can be verified without another write. Invalid/fractional-revision
metadata is not accepted as ancestry; raw malformed records are not deleted by a
read. Existing checkpoint keys/schema and all gameplay/identity contracts remain.

Rejected/read-unavailable confirmations stop automatic cloud changes without
stopping locally saved gameplay. Settings explains that a cloud operation may
already have completed and offers **Retry confirmation**, not another overwrite
choice. Pending checkpoint writes show guidance after eight seconds; retry stays
disabled while the actual operation is in flight. A comparison dialog switches
to confirmation guidance and a reachable return-to-Settings action instead of
leaving obsolete Replace controls active. Feedback fits short/narrow layouts at
200% text. Raw storage exceptions are not printed by the sync coordinator.

Retry completes only the held acknowledgement, then reassesses fresh local/cloud
data; it does not replay the earlier upload or restore merely to save metadata.
New divergence requires a new review. If another writer changed the stored
record, a subsequent explicit retry abandons only the held acknowledgement and
reassesses current ancestry instead of overwriting that unexpected record.
Matching verified ancestry is not rewritten just to refresh its timestamp.
After confirmation, a fresh local fingerprint must still match before showing
Cloud copy current. Player switching, disposal, import pause and local-save
failure invalidate late status callbacks; already-issued writes may finish only
in their original namespace, not a newly selected player's record.

Validation: clean Flutter 3.47.2 analysis, **732 Flutter tests** and **ten isolated
Chrome storage/import tests** pass. The new **26-test** failure suite covers
rejected/thrown/uncertain/lying write and removal results, changed baselines,
read outages, exact retry, shared-key serialization, cloud upload/choice retry,
fresh divergence, delayed completion and switch/import/dispose/local-failure
isolation. Settings and dialog recovery controls pass 320x360, 390x844 and
1440x900 at 200% text. Chrome confirms direct backend reads ignore a stale
SharedPreferences cache and uncertain writes retry without another mutation,
using disposable data only. Release web build passes (40.9s; Wasm dry run
succeeds); main bundle SHA-256
`8a6be9cba422e228a890414d2b20f1eae260ca281a3d9426bea2f2fc2b97f92c`.
Playtest **three tests** and Wrangler **4.129.0** dry run pass in the required
order. Brand audit: **691 classified** compatibility references, none unclassified.
Implementation **`53c240d`** is committed/pushed to main. The verified release is
deployed at **100%** current version **`9ba2d779-4510-4b99-a5bf-0098d286756b`**,
deployment `2026-09-07T06:29:20.375Z`, on the unchanged protected custom domain.
Unauthenticated requests remain **302 to Cloudflare Access**. External Chrome
refresh preserves two normal chickens, one golden chicken and +4/sec income
(493,374 coins on first Hatchery read, increasing). The daily prompt was dismissed
with Later, not claimed. Settings retains **Choose progress / Compare saves**;
neither real copy was selected. Visual inspection confirms readable portrait
layout and reachable account controls. The tab is left on Hatchery. Failure/
replacement acceptance uses disposable tests, never the real player.

Scope: this is checked sync metadata and truthful retry, not a cloud-authority,
guest identity, provider, encryption or gameplay-save-format migration. No real
save is replaced or corrupted for failure QA. Physical full-disk/eviction/native
and representative human acceptance remain open. The eight-second watch covers
checkpoint writes, not all possible stalled cloud/network/startup operations.

**Next: settings persistence and custom-editor draft recovery.** Audit confirms
DeviceSettingsStore discards backend write results; visual/audio preferences can
look applied without durable saving. CustomEggService/CustomSpriteService publish
mutations before unchecked persistence, and bulk sprite reset can partially
apply. Implement checked writes with visible retry and retained editor drafts;
do not advertise a successful save/delete/reset or clear a draft after failure.
Profile/directory deletion and other auxiliary preference writers still need
their own acceptance. Child-compatible identity, trusted cloud erasure,
policy/provider readiness and protected new-hostname cutover remain separate.
No public hostname, Firebase provider/project/credential, billing/mail, store or
sibling-product changes.

## Checked gameplay saves and held-progress recovery — preceding implementation checkpoint

Normal gameplay saves now serialize and check backend acceptance plus fresh
primary/backup read-back. A loaded-save baseline and per-player Web Lock on
supported browsers stop updated tabs from silently replacing unexpected progress.
Rejected, thrown, uncertain and delayed writes are not reported as saved. Retry
accepts only the original values or this attempt's own verified result; an
already-applied result does not rotate away the older backup. Existing save keys,
formats, player IDs, account ownership and Firebase identities remain unchanged.

A failed write, or one pending longer than eight seconds, pauses play/income and
holds the latest in-memory progress. Recovery sits above navigation, dialogs and
tutorial overlays; hidden controls lose focus and tickers. Autosaves coalesce,
retry cannot overlap a pending write, and late game callbacks cannot mutate the
held snapshot. Switching/import and new cloud/presence work are blocked until a
verified save; pending cloud comparisons survive but require a fresh review.
Retry resumes the same held progress without reloading or applying offline income
again. No cloud winner is selected and no automatic restoration is introduced.

The scrollable recovery screen offers retry and a read-only recovery backup that
substitutes this player's held progress while retaining readable local players,
settings and custom data. If storage is unreadable or hangs, a separate emergency
snapshot exports directly from memory. It intentionally is NOT a normal import:
it omits other players/settings/custom art and may need support-assisted recovery.
Exports exclude device identity and sync ancestry. Download/copy messages ask
players to verify a private saved file; Settings no longer announces a normal
export after a failed progress flush. Controls fit short/narrow and desktop
portrait layouts at 200% text. Browser exit warnings are best-effort only.

Validation: clean Flutter 3.47.2 analysis, **706 Flutter tests** and **nine
isolated Chrome storage/import tests** pass. New tests cover rejected/thrown/
applied-but-reported-failed writes, stale copies, serialized revisions, hanging
reads, slow writes, no false saved notification, held-state retry, cloud-choice
invalidation and whole-app recovery above a pushed dialog and active tutorial.
Responsive cases include 320x360, 390x844 and 1440x900 at 200% text. Chrome checks
use disposable actual browser storage with an injected rejecting writer, exclusive
progress locks and exit-listener attach/remove. Final release web build passes
(40.4s; Wasm dry run succeeds); main bundle SHA-256
`33fd40221df5a2e9026de98423431d20cbd7ac14835d63708a87fb4ea30c7871`.
Playtest **three tests** and Wrangler **4.129.0** dry run pass after that build.
Brand audit: **669 classified** compatibility references, none unclassified.
Implementation **`13d4d7c`** is committed/pushed to main. The verified build is
deployed at **100%** current version **`1cc169c1-c3dc-484a-8c89-73717fec8df6`**,
deployment `2026-09-07T02:07:09.775Z`, on the unchanged protected custom domain.
Unauthenticated requests remain **302 to Cloudflare Access**. External Chrome
refresh preserves the existing guest's two normal chickens, one golden chicken,
+4/sec income and increasing coins (430,306 on first accessible read). Settings
retains **Choose progress / Compare saves**, with neither copy selected. Visual
inspection confirms the readable portrait shell and reachable account controls;
the tab is returned to Hatchery. No real player, save or identity was changed,
removed, corrupted or replaced for failure QA.

Limits: read-back is backend verification, not a hardware durability guarantee.
Forced close/eviction can still lose unexported RAM. Old builds do not honor new
locks; close other game tabs. Browsers without Web Locks retain baseline checks,
not an atomic multi-tab guarantee. Already-issued external operations cannot be
undone by pausing. Physical disk/quota exhaustion was not forced on real data;
failure tests use disposable storage. This patch covers gameplay progress writes,
not every settings/custom-data/checkpoint/directory/deletion write.

**Next at that checkpoint: checked failure feedback for remaining settings, custom-data and sync
checkpoint writes.** Native recovery and representative human/physical-device
acceptance remain open. Child-compatible identity, trusted cloud erasure,
policy/provider readiness and the protected new-hostname cutover remain separate
gates. No new public route, provider, mail/billing, store, credential or sibling
product changes.

## Local-first startup without cloud waits — preceding implementation checkpoint

Valid local gameplay no longer waits for Firebase core initialization or restoring
the cloud identity. Mandatory storage leases, pending import/backup recovery,
player-directory validation, selected progress and local customizations still
finish before play. A slow local operation shows keep-data guidance after eight
seconds, not a reset, bypass or parallel operation. Loading guidance scrolls on
short screens. Offline/cloud errors are not mislabeled as damaged progress.

Settings separates optional cloud-startup status from identity and cloud-save
status. Cloud retry is available after a completed failure; pending operations
stay single-flight even after slow-connection messaging. SDK retry also runs on
resume. Late SDK success starts identity work only for the currently loaded valid
player. Identity retries coalesce, serialize gateway requests and recheck selected
player, device-slot generation and ownership before binding. Disposal, switching
and import suspension invalidate late results. Existing keys, UIDs, Firebase
project, SDK/provider settings and save formats remain unchanged. Google linking
stays disabled by the existing release flag; this is not child-auth acceptance.

Slow same-player identity rechecks do not reset an unresolved cloud comparison;
the same verified account/UID is not reconfigured on resume. A completed identity
failure revokes cloud context. Import/backup staging now suspends and drains
identity restoration as well as game/cloud writers; a hanging identity prevents
replacement rather than overlapping it. Guest identity copy no longer implies a
cloud save has already succeeded: the separate save status remains authoritative.

Validation: clean Flutter 3.47.2 analysis, **684 Flutter tests** and all
**seven isolated Chrome storage/import tests** pass. New mocked tests exercise
slow/failed SDK startup with preserved playable/savable local data, late success,
slow storage/local loads, safe retry, identity switching/generation/disposal/import
guards, same-identity resume, and 320x360/390x844/1440x900 retry notices at 200% text.
Final color inheritance follows the selected settings theme; all **26 focused
startup/settings tests** pass after that style change. Final release web build
passes (42.4s; Wasm dry run succeeds); main bundle SHA-256
`a019ce3159c745c7e3e624263e40f03dfd900891308c9938b9019e126d874570`.
Playtest **3 tests** and Wrangler **4.129.0** dry run pass in the required order.
Brand audit: **649 classified** compatibility references, none unclassified.
Implementation **`8a94b58`** is committed/pushed to main. The verified build is
deployed at 100% current version **`fab1c0f7-9984-441a-8e34-629ce74daea7`**,
deployment `2026-09-07T01:21:17.718Z`, on the unchanged protected custom domain.
Unauthenticated requests remain **302 to Cloudflare Access**. External Chrome
refresh reopens the existing guest's two normal chickens, one golden chicken and
+4/sec income (419,346 coins immediately after refresh, increasing). Settings
shows the new truthful guest-identity wording and retains **Choose progress /
Compare saves**; neither copy is selected. Visual inspection confirms readable
status text and reachable controls within the portrait shell. The tab is returned
to Hatchery. No real save, profile or identity was replaced/removed for testing.

Scope: this is offline-tolerant Flutter startup once app code and local storage
are available, not a promise of first-ever/cold offline web loading. Cloudflare
Access and initial assets still need appropriate network/cache availability; no
service worker or Access bypass was introduced. **Next at that checkpoint: runtime storage-write
failures/quota and truthful unsaved-progress recovery.** Native recovery and
representative human/physical-device acceptance remain open. Child-compatible
identity, trusted cloud erasure, public policies/provider readiness and protected
new-hostname cutover remain separate gates. No public route, mail/billing,
production credential, sibling-product or store setting changes.

## Damaged progress and local-backup recovery — preceding implementation checkpoint

Primary/backup progress loading is now read-only and fail-closed: only two absent
copies mean a new save. Malformed payloads, unsupported envelopes, invalid known
containers/types and checksum mismatches never silently become starting progress.
A readable older backup is offered for review, not applied automatically. Shared
decoding keeps file-import review and normal progress loading consistent while
retaining valid legacy defaults and existing keys/formats.

Startup checks the selected progress before auth identity/gameplay/cloud sync;
failed switches and runtime read failures stop progress writers, income and cloud
publication. Recovery offers retry, raw private backup, web file review and the
local-player picker. No selected player means the picker, not a running default
game. Deferred legacy tutorial migration preflights every save and retains its
marker if a payload cannot be read. Valid selected saves still honor that choice.

Web **Review local backup** shows saved time, coins, animals and Rebirth, warns
about missing recent progress and requires **Restore & restart** after a second
confirmation. Cancel is the keyboard default; controls fit 320x360 at 200% text.
The selected raw pair is compared again before staging and at restart. Bootstrap
requires exclusive updated-tab storage access before Firebase/game initialization.
It verifies an archive of BOTH original values before replacing only this player's
primary with its reviewed backup. Other players, settings, active session, device
identity/generation and cloud ancestry are not replaced/rotated. This is deliberately
not a full-save import. Completion requires acknowledgment before normal startup.

Checked writes/removals are resumable after failure, including an operation that
applied but reported failure. Cancellation restores the exact original primary
(including absent/wrong-type values) if replacement already started. Conflicting
operations or changed copies pause without guessing. Archives remain on this
device under `nestarium.progress_recovery.archive.*` and are included in exports;
they do not survive clearing browser/app data. Keep a separate downloaded backup.
Pending recovery requests are excluded from exports/imports. Close older game
tabs explicitly: old builds do not honor storage leases. Native backup application
and physical-device acceptance remain open; native UI does not promise web-only
restore actions. Unreadable raw backups may require repair before file import.

The full suite exposed a real cache race: frequent SharedPreferences.reload()
could hide a concurrent customization write. Progress guards now read only the
primary/backup pair directly from the installed legacy backend without replacing
the shared cache. The established `flutter.` prefix/backend are retained; no
SharedPreferencesAsync/DataStore migration. The already resolved platform-interface
2.4.2 is now a direct dependency (no package version upgrade). Regression tests
cover concurrent settings, fresh backup rotation and drained disposable fixtures.

Validation: clean Flutter 3.47.2 analysis and **661 Flutter tests pass**, including restart interruption,
uncertain writes, stale review, identity/other-save preservation, no cloud upload
from unreadable progress, root startup/switch/runtime recovery and small layouts.
All **seven isolated Chrome tests** pass, including real browser storage backup
repair with disposable data and preserved originals. The final test-style cleanup
also passes all 23 focused progress-recovery tests. Release web build passes
(43.1s; Wasm dry run succeeds); main bundle SHA-256
`881826b3e568a9f4f4d15ea630884ac7c5f0d44444b6b34626ce7b9362ba6664`.
Playtest **3 tests** and Wrangler **4.129.0** dry run pass in the required order.
Brand audit: **633 classified** compatibility references, none unclassified.
Implementation **`1d15690`** is committed and pushed to main. The verified build
is deployed at 100% current version **`43fe4bdb-72b3-43bd-a2fd-406c41cfc146`**,
deployment `2026-09-07T00:51:29.701Z`, on the unchanged protected custom domain.
Unauthenticated requests remain **302 to Cloudflare Access**. External Chrome
refresh reopens the existing guest (two normal chickens, one golden chicken,
+4/sec; coins continue increasing). Settings retains **Choose progress / Compare
saves** without selecting either copy. Navigation works and the tab is left on
the Hatchery. No real player is created, removed, damaged or restored for QA.

Next at that checkpoint: broader offline startup and storage-outage acceptance, including failures
outside progress decoding; native recovery and representative human comprehension
testing remain open. Child-compatible identity, trusted cloud erasure, public
policy approval and coordinated protected new-hostname cutover remain separate.
No public hostname, provider, Firebase project/rules/credential, billing/mail,
sibling-product or store setting changed.

## Unreadable saved-player recovery — preceding implementation checkpoint

Startup no longer treats an unreadable player directory as an empty install.
A read-only preflight rejects malformed/wrong-type entries, duplicate IDs,
incomplete legacy profiles, unreadable device identity types and missing player
ownership when account-scoped data remains. On those failures the directory,
progress, custom data, identity and active session are left untouched. No guest
is invented, migrations do not run, and auth identity/game/cloud sync/presence do
not start. Firebase core initialization is still owned by the earlier bootstrap.
Storage read/write failures are distinguished from unreadable profiles and are
not presented as proof that no save exists. First-directory writes are checked
and read back before a player becomes active. Retry reloads storage and coalesces
overlapping requests; profile mutation methods require completed initialization.

Valid old names/IDs and standalone legacy profiles remain compatible. Existing
valid directory formatting/unknown fields are retained unless a legacy profile
must actually be added. Pre-account device-wide progress still receives its
first guest through the existing migration; generation-only tombstones do not
block genuinely empty installs. Already known player directories do not cause
unrelated orphan records to be erased or assigned to another player.

The portrait recovery screen offers **Try again**, read-only **Download backup**
(web), **Copy backup**, and web **Review saved file** using the existing two-step
import confirmation. A recovery backup retains unreadable profile strings as-is,
is not promised to be repaired/restorable, and excludes sign-in/device identity
just like normal exports. Download status asks users to check their saved file.
Native file import is not advertised as implemented. Error messages do not echo
platform/file contents. Controls scroll and remain at least 48px at 320x360/200%.
File chooser cancellation and review/cancel never mutate local data.

Confirmed recovery imports use the same staging lease and checked restart
bootstrap as Settings. They skip runtime flush because no player/game was loaded;
even failed staging keeps the root frozen. Lifecycle background saves are now
gated on completed initialization, preventing a default in-memory state from
overwriting older saves while startup is paused. Import review and account startup
share the same player-directory validator.

Validation: clean full Flutter 3.47.2 analysis and **625 Flutter tests**.
New mocked tests cover storage outage/write/read-back failure and retry, malformed
and partially valid directories, original bytes/session/identity preservation,
legacy compatibility, responsive recovery/backup/cancellation, and whole-app
startup/lifecycle/import isolation. **Six isolated Chrome tests** pass, including
actual browser storage holding a damaged mock directory unchanged until explicit
checked bootstrap restore, then successful reinitialization of the restored player.
The final backup-action copy also passes 21 focused import/recovery UI tests.
Final release web build passes (43.5s, Wasm dry run succeeds); main bundle SHA-256
`825d4994fd60a4df462a36861379ab64a772e50c4ccf08c3ffa191f981fffbe1`.
Playtest **3 tests** and Wrangler **4.129.0** dry run pass in the required order.
Brand inventory: **606** classified references, none unclassified. Implementation
**`ab1f4d9`** is committed and pushed to main. The verified build is deployed to
the unchanged protected custom-domain route at 100% current version
**`8f2176db-27b9-43fc-8cb0-697ac54622c8`**, deployment timestamp
`2026-09-07T00:18:35.105Z`. Unauthenticated requests still return **302 to Access**.
External Chrome refresh opens the existing guest with two normal chickens, one
golden chicken and +4/sec income. Settings retains **Choose progress / Compare
saves** without choosing either copy; shell navigation works and the tab is back
at the Hatchery. No real player is created, removed, damaged or replaced for QA.
Physical-device and human comprehension acceptance remain open; automated layout
and isolated mock recovery tests do not substitute for those gates.

Next at that checkpoint: fail-closed primary/backup **progress payload** loading and truthful local
recovery status, then broader offline startup acceptance. The normal progress
loader can still conflate two unreadable payloads with no save; this checkpoint
specifically protects the player directory, not every possible storage failure.
Child-compatible identity, trusted cloud erasure, public policy approval and
coordinated new-hostname cutover remain separate gates. No public/store action.

## Save-import safety — preceding implementation checkpoint

Web Settings now validates and previews a file before a second, explicit
**Import & restart** confirmation. Review/cancel are read-only. The warning names
all local players/progress/settings/custom eggs/artwork, no merge, cloud/sign-in
exclusions, export-first guidance and closing all other game tabs. Dialogs fit
320x360 at 200% text; cancel is the keyboard default. File chooser change and
cancel both settle and remove the temporary input; repeat selection is guarded.

The root permanently pauses/drains cloud work and gameplay saves, verifies one
final local save, suppresses lifecycle/player/presence reconfiguration, then only
stages the reviewed source. It never replaces preferences in the old runtime.
Restart bootstrap runs before Firebase/game initialization. Updated browser tabs
hold shared storage leases; import/recovery requires exclusive access without
stealing another tab's lock. A separate exclusive staging lease prevents competing
pending files. Browsers without Web Locks may play, but cannot import. Older
already-open builds do not honor these locks: close those tabs explicitly.

Bootstrap revalidates the staged source and checks a durable original-data/session
journal before any replacement. All writes, removals and final content are checked;
interruption or write failure restores originals, or retains recovery state and
blocks startup when recovery cannot finish. Journal removal is the final commit
point, outside rollback handling, so an ambiguous commit cannot launch destructive
rollback without a durable journal. Recovery is temporary, not permanent backup.
Never clear browser data to work around a paused recovery screen.

Valid legacy-format exports remain supported. Import rejects unreadable nested
progress/custom content and wrong-type known settings before mutation; it does not
use normal loader fallback/repair. Device guest identity and sync checkpoints are
excluded from transfer, with the destination guest generation rotated. Rollback
restores original device identity/checkpoints/session. Firebase credentials,
projects, providers, rules, cloud-copy choices and public routes are unchanged.

Validation: full Flutter 3.47.2 analysis has no issues; **590 Flutter tests** pass.
Five isolated Chrome tests cover chooser read/cancel, real web-preferences import
round trip with mock data, shared/exclusive leases and competing staging. The
Windows Flutter test server has a CanvasKit URL/backslash 404 bug; the repeatable
`tool/test_save_import_browser.mjs` adapter supplies the same pinned SDK renderer
only into its disposable browser. No SDK patch or production renderer change.
`shared_preferences_web` 2.4.3 is also a direct dev dependency solely to register
the real plugin in those tests; its installed version is unchanged.
Mock regression coverage includes every failed replacement mutation, interrupted
rollback/restart, unverifiable recovery copy, ambiguous commit, wrong-type nested
data, old exports, session/identity preservation, responsive confirmation and
whole-app freezing after preparation failure. No real QA player is replaced.
Implementation **`e721e19`** is committed and pushed to `main`. Final analysis is
clean; release web build succeeds (41.4s, including Wasm dry run), followed by
playtest **3 tests**, Wrangler **4.129.0** dry-run and deployment in order. Brand
audit: **578** classified legacy references, none unclassified. The unchanged
protected custom-domain route reports 100% current version
**`7b413314-8c5b-4dbb-9193-5f28dd95dc68`**, deployment timestamp
`2026-09-06T23:31:04.601Z`; unauthenticated requests still return **302 to Access**.
Live Chrome refresh reopens the existing guest with the same two normal chickens
and one golden chicken, +4/sec income, and working shell navigation to Settings.
Account & Saves retains the unresolved Choose progress / Compare saves and shows
Import Save; neither cloud/device copy was selected. Tab returned to the Hatchery.
Import confirmation/replacement/failure QA uses isolated mocked data only, not the
real player's browser. Physical-device and human comprehension acceptance remain
separate gates.

The following checkpoint addresses unreadable account metadata and startup
recovery without a replacement guest (see above). Family-account
eligibility, public-site policy approval, trusted cloud erasure and coordinated
new-hostname cutover remain separate gates. No public launch or store action.

## Player-switch recovery — preceding implementation checkpoint

A whole-app regression reproduced the loading freeze with a socket that never
acknowledges close. `_switchGameAccount` previously awaited that network cleanup;
the account-change listener could also reconnect presence with the newly selected
profile before its local save loaded. The controlled reproduction failed against
the old lifecycle and passes with synchronous connection retirement. The earlier
live symptom was observed without a browser stack trace; live replay after the
verified deployment is the separate acceptance check, not inferred from tests.

Lobby disconnect now retires its ownership immediately, starts cancel/close
independently, catches transport cleanup failures and ignores obsolete handshake,
message and disconnect callbacks. Handshake failure no longer awaits close; only
the latest queued presence is sent after a successful connection. Multiplayer
protocols, endpoints and Bot Arena remain unchanged.

Root player transitions are serialized. Old cloud/presence context is revoked
before loading; neither can publish again until the currently selected player's
progress and customizations finish. Superseded selections cannot reopen a stale
player or pair a new identity with old progress. An interrupted legacy migration
stays assigned to its original player. Failed local loads show **Try again** and
**Choose local player**, without removing players or silently repairing unreadable
customizations. Diagnostics expose only the stage and exception type, not save
contents or identity. Firebase identity restoration and cloud-conflict decisions
are unchanged; this is not a blanket claim of offline bootstrap/recovery readiness.

New whole-app tests cover the actual Settings > Switch Account > creation/back >
existing-player route, non-completing socket cleanup, overlapping selection,
returning to the picker mid-load, recovery controls at 320x360/200% text, mocked
local-read failure, untouched wrong-type custom-egg storage and other-player
preservation. Socket regressions cover late success/failure, dual failure signals,
queued presence and creation failure; existing real local-server battle/trade
tests remain in the gate. Short/large-text testing also found and fixed an income
chip Row overflow by allowing its label to wrap.

Validation: Flutter 3.47.2 analysis has no issues and all **563 tests** pass,
including 15 app/lobby checks (13 new). Brand inventory: 551 classified legacy
references, none unclassified. Release web build succeeds (50.8s, including the
Wasm dry run). Implementation **`74cde12`** is pushed to `main`. Playtest 3 tests
and Wrangler 4.129.0 dry run/deploy pass in the required order. The unchanged
protected custom-domain route has 100% current version
**`fa0211d9-4070-4ebf-b53c-d0e663d8071a`**, read back at
`2026-09-06T22:25:29.213Z`; unauthenticated requests still return 302 to Access.

Live external Chrome replayed Settings > Switch Account > Create another player
> Back to players > existing guest, then repeated a direct picker round trip.
Both reopened the Hatchery on the next independent observation without refreshing.
The same three animals and continuing income remain. Between the round trips,
Settings retained the guest's cloud-copy status and unresolved Choose progress /
Compare saves; neither copy was selected. The creation form was canceled, not
submitted. No real player was created/removed and no save imported/reset/restored.
The tab is left on the existing guest's Hatchery. Failure/overlap/destructive-data
scenarios use mocks only; this is not physical-device, public multiplayer or full
offline/cloud bootstrap acceptance.
No real save is to be imported, reset, removed or selected in a cloud conflict
for QA. Next priority remains validated import preview, coordinated writer
pause/replacement/rollback/restart and cancellation, followed by unreadable account
metadata recovery. Child-compatible identity and the new hostname cutover remain
gated. No credential, Firebase project/provider/rule/schema, public route or
bundle/save identifier changes are part of this patch.

## Local-player picker clarity — preceding implementation checkpoint

Startup/player switching still used an obsolete Delete account dialog. The picker
now reuses Settings' **Remove local player** confirmation, including exact local
scope, cloud/sign-in exclusions, guest-recovery warning, no-undo wording and safe
Keep player keyboard default. Picker-specific backup directions explain opening
the player before Settings > Account & Saves > Export Save. Duplicate picker
actions are disabled during creation/removal, and failures surface an inline alert.

Choose/Create local player copy now distinguishes separate local progress from
sign-in or recovery and explicitly preserves existing players. The name field
encourages a nickname; username collision copy says "on this device" rather than
implying a global identity claim. Avatar colors have distinct accessibility labels,
48px targets and wrap on narrow screens. Creation/back actions also have 48px
minimum targets. Existing account/storage/identity APIs and keys are unchanged;
this does not complete cross-device recovery or cloud-account erasure.

Focused picker/Settings/removal suite: 22 passing, including seven new tests for
320/390/430px/desktop, 320x360 short height, 200% text, keyboard cancellation,
creation isolation and mocked local-removal preservation of another player's
progress/artwork and device settings. Flutter 3.47.2 analysis has no issues and
all 550 tests pass. Brand audit classifies 537 references, none unclassified.
Release web build succeeds. Implementation `c33df0d` and accessibility follow-up
`1d43052` are pushed to `main`. Final analysis, all 550 tests, release build,
playtest 3 tests and Wrangler 4.129.0 dry-run/deploy pass. The unchanged protected
custom-domain route has 100% current version
**`967d9911-9170-4147-b1d8-e6ce84d64c56`**, read back at
`2026-09-06T21:52:45.672Z`; unauthenticated requests still redirect (302) to Access.

Live external Chrome verified the picker, correctly scoped removal dialog and
Keep player keyboard cancellation, then creation/back without submitting a new
player. Content fits the portrait shell. The first live check caught duplicated
spoken avatar labels; the follow-up suppresses tooltip duplication and asserts
exact semantic names in all six responsive scenarios. Final refreshed Chrome
shows each of the six color names once. No real player created/removed and no
save imported, reset, restored or chosen in the device/cloud comparison for QA.
Actual data-removal/creation isolation was tested only with mocked local data.
Human comprehension and native device acceptance remain separate gates.

**Observed follow-up — player-switch startup stall:** final live QA followed Settings
> Switch Account > Create another player > Back to players > existing guest.
The return stayed on the logo/loading screen across repeated observations.
Refresh restored the existing progress and the same three animals with income
continuing. No save was selected/replaced to recover. Root cause is not yet proven;
the recovery checkpoint above records the subsequent causal regression and fix.
Picker-only tests do not establish whole-app switch completion. No local data or
identity was cleared or replaced as a workaround.

**Following priority — import safety:** code inspection found `SaveTransferService`
clears preferences and rewrites them while the existing game remains running,
with no coordinated pause/drain of gameplay/cloud writers or checked rollback.
Validation checks the transfer envelope, preference types and account list, but
not every nested progress payload. The web file picker handles change, not cancel.
These are code-level gaps, not a reproduced loss of a real player's data. Next
work must add read-only import validation/preview, coordinate exclusive replacement
and restart, verify write failure recovery and cancellation with mocked storage,
and preserve the old export format. Do not import into real QA saves to prove it.
Startup parse-failure recovery also remains open: `AccountService.initialize`
falls back to a guest when the stored account list cannot be read. Preserve and
explain unreadable metadata in that later recovery pass; the picker copy changes
do not constitute corrupt-save recovery.
Child-compatible account release, full recovery and external rebrand gates stay open.

## Review saves before replacing — preceding implementation checkpoint

Settings > Account & Saves now opens **Compare saves** instead of immediately
applying Use Cloud or Keep Device. Read-only, freshly validated summaries show
saved local time, coins, animals owned, eggs hatched, rebirth/luck levels and boss
wins. They explicitly warn that larger/newer totals are not proof of better
progress, omit offline income until restoration, and do not summarize every
field. Both source buttons have equal styling; neither source is recommended.

Choosing a source opens a separate replacement confirmation describing exactly
which progress is replaced, no merging, the preserved other players/device
settings/custom eggs/artwork, and the existing Export Save backup path. Back and
Later are keyboard defaults. Scrollable dialog bodies retain reachable 48px
decisions even in narrow/short portrait layouts and at 200% text.

Manual replacement requires the active in-memory review for the current player.
Before applying either choice, cloud revision and fingerprint must still match
the reviewed copy; changed/unavailable/expired reviews cannot overwrite progress.
The device choice uses freshly saved local progress, including intervening
income. Cancelling or opening a review never chooses, uploads or restores a save;
local saving continues while automatic cloud sync remains paused for the decision.
No schema, persisted key, identity, Firebase rule/provider or hostname change.

Validation: Flutter 3.47.2 analysis has no issues, all 543 tests pass, and release
web build succeeds. Thirty-three focused service/dialog/Settings tests pass;
15 new regressions cover read-only comparison, stale/expired/unavailable reviews,
explicit replacement with mocked data, fresh device income, loading cancellation,
retry, keyboard-safe defaults, 320/390/430px and desktop widths, short height and
200% text. Brand inventory has 533 classified references, none unclassified.
Implementation commit `2c63d66` is pushed to `main`. Playtest 3 tests and Wrangler
4.129.0 dry run/deploy pass in the required sequence. The unchanged protected
custom-domain route reports version **`107a7dde-b14b-4943-8478-486611b1f438`**;
deployment read-back shows 100% at `2026-09-06T21:33:29.596Z`. Unauthenticated
access still returns 302 to Cloudflare Access.

Refreshed external Chrome and verified Settings > Account & Saves > Compare
saves. Both populated summaries and all three footer actions fit the portrait
shell; Later has default keyboard focus. Keyboard cancellation returns to Settings.
All 11 samples across 10 seconds retain Choose progress and Compare saves with no
pending transition or dialog reappearance; income continues. Neither real save
was selected, merged, restored, imported, reset or deleted during QA. Actual
replacement/stale-write acceptance uses mocked data only. Human comprehension,
native physical-device and complete recovery acceptance remain separate gates.
Next: startup/recovery and import clarity, then child-compatible identity release;
real player saves must not be selected merely to clear a QA conflict.

## Stable cloud-save choice — preceding implementation checkpoint

The owner reported repeated **Cloud sync pending → Choose progress** flicker.
Verified cause: the one-second idle-income save callback overwrote the conflict
state and queued another cloud comparison, which rediscovered the same choice.
A regression test reproduced that full transition loop before the fix.

Unresolved conflicts now suspend automatic comparisons/uploads/downloads, cancel
queued retries and keep the choice visible. Income and local persistence continue;
neither save wins automatically. An explicit choice reads fresh progress and
resumes normal sync only after success. Failed/offline/revision-raced choices
remain actionable instead of entering another retry loop. Player selection clears
the old decision; in-flight manual completions cannot update the newly selected
player's sync state/checkpoint, and its queued initial sync still runs.

Flutter 3.47.2 analysis has no issues; all 528 tests pass, including 10 new
regressions and 29 focused sync/planner/assessment checks. Coverage includes
continued local income saves, a retry queued before conflict detection, both
explicit choices, newer cloud/local snapshots, offline failure, revision races,
declined restore and player switches during either manual choice. Mocked data
only; no real cloud/device save has been selected, replaced or deleted for QA.
Release build, playtest 3 tests and Wrangler 4.129.0 dry run/deploy pass.
Implementation commit `79e54ce` is pushed to `main`; the existing protected
custom-domain route reports version **`39c8950f-6676-44d1-a639-ddeee5aa8394`**.
Deployment read-back shows that version at 100% at `2026-09-06T20:55:07Z`;
an unauthenticated request still returns 302 to Cloudflare Access. Refreshed
external Chrome, opened Settings > Account & Saves, and sampled the visible
UI once per second for 30 seconds: all 31 samples retained Choose progress,
Use Cloud and Keep Device, without pending/comparing transitions, while coins
increased. Neither real save was selected; the unresolved choice is preserved.
The legacy-reference inventory passes without unclassified branding.
No schema, identity, Firebase rules,
provider, new-domain route or credential change is part of this patch.

The subsequent comparison checkpoint above replaces those direct buttons. Recovery
and account trust remain priorities; do not choose a real player's save merely
to clear this decision during testing.

## Usability and player trust — current implementation checkpoint

Owner explicitly made usability a major continuing priority. The ordered
workstream and per-change acceptance criteria are now near the top of
`docs/PLATFORM_ARCHITECTURE_WORKPLAN.md`: save/account trust, child-compatible
account release, first-session comprehension, whole-app navigation/accessibility,
consequential-action clarity, external rebrand gates, then durable multiplayer.
Usability is a release criterion, not deferred polish. Human comprehension and
family/device acceptance must be recorded separately from automated passes.

First bounded implementation replaces the misleading **Delete Account** control
with **Remove local player**. Its confirmation identifies the player, explains
local progress/custom-content removal and preserved other players/settings,
explicitly excludes cloud/sign-in deletion, warns guests against assuming cloud
recovery, and points to Export Save before removal. The scrollable body retains
reachable 48px decisions, with keyboard focus initially on **Keep player**.
Underlying storage, Firebase identity/data and deletion APIs are unchanged;
this is not implementation of full cloud-account erasure. The two unpublished
support/data-page drafts use the same corrected control name.

Validation: Flutter 3.47.2 analysis has no issues, all 518 Flutter tests pass,
and `flutter build web --release` succeeds. Eleven focused dialog/Settings tests
include 320/390/430px widths, 320x360 short height, wide desktop, 200% text,
48px reachable decisions, keyboard-safe cancellation, and mocked other-player,
artwork and device-setting preservation. Public-draft build and 9 tests pass;
the legacy-brand audit classifies 518 references with none unclassified.
Protected release: application commit `1f800c1` is pushed to `main`. Playtest
3 tests, Wrangler 4.129.0 dry run and deploy pass in the required sequence;
the reported custom-domain route remains
`egg-hatchers-playtest.daygullstudios.com`. Independent deployment listing shows
100% current version **`6192a8be-bc9c-41dc-b19f-6f5a0caa4065`** at
`2026-09-06T20:35:40Z`. An unauthenticated request returns 302 to Cloudflare
Access. Browser refresh shows the new local-removal control; the live dialog
fits the portrait shell, says "this browser", and focuses Keep player. Keyboard
cancellation returns to Settings with the player/progress still present.
Live QA also surfaced a device/cloud progress choice; neither copy was chosen,
imported, reset or removed. Recovery/conflict clarity remains the next priority.
No real player was removed for QA. No new-domain route, provider, billing,
credential or public-site publication is part of this patch.

**Rebrand status:** owned game branding/display names/art are implemented;
full external rollout is not complete. Public-site policy/publication,
child-compatible identity/recovery, remaining third-party/native acceptance and
the coordinated protected new-hostname cutover are open. Legacy save/package,
bundle, Firebase and current Worker/origin IDs intentionally preserve continuity;
see `docs/NESTARIUM_MIGRATION.md` and the verified legacy-reference ledger.

## Support identity readiness — latest checkpoint

After the rebrand release, the owner authorized the G&A/Railcade support-account
model, explicitly lifting the earlier no-new-third-party-accounts restriction.
Owner-controlled credentials/recovery and action-time access approvals remain.
The separate gameplay rule that new player accounts must not overwrite older
progress is unchanged. The product-support Google account is now created.

- **Verified:** `support@playnestarium.com` is an enabled exact forwarding rule
  to the same already verified company inbox. Catch-all remains disabled/drop.
  Receiving status is ready. Cloudflare dashboard performed the writes after
  the connector's write attempt returned authentication error 10000.
- **Verified:** sending domain `playnestarium.com` is enabled; dashboard DNS
  is Configured and API DNS status is ready with no errors. Eleven mail-only
  MX/TXT records now cover receiving, bounce routing, SPF, DKIM, and DMARC.
  No new subscription, sending credential, mailbox, or game/web route was added.
- **Verified:** Thunderbird now lists **Nestarium Support** with matching
  `support@playnestarium.com` From/Reply-To. It reuses the existing Cloudflare
  family SMTP selection and company Sent/Drafts folders. All eight earlier
  identities (seven roles plus original Gmail) and studio hello default remain.
  No SMTP credential was read, replaced, or created.
- **Verified:** Gmail has a `Nestarium / Support` label and exact
  `to:(support@playnestarium.com)` filter whose only action is applying that
  label. Seven existing filters remain unchanged; Inbox visibility and normal
  spam handling are preserved. No historical conversations were modified.
- **Verified controlled incoming test:** owner approved the actual Thunderbird
  Send step. The studio hello-to-Nestarium test arrived in the company Inbox,
  received the Nestarium / Support label, and Gmail's received-message summary
  reports SPF/DKIM/DMARC PASS. Exact-subject `in:sent` search confirms the first
  test's company Sent copy. Only an owner-only setup message was sent.
- **Verified Reply selection and return delivery:** using Thunderbird's
  actual Reply on that received test automatically selected Nestarium Support
  with matching support From/Reply-To and studio hello as recipient. The return
  test was sent after the owner's explicit approval on September 6 at 3:10 PM
  Central. Gmail received it in Inbox with the studio Hello label; the original
  message summary reports SPF/DKIM/DMARC PASS, with DKIM domain
  `playnestarium.com`. Exact-subject/from/to `in:sent` search confirms the reply
  in company Sent mail. No SMTP credential was read or recreated.
- **Open cosmetic mail issue:** the sent copy displays Nestarium Support, but
  the received copy displays the support address as its name. From and Reply-To
  are correct; display-name preservation needs separate investigation. This
  does not invalidate the controlled delivery/authentication acceptance.
- **Verified:** Google Auth Platform now has the **Nestarium** brand with
  `support@playnestarium.com` selected as user support email. The existing
  company contact receives private developer notifications. Audience is
  **External / Testing**, with no test users or OAuth clients. Public URLs,
  authorized brand domains, logo, verification and publication remain open.
  The Firebase Google provider and its client UI release flag remain off.
- **Verified Google account:** after the owner completed private registration
  details and handed back the Privacy and Terms screen, accepted the authorized
  terms. Account home confirms **Nestarium Support / support@playnestarium.com**.
  Optional Search recommendations/history, Play personalization/history,
  Web & App Activity, personalized ads and YouTube history were all off at
  submission. No new Gmail mailbox or private account details recorded.
- **Verified approved access:** after explicit owner approval, saved
  `roles/oauthconfig.editor` for Nestarium Support on Nestarium Dev only.
  Independent IAM API read-back confirms this sole, unconditional role and
  retention of the existing owner. It matches both sibling support roles and can
  manage OAuth brands/clients and their secrets; it is not project Owner,
  billing access, or general player-database administration. Existing owner
  and service-account grants remain unchanged. Its Overview/Clients console
  pages request unrelated quota/service-account read permissions; do not widen
  the role just to open those pages. Existing-owner read-only checks suffice.
- **Verified approved Cloud terms:** owner separately approved first-use Google
  Cloud Platform terms; accepted without starting a free trial or billing.
  Initial OAuth setup also acknowledged the applicable API user-data policy.
- **Verified Firebase public identity:** General settings independently show
  Nestarium and `support@playnestarium.com`. All four email templates
  (verification, password reset, address change, MFA enrollment notification)
  were saved and individually read back with sender name Nestarium and matching
  support Reply-To. Default Firebase From address, bodies, subject placeholders,
  and action URLs remain unchanged. No provider or MFA feature was enabled.
- **Verified billing:** authenticated Cloud Billing API reads show G&A
  Production and Railcade Production enabled on the **same** billing account.
  The existing Nestarium development project is not billing-enabled. Owner
  authorized using that shared Daygull account if Blaze becomes necessary;
  do not create a new billing account or merge/replace Firebase projects.
  This mail/identity checkpoint requires no billing upgrade and made none.
  At the first Blaze-required backend deployment, verify shared-account linkage
  and appropriate project-scoped budget alerts before billable deployment.

Controlled two-way mail acceptance is complete; do not resend either setup
test. Resolve the cosmetic received-display-name issue separately. Keep normal
spam handling; no campaigns or messages to players. Independent-provider and
Apple private-relay acceptance are not proven by this company-inbox test.

Public Nestarium homepage/privacy/terms/support publication, remaining Google
brand/client/provider setup, guest-link/recovery acceptance, and the coordinated
protected-hostname cutover remain later gates. Cloudflare's shared Railcade
login stays untouched.
This checkpoint is infrastructure/documentation only: no new game build or
deployment. The previously verified release below remains current.
**Owner-confirmed audience (September 6):** actively include ages 8–12 alongside
teens and adults. This supersedes the previously unanswered audience question.
Plan for mixed-audience protections, subject to classification/legal review;
this is not a verified store rating, a worldwide minimum age, or clearance to
collect children's data. See `docs/PUBLIC_SITE.md` for the recommended sequence.
Do not copy the siblings' child-exclusion policy or enable Google sign-in before
reviewing SDK eligibility and the full non-Google account/recovery experience.

### Public-site preparation — local draft, not published

`cloudflare/public-site` now contains the separate non-playable homepage,
support, privacy, terms and account/data-request drafts. See
`docs/PUBLIC_SITE.md` for source-backed claims and release gates. The build
copies only 11 allowlisted files, including unchanged approved artwork; the
game bundle and authentication configuration cannot enter through directory
copying. There are no routes or enabled alternate hostnames. Draft markers,
no-index headers and a guarded deployment command prevent routine publication.

Build, nine focused tests and Wrangler 4.129.0 dry run pass. Local five-page
requests return 200; game-code paths and unknown routes return 404, all with
CSP/no-index headers. CI now includes the same focused tests. This does not
claim desktop/mobile visual acceptance or publication. No game source, build,
deployment, native ID, Firebase data or billing changed.

Source review found that the former in-app Delete Account action removes local
player data only, not Firebase Auth or Firestore records. Its label is now
Remove local player, with accurate scope warnings and matching support/data-page
drafts. Trusted cloud deletion must be completed before the account release; do not inherit the siblings'
completed deletion acceptance. Audience intent is now recorded; classification,
child-privacy implementation and policy approval remain open.

## Nestarium migration — current checkpoint

The public/product name is now **Nestarium** and the selected public domain is
`playnestarium.com`. See `docs/NESTARIUM_MIGRATION.md` for completed surfaces,
hostname gates, platform actions, and rollback/continuity decisions.
`docs/LEGACY_BRAND_REFERENCES.json` enumerates every retained legacy source
reference; run `node tool/audit_brand.mjs` to validate it.

UI/web metadata, all branded launcher/loading artwork, mobile display names,
safe desktop display fields, tooling/artifact names and project documentation
are migrated. Native bundle IDs, Firebase project/app IDs, all save/settings
keys and formats, Firestore paths/rules/data, repository remote, Worker resource
name and existing browser origin stay compatible. Windows CompanyName and
ProductName specifically remain unchanged because the preferences directory
depends on them. New exports use `nestarium-save-YYYY-MM-DD.json` while their
transfer format remains compatible with pre-rename exports/installations.

Firebase now displays **Nestarium Dev** with renamed existing app registrations.
The existing protected hostname and both selected Nestarium hostnames are
authorized. Cloudflare Access displays **Nestarium private playtest** and
protects the existing origin plus `playtest.playnestarium.com`, preserving the
existing tester policy and session duration. The Nestarium domain has mail-only
DNS but no game/web route yet. Google support/consent identity and cross-origin recovery
acceptance remain release gates; do not redirect existing players away from
their browser-local saves.

Access eager cookie redirects are **off** for this application: otherwise an
approved old-origin login was redirected through the unresolved staged domain.
Verified the corrected setting and successful return to the existing game.
The shared Access Google account chooser still says Railcade; do not rename
that shared OAuth client. A Nestarium-specific Access identity needs a separate
review alongside the game's Firebase provider/support identity.

The previously unreleased Google-linking implementation is gated off by default
with `NESTARIUM_GOOGLE_SIGN_IN_ENABLED`, because the Firebase Google provider
is still unconfigured. Existing anonymous cloud sync remains active. Native
OAuth/signing and store metadata review remain owner/platform actions.

Analysis, 509 Flutter tests, and the web release build pass on installed Flutter
3.47.2 / Dart 3.13.2; no lockfile update. Android debug build also passes, with
APK label Nestarium and unchanged package `com.egghatchers.game` / 1.0.0+1.
The three Cloudflare configuration tests and Wrangler 4.129.0 dry run pass
(306 assets). The older PATH SDK failed during asset export and became
unavailable; the installed alternate SDK completed regeneration. Do not change
system security settings to recover the old SDK.

### Deployed integration evidence — 2026-09-06

- Verified implementation commit `b6b0ea03e57234c320b690584286adeb98e830ab`
  is pushed to `origin/main`. The dependency lockfile and installed application
  version remain unchanged. The compatibility inventory passed before commit
  and again after staging (stable ordering across Windows and Linux).
- Required sequence completed: `flutter build web --release`, then from
  `cloudflare/playtest`, `npm test`, `npm run deploy:dry-run`, `npm run deploy`.
  Wrangler 4.129.0 reports the existing protected custom-domain route and
  current version **`96c170ee-88f5-4276-8ae8-7bdaf5449751`**.
- Local deployed `main.dart.js` SHA-256:
  `1cadfaf2280a54b19d7ddf8ad9dec5902ed88e0651fe6436155dff5004d08b1e`.
- Anonymous requests to `/`, `/main.dart.js`, `/manifest.json`, and the in-app
  logo return **302 to Cloudflare Access**, not game content. Approved Chrome
  refresh displays the Nestarium title; the deployed image visibly reads
  NESTARIUM. The same existing player's balance and collection state remain
  present with income continuing, in the unchanged portrait shell. No save
  import, reset, account replacement, purchase, or reward claim was performed.
- Final API read-back confirms only the old hostname is attached to the Worker,
  no Nestarium-zone DNS records, unchanged tester policy/session duration, and
  eager cookie redirects off. New-domain publication remains explicitly gated.
- [GitHub Verify run 34050144460](https://github.com/daygullstudios/egg_hatchers/actions/runs/34050144460)
  completed **successfully**, including analysis, compatibility inventory,
  tests, web build, server build, artifact packaging, and deployment-container
  smoke checks on the pre-existing Flutter 3.44.0 pin. No signed native/store
  release was made.

## Project status

Nestarium is a Flutter idle collection and battle game. It currently includes local multi-account saves, hatching and mutations, rebirths, quests, collections, fusions, custom eggs and sprites, three visual styles, manual boss fights, Bot Arena, live multiplayer battles, live trading, player invitations, collection viewing, and preset trade messages.

Recent polish includes projectile trails, staged boss music that layers intensity without restarting, pause-resume countdowns, improved boss backgrounds, a hidden DayGull Egg unlock path, DayGull animals with animated glitch effects, and a live coin balance that remains in the shared app bar throughout navigation. The hatchery labels its Rebirth-scoped animal-income total as `earned` and explains the total on hover or tap; misleading player-facing `lifetime` terminology has been removed.

The main game shell is adaptive rather than portrait-only: it preserves the established phone composition on compact displays, expands to a readable tablet workspace, and uses bounded multi-pane desktop layouts. The neutral surround remains outside the 1180px maximum game surface. The major game screens share persistent navigation; compact/tablet screens show Hatchery, Shop, Battles, Collection and More, while expanded desktop screens show all seven destinations directly. Tabs remain mounted so scroll and screen state survive switching and resizing. More opens an anchored secondary menu containing Quests, Custom Animals and Settings. All three are mounted shell destinations with the same coin/navigation header and preserved screen state. The Quests screen uses a single-open accordion, a pinned category jump control, a unified Ready to Claim section with Claim All for ordinary rewards, intelligent progress sorting, and hidden claimed quests.

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
2. Move the downloaded `nestarium-save-YYYY-MM-DD.json` file to the new computer.
3. On the new computer, open Settings and choose **Import Save**.
4. Confirm replacement and restart the game when prompted.

Import replaces all Nestarium local data on the destination browser. Keep the exported file as a backup until migration is verified.

## Known unfinished production work

- Protected matchmaking and battles use authenticated Durable Object/SQLite
  state with reconnect and idempotent result settlement. Production still needs
  a trusted inventory baseline, transactional trades, family capabilities,
  moderation/abuse controls, and representative device/network acceptance.
- Named local profiles remain local; the designated guest uses anonymous
  Firebase authentication and revisioned cloud sync. Provider recovery is staged.
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
Nestarium is explicitly treated as the legacy migration source rather than
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
The Nestarium migration above supersedes the original purchase-only checkpoint:
product/Firebase displays and authorized domains are now updated. DNS/Worker
routing and public email remain staged; no public product site is published.

The next identity slice is implemented but gated off pending provider setup. The
device guest can link Google on Web while preserving the anonymous UID and its
Firestore document. If the selected Google credential already belongs to an
Nestarium identity, the client opens that UID, clears the old local sync
ancestry, and requires the normal cloud/device comparison before accepting a
save. Cancellation and errors leave the guest save unchanged. Native Google
buttons remain fail-closed because the Android OAuth/SHA registration and iOS
client configuration are not provisioned yet. Firebase's Google provider still
requires the approved product support email and Nestarium consent branding.
The playtest hostnames are already in Firebase's authorized-domain list.

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
