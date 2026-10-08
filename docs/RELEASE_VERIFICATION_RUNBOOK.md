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
node tool/audit_release_decisions.mjs
node tool/audit_public_policy_links.mjs
node tool/audit_asset_rights.mjs
node tool/audit_audio_release.mjs
node tool/audit_music_rights_listening.mjs
node tool/audit_platform_branding.mjs
node tool/audit_platform_store.mjs
node tool/audit_platform_signing_handoff.mjs
node tool/audit_store_listing_checklist.mjs
node tool/audit_multiplayer_production.mjs
node tool/audit_multiplayer_two_device_playtest.mjs
node tool/audit_monitoring_operations.mjs
node tool/audit_operations_dry_run.mjs
node tool/audit_release_reliability.mjs
node tool/audit_release_code_review.mjs
node tool/audit_release_feature_freeze.mjs
node tool/audit_security_review.mjs
node tool/audit_cross_platform_acceptance.mjs
node tool/audit_closed_beta_readiness.mjs
node tool/audit_closed_beta_tester_packet.mjs
node tool/audit_rollback_rehearsal.mjs
node tool/audit_release_candidate_record.mjs
node tool/audit_gradual_release_monitoring.mjs
node tool/audit_monetization_boundary.mjs
node tool/audit_family_privacy_gate.mjs
node tool/audit_family_privacy_review_intake.mjs
node tool/audit_gameplay_economy.mjs
node tool/audit_custom_eggs_retired.mjs
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
- `node tool/audit_release_decisions.mjs`
- `node tool/audit_public_policy_links.mjs`
- `node tool/audit_asset_rights.mjs`
- `node tool/audit_audio_release.mjs`
- `node tool/audit_music_rights_listening.mjs`
- `node tool/audit_platform_branding.mjs`
- `node tool/audit_platform_store.mjs`
- `node tool/audit_platform_signing_handoff.mjs`
- `node tool/audit_store_listing_checklist.mjs`
- `node tool/audit_multiplayer_production.mjs`
- `node tool/audit_multiplayer_two_device_playtest.mjs`
- `node tool/audit_monitoring_operations.mjs`
- `node tool/audit_operations_dry_run.mjs`
- `node tool/audit_release_reliability.mjs`
- `node tool/audit_release_code_review.mjs`
- `node tool/audit_release_feature_freeze.mjs`
- `node tool/audit_security_review.mjs`
- `node tool/audit_cross_platform_acceptance.mjs`
- `node tool/audit_closed_beta_readiness.mjs`
- `node tool/audit_closed_beta_tester_packet.mjs`
- `node tool/audit_rollback_rehearsal.mjs`
- `node tool/audit_release_candidate_record.mjs`
- `node tool/audit_gradual_release_monitoring.mjs`
- `node tool/audit_monetization_boundary.mjs`
- `node tool/audit_family_privacy_gate.mjs`
- `node tool/audit_family_privacy_review_intake.mjs`
- `node tool/audit_gameplay_economy.mjs`
- `node tool/audit_custom_eggs_retired.mjs`
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
- Release decision packet audit: `node tool/audit_release_decisions.mjs`
- Public policy/support link audit: `node tool/audit_public_policy_links.mjs`
- Asset rights inventory audit: `node tool/audit_asset_rights.mjs`
- Audio release audit: `node tool/audit_audio_release.mjs`
- Music rights/listening audit:
  `node tool/audit_music_rights_listening.mjs` for
  `docs/MUSIC_RIGHTS_AND_LISTENING_SIGNOFF.md`
- Platform branding audit: `node tool/audit_platform_branding.mjs`
- Platform store audit: `node tool/audit_platform_store.mjs`
- Platform signing handoff audit:
  `node tool/audit_platform_signing_handoff.mjs` for
  `docs/PLATFORM_SIGNING_HANDOFF.md`
- Store listing checklist audit: `node tool/audit_store_listing_checklist.mjs`
- Multiplayer production audit: `node tool/audit_multiplayer_production.mjs`
- Multiplayer two-device playtest audit:
  `node tool/audit_multiplayer_two_device_playtest.mjs` for
  `docs/MULTIPLAYER_TWO_DEVICE_PLAYTEST_SCRIPT.md`
- Monitoring operations audit: `node tool/audit_monitoring_operations.mjs`
- Operations dry-run audit: `node tool/audit_operations_dry_run.mjs`
- Release reliability audit: `node tool/audit_release_reliability.mjs`
- Release code review audit: `node tool/audit_release_code_review.mjs`
- Release feature-freeze audit:
  `node tool/audit_release_feature_freeze.mjs` for
  `docs/RELEASE_FEATURE_FREEZE_CHECKLIST.md`
- Security review audit: `node tool/audit_security_review.mjs`
- Cross-platform acceptance audit: `node tool/audit_cross_platform_acceptance.mjs`
- Closed beta readiness audit: `node tool/audit_closed_beta_readiness.mjs`
- Closed beta tester packet audit:
  `node tool/audit_closed_beta_tester_packet.mjs` for
  `docs/CLOSED_BETA_TESTER_PACKET.md`
- Rollback rehearsal audit: `node tool/audit_rollback_rehearsal.mjs`
- Release candidate record audit: `node tool/audit_release_candidate_record.mjs`
- Gradual release monitoring audit:
  `node tool/audit_gradual_release_monitoring.mjs` for
  `docs/GRADUAL_RELEASE_MONITORING_CHECKLIST.md`
- Monetization boundary audit: `node tool/audit_monetization_boundary.mjs`
- Family privacy gate audit: `node tool/audit_family_privacy_gate.mjs`
- Family privacy review intake audit:
  `node tool/audit_family_privacy_review_intake.mjs` for
  `docs/FAMILY_PRIVACY_REVIEW_INTAKE.md`
- Gameplay economy audit: `node tool/audit_gameplay_economy.mjs`
- Custom egg retirement audit: `node tool/audit_custom_eggs_retired.mjs`
- Release-surface audit: `node tool/audit_release_surface.mjs`
- Save Transfer compatibility result from the candidate matrix.
- Cross-platform account/save/multiplayer matrix result from
  `docs/CROSS_PLATFORM_ACCEPTANCE_MATRIX_TEMPLATE.md`.

## Exit Rule

The roadmap item "Run analysis, all tests, compatibility audit and every
release build" remains open until the exact candidate has all required command
results, CI evidence, selected-platform build evidence and owner review recorded
in `docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md`.

