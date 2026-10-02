# Nestarium authentication, multiplayer and trading security review

Updated: 2026-10-01

This is the release-roadmap security review for the current authentication,
multiplayer and trading implementation. It does not approve public launch by
itself. The separate production-session, privacy, family-capability,
two-device-internet and load-test gates remain open.

## Result

No new critical or high-severity security issue was found in this pass.

## Authentication boundary reviewed

- `cloudflare/multiplayer/src/auth.ts`
  - Hosted WebSocket sessions require the `nestarium-v1` protocol plus a
    Firebase ID token carried as `firebase-auth.<token>`.
  - Tokens are limited in size, must use RS256, and are verified against the
    configured Firebase project audience and issuer.
  - Subject, issued-at and authentication-time claims are validated.
  - `trusted_registry` fails closed unless the server-side capability resolver
    returns a current allow decision.
  - `trusted_claims` accepts only the current versioned allow policy.

- `cloudflare/multiplayer/src/index.ts`
  - Public requests have any client-supplied `X-Nestarium-Uid` and
    `X-Nestarium-Capabilities` headers removed before the Worker adds trusted
    values.
  - The Durable Object rejects sessions with missing or disabled hosted
    capabilities.
  - Duplicate sessions for the same UID retire the previous session.
  - Maintenance modes refuse new queue/search actions while preserving explicit
    operator migration paths.

- `lib/services/multiplayer_service.dart` and
  `lib/services/trading_service.dart`
  - Hosted clients stay fail-closed until their build flags are enabled.
  - Hosted clients require a restored cloud identity token before opening the
    socket.

## Multiplayer authority reviewed

- Server-owned Online Roster inventory is the only authority for hosted battle
  teams. Client-supplied player names, IDs, ratings and powers are not used as
  public identity or combat authority.
- Matchmaking uses server-derived safe aliases for peers.
- Server-run battle settlement creates UID-scoped receipts and redelivers them
  until acknowledgement without minting duplicate rewards.
- Reconnects are limited to the verified same Firebase identity.
- The protected playtest pool has a tested session guardrail and retry response.

## Trading authority reviewed

- Hosted trading requires the trading capability, and preset trade messages
  require the preset-message capability.
- Only animals still present in the server-owned Online Roster with quantity
  greater than one can be offered or requested.
- Trade completion is transactional: both inventory moves, both account revision
  increments, active-trade completion and both receipts are written together.
- Trade receipts are acknowledged only for the authenticated UID.
- A disconnect or block before confirmation cancels the trade without moving
  either roster.
- Player communication remains preset-only; no open text payload is accepted.

## Safety and abuse controls reviewed

- Peer reports derive the reported player from the authenticated battle/trade
  context rather than accepting a client-supplied account ID.
- Reports use approved reason tags, same-day duplicate suppression and a daily
  report limit.
- Central moderation records use pseudonymous hashes and scheduled retention
  pruning.
- Blocks apply to future battle and trade matchmaking in both directions.
- WebSocket messages are size-limited and rate-limited per session window.

## Open release gates

These are still outside this completed security-review item:

- Complete trusted authenticated sessions in the production environment.
- Run two-device internet play outside the developer network.
- Run load and capacity tests for the intended launch size.
- Obtain the professional family audience/privacy review and approved capability
  flow.
- Confirm backups, restore procedures, rate limits and operational alerts with
  a named release owner.
