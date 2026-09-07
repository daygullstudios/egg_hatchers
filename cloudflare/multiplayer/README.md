# Nestarium protected multiplayer Worker

This is a separate Cloudflare Worker from `cloudflare/playtest`. The static app
remains the origin for the protected playtest hostname; the more-specific
`/ws*` route reaches this service and remains behind the hostname's existing
Cloudflare Access application.

## Current capability boundary

- Every WebSocket session must present a signed Firebase ID token using the
  `nestarium-v1` and `firebase-auth.<token>` WebSocket subprotocols.
- The edge verifies the token's RS256 signature, Firebase project audience,
  issuer, expiry, issued-at time, authentication time and UID.
- `protected_playtest` permits authenticated battle matchmaking and the bounded
  preset-message trade flow because Access limits the hostname to approved
  testers. It is not parental consent and does not define public capabilities.
- Client player IDs and names are ignored. Peers receive a server-derived test
  alias. Profile discovery and free-text communication remain unavailable.
- The Online Roster is separate from the offline-first Hatchery Collection. It
  starts with two copies each of Chicken, Mouse and Rabbit, is stored in Durable
  Object SQLite, and is the only inventory accepted for hosted teams or trades.
  A client-
  writable Firestore save is never treated as trusted inventory.
- Each account's first completed hosted match per UTC day grants one level-1,
  normal Online Roster animal to both participants. The eligible pool expands
  at 1250 and 1600 online rating. A unique daily grant row and the existing
  settlement transaction prevent repeat farming or duplicate delivery.
- Hosted battles use roster-validated fighters and server-owned ratings/results.
  Hosted trades exchange both roster items in one SQLite transaction, preserve
  pending receipts until acknowledgement, and cancel without moving either item
  if a player leaves or disconnects before the commit.
- Match, settlement, roster, trade and receipt records are durable SQLite rows.
  Open sockets use Durable Object WebSocket hibernation and serialized
  attachments. Local development WebSockets keep the existing sandbox behavior.

The one named playtest pool is intentionally a small protected vertical slice,
not a production capacity or sharding promise. Changing its name would create a
different roster namespace and therefore requires an explicit migration plan.

## Verify

```powershell
npm install
npm run types
npm run typecheck
npm test
npm run deploy:dry-run
```

Do not add a service-account key or a Firebase private key. Production signing
keys are fetched from Google's published certificate endpoint and cached using
its response lifetime. The RSA key in the test is a disposable local fixture.

Do not route `playnestarium.com` as part of this project. Public-hostname and
release gates remain in `docs/NESTARIUM_MIGRATION.md`.
