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

1. Confirm Nestarium's intended audience, evaluate the product/marketing and
   data collection accordingly, then resolve the age section. Owner intent is
   an input, not a legal classification by itself. Do not blindly copy the
   siblings' under-13 statement. Review the draft policies against the actual
   product; these are implementation drafts, not attorney clearance.
2. Complete controlled support receipt, authenticated reply and Gmail Sent-copy
   acceptance using the saved Thunderbird identity. Preserve ordinary Spam and
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
- [Google OAuth brand verification](https://developers.google.com/identity/protocols/oauth2/production-readiness/brand-verification)
- [FTC COPPA FAQs](https://www.ftc.gov/business-guidance/resources/complying-coppa-frequently-asked-questions)
- [Cloudflare static assets](https://developers.cloudflare.com/workers/static-assets/binding/)
- [Cloudflare headers](https://developers.cloudflare.com/workers/static-assets/headers/)
- [Cloudflare custom domains](https://developers.cloudflare.com/workers/configuration/routing/custom-domains/)
