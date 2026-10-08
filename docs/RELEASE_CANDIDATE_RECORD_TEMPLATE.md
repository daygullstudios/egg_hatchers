# Nestarium release candidate record template

Use this template only when a real release candidate is frozen. Do not fill it
with placeholder approvals, and do not treat this file as launch approval. Copy
this template into a dated release-candidate record or replace the `TBD` fields
only after the matching evidence exists.

## Candidate identity

- Candidate name: TBD
- Candidate date: TBD
- Release owner: TBD
- Rollback decision maker: TBD
- Git commit: TBD
- Git tag, if any: TBD
- Version name/build number: TBD
- Selected launch platforms: TBD
- Selected launch countries: TBD

## Build artifacts

- Web build command: TBD
- Web build artifact location or checksum: TBD
- Android App Bundle path/checksum, if Android is selected: TBD
- iOS archive/build identifier, if iOS is selected: TBD
- Public information site version, if updated: TBD
- Protected playtest Worker version ID: TBD
- Multiplayer Worker version ID: TBD
- Canary Worker version ID, if used: TBD

## Verification summary

- `flutter analyze`: TBD
- `flutter test`: TBD
- `flutter build web --release`: TBD
- Android signed build inspection, if selected: TBD
- iOS real-device run, if selected: TBD
- Cloudflare playtest build/test/dry-run/deploy: TBD
- Multiplayer Worker tests/dry-run/deploy: TBD
- Public-site tests/dry-run/deploy, if updated: TBD
- Brand audit: TBD
- Asset rights audit: TBD
- Accessibility/layout/audio acceptance: TBD
- Two-device internet play: TBD
- Load/capacity test: TBD
- Account/save/multiplayer acceptance matrix: TBD

## Data, backups and rollback

- Firebase/Firestore backup reference: TBD
- D1 safety database backup/export reference: TBD
- Multiplayer Durable Object migration/export reference, if relevant: TBD
- Release build artifact backup location: TBD
- Previous protected version ID: TBD
- Rollback test result: TBD
- Restore rehearsal result: TBD
- Known data-retention constraints: TBD

## Privacy, family and support

- Professional family/privacy review reference: TBD
- Approved age/guardian capability flow reference: TBD
- Candidate Privacy Policy URL/version: TBD
- Candidate Terms URL/version: TBD
- Support/account-deletion URL: TBD
- Support/deletion selected-store verification: Verify the support/account-deletion links from every selected store. TBD
- Candidate support instructions URL/version: TBD
- Store Data Safety/Privacy answers source reference: TBD
- Monitoring/alert owner and destinations: TBD
- Production error visibility drill result: TBD

## Open risks

List every accepted release risk. Critical and high risks should be empty unless
the release owner and rollback decision maker explicitly accept them.

- Critical risks: TBD
- High risks: TBD
- Medium risks: TBD
- Low risks: TBD

## Approval

- Release owner approval: TBD
- Rollback decision maker approval: TBD
- Public routing approval: TBD
- Store submission approval, if selected: TBD

## Post-release monitoring

- First-hour checks: TBD
- First-day checks: TBD
- Save/account checks: TBD
- Multiplayer/trading checks: TBD
- Support inbox checks: TBD
- Rollback trigger thresholds: TBD
