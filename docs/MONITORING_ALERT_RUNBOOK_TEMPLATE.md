# Monitoring Alert Runbook Template

Use this template after the production monitoring/privacy model is approved. It
does not authorize adding client telemetry or public launch.

## Ownership

- Monitoring owner:
- Backup responder:
- Release owner:
- Rollback decision maker:
- Alert destinations:
- Support inbox:
- Incident log location:

## Approved Data Boundary

Allowed operational fields:

- Route or Worker name:
- Request outcome/status class:
- Error class:
- Capability denial class:
- Deployment version ID:
- Timestamp rounded as approved:
- Region/colo only if approved:

Do not intentionally log player profile payloads, progress payloads,
preset-message contents, custom art, animal rosters, Save Transfer files,
identity tokens, child/guardian information, or raw support documents.

## Alert Triggers

Fill thresholds only after the owner approves launch size and privacy-safe
monitoring.

- Protected/public web Worker error spike:
- Multiplayer Worker error spike:
- Multiplayer capacity saturation or repeated `503` guardrail responses:
- D1 safety database errors:
- Scheduled maintenance or retention-prune failure:
- Failed deploy or dry-run:
- Support/account-deletion link failure:
- Save/account recovery support spike:
- Rollback trigger thresholds:

## Response Steps

1. Identify the affected route, Worker version and first failure time.
2. Confirm whether the issue affects saves, identity, multiplayer, trading,
   account deletion/support, or only static pages.
3. Check the latest release candidate record and rollback rehearsal record.
4. If critical player data, identity, trade, reward or child/privacy risk is
   suspected, pause rollout and contact the rollback decision maker.
5. Use the privacy-approved logs only; do not ask testers or players for
   private data unless the support process explicitly requires it.
6. Record the incident, decision, fix commit and focused retest result.
7. If rollback is chosen, follow `docs/ROLLBACK_REHEARSAL_TEMPLATE.md`.

## Evidence Before Closing The Roadmap Item

- Worker Observability is enabled on selected production Workers.
- Alert destinations are tested.
- Retention and support-access rules are approved.
- A privacy-safe error visibility test has been run.
- The release candidate record cites this runbook and the monitoring owner.
- Rollback trigger thresholds are recorded in the release candidate record.

