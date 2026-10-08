# Nestarium support and deletion link verification

Updated: 2026-10-08

Use this checklist for the exact release candidate after launch platforms and
launch countries are selected. It does not publish policy copy, approve public launch,
approve store submission, or close account-deletion/support roadmap items by
itself.

## Verification identity

- Candidate Git commit: TBD
- Release owner: TBD
- Support owner: TBD
- Launch platforms: TBD
- Launch countries: TBD
- Public site version: TBD
- Store listing draft version: TBD
- Verification date: TBD

## Public routes to verify

Verify these routes on the candidate public information site:

- `https://playnestarium.com/support`
- `https://playnestarium.com/privacy`
- `https://playnestarium.com/terms`
- `https://playnestarium.com/delete-account`

Record for each route:

- Loads without authentication:
- Uses the approved Nestarium domain:
- Has no playtest link, temporary tunnel, Flutter bundle, tracker, form, script,
  credential, or private support document:
- Mail link opens the approved role address:
- Copy matches the exact candidate behavior:
- Screenshot or archive reference:

## Store-entry checks

For every selected store or platform, record:

- Store/platform name:
- Store listing URL or draft reference:
- Support URL shown in the store:
- Privacy Policy URL shown in the store:
- Terms URL shown in the store:
- Account-deletion URL shown in the store:
- Support email or role inbox:
- Verification result:

Google Play Data Safety and Apple privacy answers must cite the same public
policy/support/deletion URLs and the final candidate behavior.

## In-app checks

On each selected platform, verify:

- Settings exposes account/save controls.
- Protected players can find `Delete cloud account`.
- The cloud deletion confirmation says the Nestarium cloud account and synced cloud progress are deleted.
- The local player remains on the device after cloud deletion.
- `Remove local player` remains local-only.
- Save Transfer export/import remains available.
- Support instructions are reachable from the selected store or public site.
- Provider reauthentication prompts, if any, are understandable and recoverable.

## Support inbox checks

Before launch:

- Confirm `support@playnestarium.com` receives mail.
- Confirm replies can be sent from the approved support owner or process.
- Confirm `launch@playnestarium.com` and `legal@daygullstudios.com` route to
  the approved owners if they are used in public pages.
- Confirm support staff know not to ask for passwords, one-time codes,
  authentication tokens, full browser storage dumps, government IDs, private
  Save Transfer files, or child/guardian data unless the approved support
  process explicitly requires it.
- Confirm private account data is handled according to the approved retention and deletion rules.

## Deletion evidence to attach

Attach or cite:

- `docs/RELEASE_CLOUD_ACCOUNT_DELETION_EVIDENCE.md`.
- `docs/PUBLIC_POLICY_READINESS.md`.
- `cloudflare/public-site/src/delete-account.html`.
- `cloudflare/public-site/src/support.html`.
- `test/settings_account_test.dart`.
- `test/account_protection_service_test.dart`.
- Public-site release audit result.
- Store link screenshots or review notes for selected platforms.

## Stop conditions

Do not close the support/deletion release gate if any of these occur:

- A selected store points to the wrong support, privacy, terms, or deletion URL.
- `delete-account` copy disagrees with the exact candidate behavior.
- Support mail does not receive or reply correctly.
- A public page exposes a playtest route, temporary tunnel, credential, script,
  tracker, playable game bundle, or private support document.
- In-app cloud deletion fails to preserve local progress.
- Local player removal is described as cloud deletion.
- Provider reauthentication blocks deletion without a recoverable explanation.
- Store/public copy promises a privacy, family, retention, support, or deletion
  behavior that has not been implemented and tested.
