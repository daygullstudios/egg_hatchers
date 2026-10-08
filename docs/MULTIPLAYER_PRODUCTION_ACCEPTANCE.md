# Multiplayer Production Acceptance

Use this checklist only after the release owner chooses the launch size and the
family/privacy capability model is approved. It does not authorize public
multiplayer by itself.

## Environment Identity

- Candidate Git commit:
- Multiplayer Worker version ID:
- Protected playtest Worker version ID:
- Capability mode:
- Matchmaking generation:
- Selected launch size:
- Operator:
- Release owner:

## Trusted Session Checks

- Hosted WebSocket requires `nestarium-v1` plus `firebase-auth.<token>`.
- Missing, expired, denied, revoked or stale trusted-registry decisions fail
  closed.
- Client-supplied identity headers are stripped before trusted values are added.
- Duplicate sessions for the same UID retire the older session.
- Hosted clients fail closed when the build flag or identity token is missing.
- Battle, trading and preset-message capabilities are enforced separately.

## Two-Device Internet Play

Run outside the developer network with two ordinary tester accounts:

- Device A network:
- Device B network:
- Both players can start from fresh ordinary accounts:
- Direct battle invitation succeeds:
- Random matchmaking succeeds or times out gracefully:
- Battle reconnect window works after one refresh/disconnect:
- Battle reward receipt is delivered once:
- Direct trade invitation succeeds:
- Trade cancel/disconnect preserves both rosters:
- Completed trade moves both roster items exactly once:
- Preset trade messages work; open text is unavailable:
- Block/report flow is available after the interaction:

## Capacity and Load

The protected playtest currently has a 32-session guardrail, tested in
`cloudflare/multiplayer/test/worker.test.ts`. Public capacity must be measured
against the selected launch size and sharding plan before launch.

Record:

- Intended concurrent session target:
- Test topology:
- Number of sessions opened:
- Number of matches formed:
- Capacity/latency result:
- Expected 503/Retry-After behavior at guardrail:
- Errors observed:
- Cost/latency notes:
- Decision: pass/fail/defer:

## Required Evidence

- `cloudflare/multiplayer/README.md` current capability boundary reviewed.
- `docs/RELEASE_SECURITY_REVIEW.md` open gates still reflected.
- `docs/MULTIPLAYER_SHARD_MIGRATION.md` reviewed if capacity requires sharding.
- `cloudflare/multiplayer/test/worker.test.ts` passed.
- `cloudflare/multiplayer/test/safety_authority.test.ts` passed.
- `cloudflare/multiplayer/test/migration.test.ts` passed if migration or
  sharding is involved.

Do not mark the roadmap multiplayer production gates complete until this
checklist is filled with measured results from the selected launch environment.

