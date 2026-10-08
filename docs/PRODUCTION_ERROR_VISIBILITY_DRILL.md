# Production error visibility drill

Use this drill only after the release owner approves the production monitoring
and privacy model. It does not authorize client telemetry, public routing or
store submission by itself.

## Purpose

The drill proves that production errors are visible quickly enough for release
support while the logs stay inside the approved operational data boundary. It
also confirms that a failure can be connected to a deploy version and rollback
decision without exposing player progress, identity, custom art, roster data or
child/guardian information.

## Preconditions

- Release owner, rollback decision maker, monitoring owner and backup responder
  are named in the candidate record.
- Alert destinations are configured and can receive a test notification.
- Log retention, export, deletion and support-access rules are approved.
- Allowed operational fields are recorded in
  `docs/MONITORING_ALERT_RUNBOOK_TEMPLATE.md` or the candidate copy of it.
- Public policy, support and account-deletion links are candidate-accurate.
- Worker Observability is enabled on every selected production Worker.
- Client analytics, Crashlytics, Sentry or similar telemetry remains absent
  unless the approved family/privacy review explicitly allows it.

## Test Scenarios

Run the smallest safe version of each scenario against the selected candidate
environment. Do not use real player support files or private Save Transfer
files.

1. Web route failure visibility
   - Trigger a controlled missing-route or invalid-route request.
   - Confirm the status class, route or Worker name, timestamp and deployed
     version are visible.
   - Confirm the log does not contain player profile payloads, progress
     payloads, account tokens, custom art, animal rosters or child/guardian
     information.

2. Multiplayer capability-denial visibility
   - Send a request that should be denied by the hosted capability rules.
   - Confirm the capability denial class and request outcome are visible.
   - Confirm preset-message contents and roster payloads are not logged.

3. Trading or battle safety failure visibility
   - Use a controlled stale-client, duplicate-receipt or invalid-trade request.
   - Confirm the denial is visible without minting rewards or changing either
     roster.
   - Confirm the log links to a deploy version or Worker version.

4. Support and account-deletion link failure visibility
   - Check the public support, privacy, terms and account-deletion routes from
     the selected store entry or candidate web origin.
   - Confirm a broken route produces an alert or a visible error record.
   - Confirm no support inbox contents or private documents are copied into
     operational logs.

5. Alert delivery and rollback handoff
   - Send a test alert to every selected destination.
   - Confirm the monitoring owner and backup responder receive it.
   - Confirm the release owner and rollback decision maker know where to find
     the candidate record, incident log and rollback rehearsal record.

## Pass Criteria

- Every selected production Worker exposes privacy-safe error visibility.
- Alert destinations receive a test notification.
- The candidate deploy version is visible for each controlled failure.
- No player progress, identity details, Save Transfer files, custom art, animal
  rosters, preset-message contents or child/guardian information appear in logs.
- The incident log records the scenario, timestamp, owner, result and any fix.
- The release candidate record cites this drill result.

## Stop Conditions

Stop release work and keep the monitoring roadmap item open if any of these
occur:

- Logs expose player profile payloads, progress payloads, identity tokens,
  private support documents, custom art, animal rosters, preset-message
  contents or child/guardian information.
- Alert destinations fail or are not owned by a named responder.
- A controlled battle or trade failure changes rewards, rosters or save state.
- A production error cannot be tied to the candidate deploy version.
- The release owner, rollback decision maker or monitoring owner is unnamed.

