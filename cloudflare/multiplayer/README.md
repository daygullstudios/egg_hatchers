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
- `protected_playtest` permits authenticated battle matchmaking because Access
  limits the hostname to approved testers. It is not parental consent.
- Client player IDs and names are ignored. Peers receive a server-derived test
  alias. Profile discovery, messages, trading, rewards and result settlement
  are default-denied until their later authority/safety packages ship.
- Match records are durable SQLite rows. Open sockets use Durable Object
  WebSocket hibernation and serialized attachments.
- The Flutter client knows how to attach its restored Firebase ID token, but its
  hosted release switch remains off until battle execution and settlement are
  implemented. Local development WebSockets remain available without Firebase.

The one named playtest pool is intentionally a small protected vertical slice,
not the production sharding plan.

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
