# Nestarium Project Handoff

Updated: 2026-09-06

## Damaged progress and local-backup recovery — current implementation checkpoint

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
Protected deployment/live acceptance is the remaining step of this checkpoint.
No real player is damaged or restored for QA.

Next: broader offline startup and storage-outage acceptance, including failures
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
