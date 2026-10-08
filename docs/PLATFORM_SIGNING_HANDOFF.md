# Nestarium platform signing handoff

Updated: 2026-10-08

Use this handoff only after the owner chooses Android and/or iOS as launch
platforms. It does not select a platform, create credentials, approve store submission,
or close any platform/store roadmap item. It records the safe path for creating
signing material and the evidence that must be attached to the release
candidate.

## Handoff identity

- Selected platforms: TBD
- Release owner: TBD
- Credential owner: TBD
- Build operator: TBD
- Candidate commit: TBD
- Candidate version/build number: TBD
- Credential storage location reference: TBD

## Android signing handoff

Only do this if Android is selected:

- Create a Google Play upload keystore outside the repository.
- Store keystore passwords and key passwords in the approved password manager,
  not in Git, chat, screenshots, logs, or issue text.
- Create local `android/key.properties` from `android/key.properties.example`.
- Keep `android/key.properties`, `*.jks`, and `*.keystore` untracked.
- Build the signed App Bundle from the frozen candidate.
- Record the App Bundle path and checksum in
  `docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md`.
- Inspect package name, version name, version code, app icon, app label,
  permissions, signing status, and supported architectures.
- Verify support and account-deletion links from the Google Play listing.
- Complete Google Play Data Safety answers from the exact candidate behavior.

Stop if the keystore, passwords, `android/key.properties`, App Bundle, or Play
Console screenshots contain secrets in a commit, public artifact, or chat.

## iOS signing handoff

Only do this if iOS is selected:

- Use the approved Apple Developer account and selected Team ID.
- Confirm bundle identifier and app record before archiving.
- Keep certificates, provisioning profiles, App Store Connect credentials, and
  export options out of Git.
- Archive the frozen candidate on the approved Mac path.
- Run a real-device test before App Store submission.
- Record the archive/build identifier in
  `docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md`.
- Inspect app icon, launch image, app label, bundle identifier, version/build,
  entitlements, signing team, and privacy-sensitive capabilities.
- Verify support and account-deletion links from the App Store listing.
- Complete Apple privacy answers from the exact candidate behavior.

Stop if certificates, profiles, App Store credentials, raw notarization/export
logs with secrets, or private screenshots are committed or shared publicly.

## Shared store handoff

For every selected platform:

- Use `docs/STORE_LISTING_DRAFT_CHECKLIST.md` for app name, descriptions,
  screenshots, ratings, disclosures, support URL, privacy URL, terms URL, and
  account-deletion URL.
- Use `docs/FAMILY_PRIVACY_REVIEW_INTAKE.md` and the approved review output for
  audience, privacy, and guardian/parent-control answers.
- Use `docs/MUSIC_RIGHTS_AND_LISTENING_SIGNOFF.md` and
  `docs/ASSET_RIGHTS_RELEASE_AUDIT.md` for shipped asset source evidence.
- Use `docs/CROSS_PLATFORM_ACCEPTANCE_MATRIX_TEMPLATE.md` for selected-platform
  account/save/multiplayer acceptance.
- Do not upload a build from a dirty working tree.
- Do not submit a store build until the release owner and rollback decision
  maker approve the exact candidate.

## Evidence to attach

Attach or cite:

- Candidate commit and tag/build.
- Selected platforms and launch countries.
- Android App Bundle checksum, if Android is selected.
- iOS archive/build identifier, if iOS is selected.
- Store listing copy source version.
- Screenshot capture commit and device list.
- Google Play Data Safety or Apple privacy answer source.
- Support/account-deletion URL verification result.
- Signing credential storage reference without secrets.
- Owner approval for store submission.

## Repository safety check

Before commit or release, verify:

- `android/key.properties` does not exist in Git.
- `*.jks` and `*.keystore` do not exist in Git.
- No certificate, provisioning profile, password, API token, or store credential
  is present in the repository.
- The release candidate record contains references and checksums, not secrets.
