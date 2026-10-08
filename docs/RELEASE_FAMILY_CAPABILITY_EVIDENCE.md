# Nestarium family capability release evidence

Updated: 2026-10-01

This records the current technical evidence only for names, discovery,
invitations, preset messages and trading under hosted account capability
levels. It does not replace the professional audience/privacy review,
approved guardian flow, parent-managed controls, final retention ownership or
candidate legal policy work that remain separate release gates.

## Capability enforcement

- `cloudflare/multiplayer/test/worker.test.ts`
  - `fails closed unless trusted capability claims use the current policy`.
  - `fails closed in registry mode and accepts only a resolved hosted capability`.
  - `enforces battle and trade permissions independently after connection`.
  - `retires a live hosted session when its capability decision is revoked`.

- `cloudflare/multiplayer/test/safety_authority.test.ts`
  - `issues, expires, and revokes bounded capability decisions`.

- `cloudflare/multiplayer/src/safety_authority.ts`
  - `profile discovery is not approved in family policy v1`.
  - `preset messages require trading permission`.
  - `deniedCapabilities` is the default for missing, stale, expired, revoked or
    denied capability decisions.
  - `capabilityDecisionForUid` resolves the current hosted capability status
    from the pseudonymous safety database.
  - `moderationReportRetentionMs` bounds report retention before pruning.

## Names, discovery and invitations

- `cloudflare/multiplayer/test/worker.test.ts`
  - `matches two verified identities without disclosing supplied names or ids`.
  - The server replaces supplied player names, ids and team power with
    generated safe account labels and server-owned state.
  - Block-list responses use generated account labels and manage tokens rather
    than raw user ids.

## Messages and trading

- `test/trading_service_test.dart`
  - `hosted trading authenticates and consumes only server inventory`.
  - Trading chat remains preset-only with `TradeChatTag.isThisFair`,
    `TradeChatTag.yes` and `TradeChatTag.requestAnimal`.

- `test/multiplayer_service_test.dart`
  - `hosted battle sends preset player safety actions`.

## Reports, blocks and retention evidence

- `cloudflare/multiplayer/test/worker.test.ts`
  - `records preset reports and persists two-way matchmaking blocks`.
  - Blocks prevent battle and trade matching until removed by the owner.
  - Reports use bounded preset reasons instead of open text.

- `cloudflare/multiplayer/test/safety_authority.test.ts`
  - `stores idempotent pseudonymous reports and prunes them after retention`.

## Remaining release gates

- Obtain professional audience/privacy review for the intended ages 8-12, teen
  and adult audience.
- Implement the approved age/guardian capability flow before optional data
  connections.
- Add parent-managed permissions, review, revocation and deletion controls.
- Finalize retention rules and provider responsibilities.
- Publish candidate-accurate Privacy Policy, Terms and support instructions.
