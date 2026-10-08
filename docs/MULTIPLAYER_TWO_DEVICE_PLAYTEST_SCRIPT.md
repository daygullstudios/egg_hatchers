# Nestarium two-device multiplayer playtest script

Updated: 2026-10-08

Use this script only after the release owner chooses the launch size, the
family/privacy capability model is approved, and the candidate multiplayer
environment is deployed. It does not authorize public multiplayer or close the
roadmap item by itself. It records the exact two-device internet play sequence
that must be run outside the developer network.

## Session identity

- Candidate Git commit: TBD
- Multiplayer Worker version ID: TBD
- Protected playtest Worker version ID: TBD
- Capability mode: TBD
- Matchmaking generation: TBD
- Device A platform/browser/network: TBD
- Device B platform/browser/network: TBD
- Tester A account: ordinary fresh account
- Tester B account: ordinary fresh account
- Operator: TBD
- Release owner: TBD

## Setup checks

Before the test:

- Confirm both devices are outside the developer network.
- Confirm both testers use ordinary fresh accounts unless the release owner
  assigned a recovery/import scenario.
- Confirm both testers can load the same protected candidate route.
- Confirm hosted clients use `nestarium-v1` and `firebase-auth.<token>`.
- Confirm missing, expired, denied, revoked, or stale capability decisions fail
  closed.
- Confirm player communication remains preset-only.
- Do not use developer boosts, edited saves, real child data, private support
  documents, or screenshots containing account secrets.

## Battle invitation path

1. Device A opens Online Arena and sees Device B online.
2. Device A sends a direct battle invitation.
3. Device B receives the invitation.
4. Device B accepts.
5. Both devices enter the same battle.
6. Device A refreshes or briefly disconnects during a low-risk moment.
7. Device A reconnects within the reconnect window.
8. The battle finishes once.
9. Battle reward receipt is delivered once.
10. Refresh both devices and confirm the reward is not duplicated.

Record:

- Invitation latency:
- Reconnect behavior:
- Reward receipt ID or evidence:
- Any mismatch between the two devices:

## Matchmaking path

1. Both devices enter random matchmaking.
2. Matchmaking succeeds or times out gracefully.
3. If matched, finish one battle.
4. If not matched, record timeout behavior and UI clarity.

Record:

- Time to match or timeout:
- Error/fallback copy:
- Whether either account became stuck in queue:

## Trading path

1. Device A sends a direct trade invitation.
2. Device B accepts.
3. Device A offers an animal that remains in the server-owned Online Roster.
4. Device B requests or offers an animal.
5. Send preset trade messages, including `Is this fair?`, and confirm open text
   is unavailable.
6. Cancel one trade and confirm both rosters are unchanged.
7. Start a second trade and complete it.
8. Refresh both devices and confirm both roster moves happened exactly once.
9. disconnect one device during a low-risk trade moment and confirm the trade
   cancels without moving either roster.

Record:

- Trade receipt IDs or evidence:
- Roster before/after:
- Cancel/disconnect result:
- Preset messages shown:

## Block and report path

1. After a battle or trade, Device A blocks Device B.
2. Confirm future battle and trade matching is blocked.
3. Remove the block.
4. Send one preset report reason from a test interaction.
5. Confirm the report flow uses bounded preset reasons and does not allow open
   text.

Record:

- Block result:
- Unblock result:
- Report reason:
- Any unexpected player-identifying data shown:

## Capacity spot check

This script does not replace the full capacity/load test, but the two-device
run should still record whether the environment is near the protected 32-session guardrail:

- Current active session estimate:
- Any `503` response:
- Any `Retry-After` response:
- Any queue or invite degradation:

## Stop conditions

Stop the playtest and keep the roadmap gate open if any of these occur:

- A client mints rewards without a server receipt.
- A battle reward is delivered more than once.
- A trade moves only one side of the roster.
- A canceled or disconnected trade moves either roster.
- A duplicate session can play as the same UID at the same time.
- A denied or revoked capability can battle, trade, or send preset messages.
- Open text chat is possible.
- Blocking does not prevent future matching.
- Report flow accepts free text or raw player IDs.
- Either tester loses progress, animals, account access, or Save Transfer
  recovery.

## Evidence to attach

Attach or cite:

- Completed copy of this script.
- `docs/MULTIPLAYER_PRODUCTION_ACCEPTANCE.md`.
- `docs/RELEASE_SECURITY_REVIEW.md`.
- `docs/CROSS_PLATFORM_ACCEPTANCE_MATRIX_TEMPLATE.md`.
- Multiplayer Worker version ID.
- Protected playtest Worker version ID.
- Battle and trade receipt evidence.
- Screenshots or short recordings with private account details hidden.
- Focused retest notes for any fix.
