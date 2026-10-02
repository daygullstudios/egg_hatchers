# Nestarium release monitoring evidence

Updated: 2026-10-01

This records the current error-monitoring position for the release roadmap. It is
not a public-launch approval. The family privacy model is still open, so
Nestarium deliberately avoids adding client analytics, Crashlytics, Sentry or
similar app-side telemetry until the approved privacy, retention and guardian
control model says exactly what is allowed.

## Current monitored surfaces

- The protected web playtest Worker has Cloudflare Worker Observability enabled
  in `cloudflare/playtest/wrangler.jsonc`.
- The protected multiplayer Worker has Cloudflare Worker Observability enabled,
  including invocation logs, in `cloudflare/multiplayer/wrangler.jsonc`.
- The canary multiplayer Worker has the same Cloudflare Worker Observability and
  invocation-log settings in `cloudflare/multiplayer/wrangler.canary.jsonc`.
- The Flutter client has no production crash or analytics SDK dependency. The
  current dependency list intentionally excludes `firebase_crashlytics`,
  `firebase_analytics`, `sentry_flutter`, App Center and similar packages.

## Privacy boundary

Monitoring must support operations without turning into player tracking. Do not
intentionally log player profile payloads, progress payloads, chat/preset-message
contents, custom art, animal rosters, save-transfer files or child/guardian
information. Operational logs should stay focused on request outcomes, worker
errors, capability-denial classes, route failures and service health.

If a future error-monitoring provider is added to the client, it needs the same
family-audience approval as other optional data connections. That review must
cover data fields, region handling, retention, deletion, guardian controls,
support access, store disclosures and whether the SDK can be disabled before any
eligibility decision.

## Remaining release blockers

The roadmap item "Add production error monitoring that matches the approved
privacy model" remains open until these decisions are recorded:

- Final production topology and which Workers/routes are public.
- Alert destinations and the release owner responsible for responding.
- Log retention, export, deletion and support-access procedures.
- A privacy-approved list of allowed operational fields.
- A test proving public production errors are visible without exposing player
  progress or identity details.

Until then, the protected playtest has server-side visibility, and the client
continues to avoid app-side telemetry.
