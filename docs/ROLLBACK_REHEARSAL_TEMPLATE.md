# Rollback Rehearsal Template

Use this template only for a real release candidate or disposable operations
rehearsal. Do not fill it with placeholder approvals.

## Rehearsal Identity

- Date:
- Operator:
- Release owner:
- Rollback decision maker:
- Candidate Git commit:
- Candidate tag/build:
- Previous protected playtest Worker version ID:
- Candidate protected playtest Worker version ID:
- Previous multiplayer Worker version ID:
- Candidate multiplayer Worker version ID:
- Public-site Worker version ID, if changed:

## Backup References

- Firebase/Firestore backup reference:
- D1 safety database backup/export reference:
- Multiplayer Durable Object migration/export reference, if relevant:
- Release build artifact backup location:
- `docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md` entry updated: yes/no

## Pre-Rehearsal Checks

- `flutter analyze` result:
- `flutter test` result:
- `flutter build web --release` result:
- `node tool/audit_release_surface.mjs` result:
- Cloudflare playtest build/test/dry-run result:
- Multiplayer Worker tests/dry-run result:
- Public-site tests/dry-run result, if changed:
- Owner confirms rehearsal uses disposable or approved data: yes/no

## Rollback Path

Record exact commands or dashboard actions used. Prefer a protected test route
or disposable canary before rehearsing against public routing.

1. Record the current deployed version IDs.
2. Deploy or route the candidate to the approved protected target.
3. Run smoke checks for startup, account/save load, manual boss route,
   multiplayer connection and support links.
4. Roll back the protected route or Worker to the previous version.
5. Repeat smoke checks and confirm the previous protected version works.
6. Confirm no backup restore was needed. If restore was needed, record the
   exact backup and recovery command/path.

## Smoke Check Results

- App loads:
- Existing protected player still loads:
- Fresh player can start:
- Save export/import still reachable:
- Manual boss screen reachable:
- Online lobby connects or fails closed as expected:
- Trading connects or fails closed as expected:
- Public support/deletion links reachable, if public site changed:
- Observability shows expected requests/errors:

## Decision

- Rollback rehearsal passed: yes/no
- Open critical/high issues:
- Accepted risks:
- Next action:

Do not mark the release roadmap rollback item complete until this record is
filled for the exact candidate commit and approved by the release owner and
rollback decision maker.

