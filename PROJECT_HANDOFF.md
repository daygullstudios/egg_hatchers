# Nestarium Project Handoff

Updated: 2026-09-06

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
2. Move the downloaded `nestarium-save-YYYY-MM-DD.json` file to the new computer.
3. On the new computer, open Settings and choose **Import Save**.
4. Confirm replacement and restart the game when prompted.

Import replaces all Nestarium local data on the destination browser. Keep the exported file as a backup until migration is verified.

## Known unfinished production work

- Multiplayer rooms and presence are held in server memory. Production needs authenticated server accounts, durable database storage, transactional trades, reconnect handling, moderation controls, and abuse protection.
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
