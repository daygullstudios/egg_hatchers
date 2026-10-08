# Backup restore drill

Use this drill only with disposable test data or release-owner-approved rehearsal
data. It does not authorize touching live player saves, support documents,
identity tokens, custom art, animal rosters or child/guardian information.

## Purpose

The drill proves that the backups named in a release candidate record are
complete enough to restore service after a failed deploy, failed migration,
corrupt save path or infrastructure outage. It also verifies that every restore
step has an owner, a retest command and a rollback decision path.

## Required Backup References

Record these references before starting:

- Firebase/Firestore backup reference for the selected test project.
- D1 safety database backup/export reference.
- Multiplayer Durable Object migration/export reference, if a multiplayer
  generation migration is part of the candidate.
- Release build artifact backup location.
- Previous protected playtest Worker version ID.
- Previous multiplayer Worker version ID.
- Candidate protected playtest Worker version ID.
- Candidate multiplayer Worker version ID.

## Restore Checks

1. Local progress restore
   - Use a disposable save with a known account name, coin value and roster.
   - Trigger the existing recovery path from a damaged primary save and a valid
     backup.
   - Confirm the app opens recovery UI instead of overwriting damaged progress.

2. Save Transfer restore
   - Import a versioned Save Transfer file using disposable data.
   - Confirm the import is staged for review before replacing the active save.
   - Confirm legacy custom-egg records remain readable but unplayable.

3. Cloud account restore
   - Use a disposable linked account in the selected test project.
   - Confirm a clean device or clean browser can recover the same player only
     after explicit restore.
   - Confirm local progress is not overwritten by uncertain or conflicting
     cloud state.

4. Safety database restore
   - Export and restore D1 safety data with disposable report/block records.
   - Confirm report retention pruning still works after restore.
   - Confirm blocks and reports do not expose private chat or support content.

5. Multiplayer migration restore
   - If a Durable Object migration is included, rehearse the documented
     drain/freeze/export/import/canary/rollback path.
   - Confirm a failed migration can return to the previous generation without
     minting rewards, duplicating trades or orphaning sessions.

6. Release artifact restore
   - Restore the recorded release build artifact to a disposable host or local
     verification directory.
   - Run the smoke checks from `docs/ROLLBACK_REHEARSAL_TEMPLATE.md`.

## Pass Criteria

- Every required backup reference is recorded in the candidate record or
  rollback rehearsal record.
- Each restore check uses disposable or explicitly approved rehearsal data.
- Restored saves, safety data, multiplayer state and release artifacts pass
  their smoke checks.
- Any failed restore names an owner, a fix ticket and a retest command.
- The release owner and rollback decision maker know which backup should be
  used for rollback.

## Stop Conditions

Stop the release rehearsal and keep the operations roadmap item open if:

- A backup cannot be found, read or tied to the candidate build.
- A restore path requires live player data without explicit approval.
- Restored data loses progress, duplicates rewards, changes rosters, reveals
  private support data or exposes child/guardian information.
- The rollback decision maker cannot identify the correct backup or previous
  Worker version.
- A restore failure has no owner and retest command.

