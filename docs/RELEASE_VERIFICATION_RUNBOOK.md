# Release Verification Runbook

Use this runbook only for a frozen release candidate. It complements GitHub CI;
it does not replace owner approval, live platform testing, or closed beta.

## Local Candidate Commands

Run from the repository root unless noted:

```powershell
flutter pub get
flutter analyze
node tool/audit_brand.mjs
node tool/audit_release_evidence.mjs
node tool/audit_public_policy_links.mjs
node tool/audit_asset_rights.mjs
flutter test
flutter build web --release --no-pub
node tool/audit_release_surface.mjs
dart compile exe tool/multiplayer_server.dart -o build/nestarium-server
```

Public information site:

```powershell
cd cloudflare/public-site
npm test
npm run deploy:dry-run
```

Protected playtest:

```powershell
cd cloudflare/playtest
npm test
npm run build:web
npm run deploy:dry-run
```

Protected multiplayer Worker:

```powershell
cd cloudflare/multiplayer
npm install
npm run typecheck
npm test
npm run deploy:dry-run
```

## CI Evidence

`.github/workflows/verify.yml` currently verifies:

- `flutter analyze`
- `node tool/audit_brand.mjs`
- `node tool/audit_release_evidence.mjs`
- `node tool/audit_public_policy_links.mjs`
- `node tool/audit_asset_rights.mjs`
- `cloudflare/public-site` tests
- `flutter test`
- `flutter build web --release --no-pub`
- `node tool/audit_release_surface.mjs`
- Hosted server compile and release packaging
- Deployment container smoke test with `docker build` and `docker run`

The release candidate record should cite the CI run URL and artifact reference.

## Candidate Deployment Evidence

Before public routing or store submission, record:

- Git commit and tag/build.
- Web build artifact checksum or storage location.
- Protected playtest Worker version ID.
- Multiplayer Worker version ID.
- Public-site Worker version ID, if changed.
- Android App Bundle checksum, if Android is selected.
- iOS archive/build identifier, if iOS is selected.
- Release build artifact backup location.

## Compatibility Audits

Run and record:

- Brand/legacy compatibility audit: `node tool/audit_brand.mjs`
- Release-evidence index audit: `node tool/audit_release_evidence.mjs`
- Public policy/support link audit: `node tool/audit_public_policy_links.mjs`
- Asset rights inventory audit: `node tool/audit_asset_rights.mjs`
- Release-surface audit: `node tool/audit_release_surface.mjs`
- Save Transfer compatibility result from the candidate matrix.
- Cross-platform account/save/multiplayer matrix result from
  `docs/CROSS_PLATFORM_ACCEPTANCE_MATRIX_TEMPLATE.md`.

## Exit Rule

The roadmap item "Run analysis, all tests, compatibility audit and every
release build" remains open until the exact candidate has all required command
results, CI evidence, selected-platform build evidence and owner review recorded
in `docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md`.

