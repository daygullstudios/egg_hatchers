# Nestarium multiplayer load and capacity rehearsal

Updated: 2026-10-08

Use this rehearsal only after the release owner chooses the launch size, public
topology, and family/privacy capability model. It does not authorize public multiplayer
or close the roadmap capacity item by itself. It records the launch-size test
that must be run against the selected candidate environment.

## Rehearsal identity

- Candidate Git commit: TBD
- Multiplayer Worker version ID: TBD
- Protected playtest Worker version ID: TBD
- Candidate topology: single compatibility / sharded canary / public generation
- Matchmaking generation: TBD
- Selected launch size: TBD
- Intended concurrent session target: TBD
- Test operator: TBD
- Release owner: TBD
- Rollback decision maker: TBD

## Existing protected evidence

Current automated and canary evidence is useful but not public launch proof:

- `docs/MULTIPLAYER_SHARD_MIGRATION.md` records the protected-v1 compatibility
  boundary and the Access-protected two-shard canary acceptance.
- The current protected playtest has a 32-session per-shard guardrail.
- A 33rd distinct protected session receives `503` plus `Retry-After`.
- Existing automated acceptance forms isolated battle matches and verifies the
  fail-closed boundary.
- The canary acceptance measured empty-shard behavior, but it does not prove public traffic,
  store traffic, launch-country latency, support readiness, or
  final family/privacy capability behavior.

## Required preconditions

Before running the rehearsal:

- Launch platforms and launch countries are chosen.
- Family/privacy capability model is approved.
- Candidate Worker versions are recorded.
- Capacity target and expected launch concurrency are approved.
- Monitoring and rollback owners are available.
- `docs/MULTIPLAYER_TWO_DEVICE_PLAYTEST_SCRIPT.md` passes or has accepted risks.
- `docs/MONITORING_ALERT_RUNBOOK_TEMPLATE.md` has alert thresholds.
- No real child data, private support documents, credentials, or account secrets
  are used in the test.

## Load plan

Record:

- Number of accounts/sessions to open:
- Session ramp-up rate:
- Target duration:
- Battle invite ratio:
- Random matchmaking ratio:
- Trade invite/cancel/complete ratio:
- Reconnect/refresh ratio:
- Report/block spot-check count:
- Expected guardrail behavior:
- Cost/latency budget:

The test must include:

- Fresh ordinary accounts.
- At least one direct battle path.
- At least one random matchmaking path.
- At least one battle reconnect path.
- At least one direct trade path.
- At least one trade cancel/disconnect path.
- At least one completed trade.
- Preset-message traffic only.
- Block/report spot checks using bounded preset reasons.

## Measurements

Record:

- Sessions attempted:
- Sessions accepted:
- Sessions rejected:
- Match count:
- Battle settlement count:
- Duplicate settlement count:
- Trade started count:
- Trade completed count:
- Trade canceled count:
- One-sided trade count:
- Receipt redelivery count:
- `503` count:
- `Retry-After` count:
- WebSocket close/error count:
- p50/p95/max connection latency:
- p50/p95/max match time:
- p50/p95/max trade completion time:
- Worker error count:
- D1/safety database error count:
- Estimated cost:

## Pass criteria

The rehearsal can pass only if:

- Accepted sessions meet or intentionally stop at the selected launch-size
  guardrail.
- Guardrail responses are recoverable and include expected `503` and
  `Retry-After` behavior.
- Battle rewards are delivered once.
- No duplicate reward is minted.
- No one-sided trade occurs.
- Completed trades move both roster items exactly once.
- Canceled and disconnected trades preserve both rosters.
- Reconnects stay limited to the verified same Firebase identity.
- Preset messages remain preset-only.
- Reports and blocks stay bounded and pseudonymous.
- Monitoring shows enough signal for rollback decisions without exposing player
  progress, rosters, Save Transfer files, child/guardian information, or tokens.

## Stop conditions

Stop and keep the roadmap load gate open if any occur:

- The environment accepts more sessions than the approved guardrail.
- Capacity errors lack `Retry-After`.
- A client can mint rewards without an acknowledged server receipt.
- A duplicate battle settlement pays twice.
- A trade completes on only one side.
- A disconnect moves either roster.
- A duplicate UID keeps two active playable sessions.
- Denied, expired, revoked, or stale capabilities can match, battle, trade, or
  send preset messages.
- Logs expose profile payloads, progress payloads, tokens, Save Transfer files,
  rosters, preset-message contents, or child/guardian information.
- Latency or error rates exceed the approved launch threshold.

## Evidence to attach

Attach or cite:

- Completed copy of this rehearsal.
- `docs/MULTIPLAYER_PRODUCTION_ACCEPTANCE.md`.
- `docs/MULTIPLAYER_TWO_DEVICE_PLAYTEST_SCRIPT.md`.
- `docs/MULTIPLAYER_SHARD_MIGRATION.md`.
- `docs/RELEASE_MONITORING_EVIDENCE.md`.
- `docs/MONITORING_ALERT_RUNBOOK_TEMPLATE.md`.
- Worker version IDs.
- Test account cleanup result.
- Cost/latency summary.
- Any focused retest notes after fixes.
