# Nestarium product migration

Date: 2026-09-06. Source baseline: `ff80737` on the saved local `main`.
The worktree was clean before this migration. Public product: **Nestarium**.
Selected public domain: **playnestarium.com** (owner-selected and Cloudflare
verified active). This is a product rebrand, not a new application/data identity.

## Completed owned surfaces

- Flutter application class/title, onboarding labels and logo semantics,
  Hatchery fallback title, Settings import warning, and save-validation copy.
- Export filenames now use `nestarium-save-YYYY-MM-DD.json`; the JSON contents
  remain readable by existing installations and old exports still import.
- Web title, description, application/PWA names, loading/accessible text,
  Open Graph product metadata, favicon, launcher and maskable icons. The
  portrait shell, start URL, route paths, and private/no-index headers remain.
- Android/iOS display names, macOS application product and scheme/test-host
  references, Linux/Windows window titles and safe Windows file metadata.
  Publisher copyright credits Daygull Studios LLC.
- The old name embedded in the art is replaced by NESTARIUM. The checked-in
  source is `assets/branding/nestarium_source.png`; deterministic exports cover
  every platform launcher/splash and the in-app/loading logo. No pre-existing
  product screenshot files were tracked. Gameplay egg/animal art is unchanged.
- README, handoff, architecture/deployment instructions, tooling comments,
  server log title, CI artifact/container names, npm package display identity,
  and the unused Render recipe now use Nestarium. There are no configured
  analytics SDK labels/events to rename; Firebase app display names and the
  Cloudflare Access label are updated separately below.
- New `NESTARIUM_*` server configuration options accept the old options as
  fallbacks. Their precedence and the old save transfer format have regression
  coverage. An automated inventory classifies each remaining legacy reference.

## Compatibility decisions

`LEGACY_BRAND_REFERENCES.json` records **every current source occurrence** with
path, line, matched reference and reason. Regenerate it after reviewed edits
with `node tool/audit_brand.mjs --write`, then run without `--write` to verify.
The scanner itself is excluded to avoid self-reporting its matching rules.
Generated build/cache directories and Git history are not public source and
are rebuilt rather than rewritten. Historical commits remain immutable.

- `egg_hatchers` stays the private Dart package/import identity and repository
  checkout/remote name. No GitHub repository move or remote rewrite is needed.
- `com.egghatchers.game` and matching native test IDs stay unchanged. Android
  namespace/Kotlin paths, Apple bundle IDs, and Linux application ID remain
  aligned with installs and Firebase registrations.
- Existing Windows/Linux executable names remain compatible with launchers.
  Windows `CompanyName` and `ProductName` must both stay **Egg Hatchers**:
  `path_provider_windows` 2.3.0 derives the support directory from those fields,
  and `shared_preferences_windows` 2.4.1 stores preferences there. Renaming
  them would silently open a different save location. The window title and
  FileDescription say Nestarium; changing these two storage fields needs a
  dedicated tested directory migration. The audit enforces this boundary.
- All local preference/session keys, account IDs, guest Firebase-UID bindings,
  identity generations, settings namespaces, progress envelopes/fingerprints,
  backups and sync checkpoints remain byte-compatible.
- `egg_hatchers_save`, `egg_hatchers_player_progress`,
  `egg_hatchers_cloud_progress`, and `users/<uid>/products/egg_hatchers` remain
  serialization/database contracts. No save or Firestore schema/rules/data
  migration is performed. JSON exports never transfer authentication metadata.
- Firebase project `egg-hatchers-dev`, app IDs, API keys, bucket, default auth
  handler domains, bundle registrations and any OAuth client identifiers stay
  unchanged. Display names can change without replacing these resources.
- Worker `egg-hatchers-playtest` and its old hostname remain the active release
  target to preserve deployment history, rollback, browser saves and sessions.
  No redirect is installed. Route paths, WebSocket protocol and local port
  53218 remain stable. Old environment options continue to work.
- Egg Shop, Hatchery, hatching, egg types, animal IDs, guest display names and
  player-created content are gameplay/user data, not obsolete product branding.
  No stored player names, custom sprites, or save contents are rewritten.

## Verified infrastructure and hostname state

- Firebase project display: **Nestarium Dev**. Existing Web/Android/iOS app
  displays: **Nestarium Dev Web**, **Nestarium Dev Android**, **Nestarium Dev
  iOS**. The four display-name-only API updates were read back successfully.
- Firebase authorized domains preserve every prior entry and add the existing
  playtest origin, `playtest.playnestarium.com`, and `playnestarium.com`.
- Owner-approved Nestarium-only `roles/oauthconfig.editor` access for
  `support@playnestarium.com` is saved and independently verified, matching the
  sibling support model without wider project/billing permissions. First-use
  Cloud terms were separately approved and accepted; no trial or billing change.
- Google OAuth branding is initialized as **Nestarium**, support email
  `support@playnestarium.com`, External audience in **Testing**. Owner read-back
  shows no clients or test users; public URLs/domain verification are incomplete.
  Firebase General settings independently reflect the same public name/email.
  All four Firebase email templates now use sender name Nestarium and that
  Reply-To; default From, bodies, subject placeholders and action URLs are intact.
- Anonymous authentication remains enabled. No Google provider is configured.
  The previously committed Google-linking implementation was unreleased; it
  is now explicitly gated by `NESTARIUM_GOOGLE_SIGN_IN_ENABLED` (default false)
  so a rebrand deploy does not publish a nonfunctional sign-in action. Guest
  cloud-sync behavior and existing protected-identity restoration remain.
- Access application `2ed23c5f-4d30-42e9-83c4-90b4e24c2135` is now **Nestarium
  private playtest**, retaining its single existing tester policy and 24-hour
  session. It protects both the old hostname and the staged
  `playtest.playnestarium.com`. API writes returned error 1010 without changes;
  the authenticated dashboard completed the update, verified by API read-back.
- Access's eager cookie redirects initially sent an approved login through the
  unrouted staged hostname. Corrected by setting this app's **Eager redirect
  cookie** off, verified by API read-back; authorization cookies are now issued
  on hostname visit. The existing game origin opens successfully again. Policy,
  session duration, and other applications were not changed. See Cloudflare's
  [authorization-cookie documentation](https://developers.cloudflare.com/cloudflare-one/access-controls/applications/http-apps/authorization-cookie/#eager-redirect-cookie).
- The shared Access identity provider still presents **Railcade** on Google's
  account chooser. That is separate from Firebase game-account sign-in. Do not
  rename this shared OAuth client and alter Railcade's consent branding; a
  reviewed Nestarium-specific Access identity is a remaining infrastructure
  action, not a reason to weaken the playtest gate.
- `playnestarium.com` has mail-only MX/TXT records after the support-readiness
  continuation; it has no web-address DNS records or attached game Worker.
  The staged playtest hostname is deliberately **unrouted**, and the apex is
  reserved for the later public product surface. Access configuration alone
  does not publish the game. Ordinary deployment tests reject a new-domain
  route until this gate is deliberately revised.

## Hostname cutover and owner/platform actions

1. `support@playnestarium.com` forwarding and authenticated sending DNS are
   configured using the existing studio email model. Controlled receipt, label,
   SPF/DKIM/DMARC and first Sent copy pass. Thunderbird automatically chooses
   the matching Nestarium reply identity; the return-test Send confirmation and
   reply receipt/authentication/Sent-copy acceptance remain open. The local Nestarium
   identity is saved with matching From/Reply-To, existing family Cloudflare
   SMTP, and company Sent/Drafts. The sibling-model Google role account is now
   created and verified as Nestarium Support / support@playnestarium.com after
   owner-authorized terms acceptance. No new Gmail mailbox. The Nestarium-only
   OAuth Config Editor grant and initial support-email selection are now saved
   and verified. Gmail's new exact-address Nestarium / Support filter only
   labels mail; existing filters and normal spam handling remain intact. Do not
   publish an untested support/recovery workflow. See PROJECT_HANDOFF.md for
   the latest evidence, shared-billing decision, and next acceptance steps.
2. Complete the remaining Google provider/OAuth brand configuration. The
   Nestarium name and approved support identity are saved in Testing; public
   homepage/privacy/terms/support pages, consent-screen domain,
   verification and publishing status remain release gates. Confirm intended
   age audience before finalizing policy/auth decisions; no Nestarium audience
   designation was found in current sources. Retain existing project/client IDs
   and Firebase handler URLs. No provider credentials were replaced here.
   The isolated local website draft, allowlisted build and closed publication
   gates are documented in `PUBLIC_SITE.md`; no public route was deployed.
   Review a Nestarium-specific Access login identity separately from Firebase;
   the current shared Railcade Google identity was intentionally not renamed.
3. Enable the staged Web Google button in a deliberate provider release; prove
   guest linking preserves the UID and cloud document, then prove recovery
   from a second browser. Native OAuth/SHA configuration still needs its own
   acceptance; Apple signing/build/device work remains on the Mac.
4. Before routing the new hostname, verify Access rejects anonymous requests
   to HTML and compiled assets, TLS/DNS and Firebase domains are ready, and
   approved browsers pass sign-in/recovery. Preserve the old protected origin
   as a recovery route. Browser localStorage, IndexedDB and anonymous Firebase
   credentials do **not** move automatically between hostnames. Export/import
   copies local progress/settings only; it does not preserve an anonymous UID.
   Do not redirect old-origin players or tell them to clear browser data.
5. Update existing App Store/Google Play product names, descriptions, icons,
   screenshots, support/privacy URLs and any console-only titles at the next
   reviewed release. Store records and current listing availability were not
   verified in this task. Do not create records, change bundle IDs or submit.
   Windows/macOS/Linux package/installer acceptance also remains platform QA.
6. Review external GitHub display metadata, CI consumers of renamed artifact
   files, and any previously linked Render Blueprint before external updates.
   The repo remote remains canonical. No store submission, domain purchase,
   trademark filing, credential replacement or production-data change occurred.

## Validation and deployment

Analysis, all 509 Flutter tests, and `flutter build web --release` pass with the
already installed Flutter 3.47.2 / Dart 3.13.2 SDK. An additional Android debug
build passes; `aapt dump badging` verifies `application-label:'Nestarium'` and
unchanged package `com.egghatchers.game`, version 1.0.0+1. No device installation
or signed release was performed. The three Cloudflare config tests and Wrangler
4.129.0 deployment dry run pass (306 assets). Dependency lockfile is unchanged.
The PATH SDK was
Flutter 3.47.1 / Dart 3.13.1; its asset run crashed and its executable then became
unavailable. The installed alternate SDK completed all asset exports; no system
SDK/security setting was changed. The deployment receipt is added
at the completed integration checkpoint in PROJECT_HANDOFF.md.

The repository's pre-existing CI/Docker Flutter pin is 3.44.0 and was not
upgraded. [GitHub Verify run 34050144460](https://github.com/daygullstudios/egg_hatchers/actions/runs/34050144460)
completed successfully, including the deployment-container smoke check. The
verified source is `b6b0ea0`; the protected Worker release is
`96c170ee-88f5-4276-8ae8-7bdaf5449751`. The post-deploy browser refresh shows
Nestarium with the existing player's progress; anonymous HTML and asset
requests still redirect to Access. Full receipt is in PROJECT_HANDOFF.md.
