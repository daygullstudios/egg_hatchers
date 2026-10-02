# Nestarium operations evidence

Updated: 2026-10-01

This records the current release evidence for backups, restore procedures, rate
limits and operational alerts. It is not approval to launch. The roadmap item
remains open until a named owner approves the production backup schedule, alert
destinations, retention windows and restore rehearsal.

## Local save backup and restore

- `test/unsaved_progress_test.dart`
  - Failed live saves freeze risky actions until retry.
  - Slow writes keep the latest coalesced progress.
  - Backup rotation and revision increments serialize instead of racing.

- `test/progress_recovery_test.dart`
  - Storage outages surface `storageUnavailable`.
  - Interrupted backup restore can resume or cancel without losing originals.
  - Runtime corruption blocks autosave and cloud replacement.

- `test/progress_recovery_ui_test.dart`
  - Damaged progress opens recovery UI instead of saving over damage.
  - Backup review fits narrow and enlarged-text layouts.

- `test/save_transfer_service_test.dart`
  - Versioned Save Transfer imports are staged for review.
  - Legacy files with dormant custom eggs remain readable while custom eggs stay
    unplayable.

## Cloud and multiplayer recovery evidence

- `docs/RELEASE_ACCOUNT_RECOVERY_EVIDENCE.md` records cross-device recovery
  evidence for Google-linked accounts, conflict review and explicit restore.
- `docs/RELEASE_CLOUD_ACCOUNT_DELETION_EVIDENCE.md` records the current cloud
  deletion evidence and its remaining production/privacy limits.
- `cloudflare/multiplayer/README.md` documents the Durable Object migration
  status, drain/freeze/activate procedure, encrypted manifest artifacts,
  export/import commands and canary topology.
- `docs/MULTIPLAYER_SHARD_MIGRATION.md` records the required drain, manifest,
  export/import, canary and rollback sequence before a multiplayer generation
  migration.

## Rate limits and abuse guardrails

- The protected playtest multiplayer pool has a 32-session guardrail documented
  in `cloudflare/multiplayer/README.md`, with a 33rd distinct session receiving a
  recoverable 503 and `Retry-After`.
- `cloudflare/multiplayer/test/worker.test.ts` covers duplicate identity session
  retirement, replay-safe settlement receipts, trade receipt acknowledgement and
  the protected-playtest capacity guardrail.
- Reports are preset-reason only, deduplicated per reporter/reported/reason/day
  and limited to ten unique reports per reporter per day.
- `cloudflare/multiplayer/test/safety_authority.test.ts` covers pseudonymous
  central report storage and retention pruning.

## Operational alerts

Current visibility is server-side only: `docs/RELEASE_MONITORING_EVIDENCE.md`
records Cloudflare Worker Observability and the decision to avoid client
telemetry until the family privacy model approves it.

The release still needs:

- A named release owner and rollback decision maker.
- Alert destinations for Worker errors, failed scheduled maintenance,
  multiplayer capacity saturation, D1 errors and failed deploys.
- A documented backup cadence for Firebase/Firestore, D1 safety data,
  multiplayer Durable Object migration artifacts and release build artifacts.
- A restore rehearsal using disposable test data, including the expected
  rollback path if a migration or deployment fails.
- Retention and support-access rules that match the final privacy policy.

Do not mark the roadmap operations item complete until those human-owned
production procedures are confirmed.
