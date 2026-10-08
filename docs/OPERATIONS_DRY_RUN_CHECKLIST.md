# Operations Dry-Run Checklist

Updated: 2026-10-08

Use this checklist before closed beta and again for every frozen release
candidate. It is a rehearsal aid only; it does not approve production launch or
close the release roadmap items for monitoring, backups, restore procedures,
rate limits, alerts or rollback.

## Preconditions

- Fill the owner-dependent fields in `docs/RELEASE_DECISION_PACKET.md`.
- Open `docs/MONITORING_ALERT_RUNBOOK_TEMPLATE.md` and record temporary dry-run
  contacts for monitoring owner, backup responder, release owner, rollback
  decision maker, alert destinations, support inbox and incident log location.
- Open `docs/ROLLBACK_REHEARSAL_TEMPLATE.md` and identify disposable test
  references for Firebase/Firestore, D1 safety data, Durable Object migration
  artifacts and release build artifacts.
- Open `docs/BACKUP_RESTORE_DRILL.md` and select the smallest disposable data
  set that proves each backup can be found, read and smoke-tested.
- Confirm this dry run uses test data only. Do not touch live player saves,
  identity tokens, support documents, custom art or child/guardian information.

## Local Candidate Verification

Run from the repository root and attach the output summary to the candidate
record:

```powershell
flutter analyze
node tool/audit_monitoring_operations.mjs
node tool/audit_rollback_rehearsal.mjs
node tool/audit_release_candidate_record.mjs
node tool/audit_release_surface.mjs
flutter test
flutter build web --release --no-pub
```

## Surface Dry Runs

Run these commands with the selected release candidate, stopping on the first
failure:

```powershell
cd cloudflare/public-site
npm test
npm run deploy:dry-run
```

```powershell
cd cloudflare/playtest
npm test
npm run build:web
npm run deploy:dry-run
```

```powershell
cd cloudflare/multiplayer
npm install
npm run typecheck
npm test
npm run deploy:dry-run
```

## Restore And Rollback Rehearsal

- Record the previous protected playtest Worker version ID and candidate
  protected playtest Worker version ID.
- Record the previous multiplayer Worker version ID and candidate multiplayer
  Worker version ID.
- Confirm where the release build artifact backup is stored.
- Confirm the Firebase/Firestore backup reference for the test project.
- Confirm the D1 safety database backup/export reference for the test project.
- Confirm the Durable Object migration/export reference, if a migration is part
  of the candidate.
- Complete the backup restore drill in `docs/BACKUP_RESTORE_DRILL.md` using
  disposable or release-owner-approved rehearsal data.
- Walk through the rollback path in `docs/ROLLBACK_REHEARSAL_TEMPLATE.md`
  without routing public traffic.
- Run the smoke checks listed in the rollback template: app loads, existing
  protected player loads, fresh player starts, Save Transfer is reachable,
  manual boss screen is reachable, online lobby fails closed or connects as
  expected, and trading fails closed or connects as expected.

## Alert Rehearsal

Use privacy-safe synthetic events only:

- Worker error spike.
- Multiplayer capacity saturation or repeated `503` guardrail responses.
- D1 safety database error.
- Failed deploy or dry-run.
- Support/account-deletion link failure.
- Save/account recovery support spike.

For each synthetic event, record whether the owner saw it, where it appeared,
how long it took to notice, and which rollback or support decision it would
trigger.

## Pass Criteria

- Every command above passes or has an owned fix ticket.
- The dry-run candidate record lists exact commit, build artifact backup,
  Worker version IDs, backup references, alert destinations and rollback result.
- Backup restore drill results are recorded for local progress, Save Transfer,
  cloud account recovery, D1 safety data, multiplayer migration artifacts and
  release build artifacts.
- No dry-run step requires logging player profile payloads, progress payloads,
  preset-message contents, custom art, animal rosters, Save Transfer files,
  identity tokens, support documents or child/guardian information.
- Any failed check names an owner and a retest command.

Do not mark the release roadmap operations or rollback items complete from this
checklist alone. They remain open until the named owners approve the production
procedures and a real candidate rehearsal is recorded.
