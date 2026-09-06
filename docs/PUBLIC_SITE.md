# Nestarium public information site

## September 6, 2026 checkpoint — local review draft, not deployed

`cloudflare/public-site` owns the non-playable Nestarium homepage, support,
privacy, terms and account/data-request pages. It follows the sibling products'
separation between the public information site and the protected game. This is
not a new game origin, a store listing or a published/effective legal agreement.

The selected future canonical domain is `playnestarium.com`. The configuration
has **no routes**, and both `workers_dev` and `preview_urls` are false. No live
Worker, domain route, DNS record, credential or billable backend was created by
this checkpoint. The existing protected game deployment remains unchanged.

## Source and data accuracy

### September 6 continuation — audience confirmed, controlled mail accepted

- **Owner-confirmed product intent:** ages 8–12 are deliberately included
  alongside teens and adults. Do not ask this same intent question again or
  describe Nestarium as excluding under-13 players by default. This is not a
  toddler/preschool designation or an approved store age rating.
- **Recommended planning basis, not legal clearance:** mixed-audience design.
  The approachable animal collection/discovery loop serves younger players;
  fusion, teams, upgrades and long-term progression provide older-player depth.
  This is product judgment, not measured customer demographics. Final legal
  classification depends on the actual product, presentation, marketing and
  audience evidence; review it before public release.
- **Unvalidated usability hypothesis:** typical independent play is more
  plausible around ages 10–12 and up; ages 8–9 may need stronger onboarding or
  occasional adult help with fusion losses, rebirth and income/team strategy.
  The owner's experienced child testers are useful but not representative
  proof. Test comprehension with varied experience levels before making age
  suitability claims. This hypothesis does not narrow the confirmed audience,
  create an official minimum age, or exempt advanced children from protections.
- **Verified mail:** both owner-only test directions arrived in company Inbox,
  passed SPF/DKIM/DMARC, and have company Sent copies. Thunderbird's actual
  Reply automatically selects the Nestarium identity. The return receipt is
  signed by `playnestarium.com` and has matching support From/Reply-To. Gmail
  displays its received sender name as the address rather than Nestarium
  Support; investigate that cosmetic issue separately. No independent-provider
  or Apple private-relay delivery claim follows from these tests.
- `audienceDecisionRecorded` means the owner's product intent is recorded,
  not that child-privacy compliance is complete. The controlled mail gate is
  also satisfied. Policy/support approval and hostname/header readiness remain
  false, every public page remains a draft, and publication remains blocked.

Recommended next work, before revising the public policy or enabling accounts:

1. Audit startup collection (including anonymous Firebase identity), SDK terms,
   online names/profiles, multiplayer/trades, support, retention and cloud
   deletion against the intended audience and launch regions.
2. Design minimal age handling before non-permitted collection, an appropriately
   restricted child experience, and parent consent/access/deletion where
   required. A checkbox or a Google login alone is not proof of parental consent.
   Evaluate any internal-operations exception narrowly; do not assume guest or
   anonymous means data-free. Do not collect a full birth date without need.
3. Preserve the shared core game and preset-only communication. Review public
   identifiers and adult controls for social features; do not introduce open
   chat. Keep custom artwork local unless a separate sharing review is approved.
4. Google must stay optional for a mixed-audience app, with the entire app
   accessible without a Google account under Google's policy. Design a reviewed
   non-Google recovery path and parent-managed options; don't simply block
   children from the game or make Google the only way to use important features.
5. Review random-reward monetization, loss/fusion warnings and daily-pressure
   mechanics for the intended ages before adding ads or purchases. No paid
   randomized eggs, advertising SDK or monetization policy was authorized here.
6. Implement/test those controls, obtain policy/classification review and
   appropriate family usability testing, then complete public policy/auth gates.
   No child participant, parent contact, enrollment or public launch is authorized
   merely by recording the target audience.

The current `AUDIENCE_REVIEW_REQUIRED` page markers now mean the compliance and
policy review remains unfinished, not that the owner's audience is unknown.

### Current implementation evidence

- Approved Nestarium logo/favicon are copied byte-for-byte from the existing
  web artwork; no generated placeholder art, private screenshot or gameplay
  bundle is included.
- `lib/services/firebase_progress_repository.dart` and `lib/models/player_state.dart`
  establish core cloud-save contents. Device settings/custom content are not
  all part of that document; do not promise universal settings/art recovery.
- `lib/services/save_transfer_service.dart` establishes that exports include
  local player information/settings and imports replace destination storage.
  Exports deliberately exclude device-authentication bindings.
- `lib/services/account_service.dart`, `lib/services/account_storage.dart`,
  `lib/screens/settings_screen.dart` and `firestore.rules` establish that the
  current Delete Account action is local removal, not Firebase Auth/Firestore
  erasure. Full trusted cloud deletion and truthful in-app labeling remain
  required account-release work. Do not delete a real player to test this.
- `lib/services/online_lobby_service.dart` and `tool/multiplayer_server.dart`
  establish profile/presence/session sharing for available online tests.
  Custom-sprite copy and storage explicitly say artwork is device-local.
- `pubspec.yaml` contains no advertising, purchase, Analytics or Crashlytics
  SDK. This is not a claim that providers keep no technical/security logs.
- Google sign-in remains gated off. Public draft language describes the
  current test rather than pretending the eventual recovery path is ready.

Product support is `support@playnestarium.com`; legal/privacy uses the shared
studio legal role. No separate launch alias, forms, subscription list, trackers,
third-party fonts, uploads, sign-in controls or account database were added.

## Build and checks

From `cloudflare/public-site`:

```text
npm run build
npm test
npm run deploy:dry-run
npm run dev
```

The build writes exactly **11 allowlisted files** into the separate ignored
`build/nestarium-public-site` directory. Unexpected output files fail the build
instead of being silently uploaded or deleted. Never substitute `build/web`.
The 9 focused tests cover the asset boundary, original artwork bytes, document
metadata, internal links, approved contacts, no scripts/private links, restrictive
headers, accurate support copy, draft publication guard and protected-game route.

Verified locally with Wrangler 4.129.0:

- Build, 9/9 tests and deployment dry run pass; no bindings or game code.
- `/`, `/support`, `/privacy`, `/terms`, `/delete-account` return HTTP 200.
- `/main.dart.js`, `/flutter_bootstrap.js`, `/assets/AssetManifest.bin` and an
  unknown route return HTTP 404, not an application-shell fallback.
- Successful and missing-page responses carry the restrictive CSP and
  `X-Robots-Tag: noindex, nofollow`.
- The local review preview uses port 53219, leaving the usual game port alone.
  Desktop/phone visual and enlarged-text acceptance remain to be performed;
  markup checks are not a substitute for those checks.

No Flutter source/platform asset changed, so valid previous game analysis,
tests and release evidence were not repeated. No playtest deployment is needed
for an incomplete, unpublished public-site review draft.

## Publication gates and order

`npm run deploy` refuses publication while any gate in
`release-readiness.json` remains false or any draft marker remains. Do not flip
flags just to make deployment succeed; record supporting evidence first.

1. Use the confirmed audience above, evaluate the product/marketing and
   data collection accordingly, then resolve the age section. Owner intent is
   an input, not a legal classification by itself. Do not blindly copy the
   siblings' under-13 statement. Review the draft policies against the actual
   product; these are implementation drafts, not attorney clearance.
2. Preserve the completed controlled support receipt, authenticated reply and
   Gmail Sent-copy acceptance using the saved Thunderbird identity. Investigate
   the cosmetic received sender name separately. Preserve ordinary Spam and
   Inbox behavior; no player/customer messages are setup tests.
3. Finalize the effective policy/terms, dates, data-request procedure and
   platform-specific disclosures. Remove review markers only after approval.
   Full self-service deletion is still a game-release gate even if a verified
   support-request page is published first.
4. Review domain ownership, the exact apex-only route and security headers,
   DNS/TLS readiness and absence of a playable bundle. Add only the canonical
   public route to this site's config. Keep alternate previews disabled and
   decide indexability deliberately; do not expose the playtest hostname.
5. Run tests, build and dry run, then the guarded deploy. Record the version ID,
   live exact-page/artwork checks, 404 game-file checks and security headers.
   Keep `email_off` guards and verify Cloudflare did not inject a mail decoder
   or analytics script incompatible with CSP.
   The current tests intentionally assert the draft/no-route state; update
   those assertions in the reviewed publication patch, preserving the exact
   asset allowlist, contact and no-game/no-private-host protections.
6. Only after the real public URLs are ready, complete Google branding/domain
   review. Provider setup, linking/recovery acceptance and protected-game host
   cutover are separate gates in `NESTARIUM_MIGRATION.md`.

## Primary references reviewed

- [Google API Services User Data Policy](https://developers.google.com/terms/api-services-user-data-policy)
- [Google Play Families requirements](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en)
- [Google OAuth brand verification](https://developers.google.com/identity/protocols/oauth2/production-readiness/brand-verification)
- [FTC COPPA FAQs](https://www.ftc.gov/business-guidance/resources/complying-coppa-frequently-asked-questions)
- [Cloudflare static assets](https://developers.cloudflare.com/workers/static-assets/binding/)
- [Cloudflare headers](https://developers.cloudflare.com/workers/static-assets/headers/)
- [Cloudflare custom domains](https://developers.cloudflare.com/workers/configuration/routing/custom-domains/)
