# Nestarium release code review evidence

Updated: 2026-10-01

This records the current release-focused code review for crashes, data loss and
security-sensitive bugs. It is not approval to launch, and it does not replace
the later production security review, account recovery acceptance, privacy
review or two-device internet playtest gates.

## Scope reviewed

- Local save integrity, damaged-progress recovery and Save Transfer staging.
- Cloud progress sync, conflict review, checkpoint ancestry and account
  protection identity transitions.
- Hosted multiplayer client behavior for authentication, reconnects, settlement
  receipts and safety actions.
- Hosted trading client behavior for authenticated sessions, preset messages,
  cancellation and settlement receipts.
- Cloudflare multiplayer worker authentication, capability enforcement,
  trusted-header handling, migration access, roster authority, atomic trades,
  server-run battles, report limits and block handling.

## Result

No new critical release blocker was found in this pass for the reviewed code
paths. The candidate still has open release gates that are intentionally kept
separate from this review:

- Complete an approved cross-device account-recovery method.
- Complete trusted authenticated sessions in the production environment.
- Obtain the audience/privacy review and approved family capability flow.
- Add production error monitoring, backup/restore procedures and operational
  alerts.
- Perform the final authentication, multiplayer and trading security review.
- Run the two-device internet playtest outside the developer network.

## Save and sync integrity

- `test/save_transfer_service_test.dart`
  - Import review and staging never replace existing players or the active
    session.
  - A second staging attempt cannot replace the reviewed pending file.
  - Supported settings are restored without importing foreign identity or cloud
    ancestry.
  - Legacy files with dormant custom eggs remain importable while custom eggs
    stay unplayable.

- `test/progress_sync_service_test.dart`
  - Local save failures preserve unresolved cloud choices instead of uploading
    or replacing progress.
  - Unreadable local progress cannot trigger cloud upload or replacement.
  - Import pause drains late cloud reads without upload or restore.
  - Changed cloud state blocks both reviewed device and cloud replacement.
  - Unknown cloud state never authorizes an upload.
  - Player switches during explicit choices are isolated from stale work.
  - Confirmed empty cloud upload records checkpoint ancestry.

- `test/progress_recovery_test.dart`
  - Storage outages surface `storageUnavailable`.
  - Runtime corruption blocks autosave and cloud replacement.
  - Interrupted backup restore can resume or cancel without losing originals.
  - Stale previews and changed copies fail closed.

- `test/unsaved_progress_test.dart`
  - Failed live saves freeze mutation, cloud acknowledgement, import and player
    switching until retry.
  - Queued writes serialize backup rotation and revision increments.

- `test/checkpoint_persistence_test.dart`
  - Sync checkpoints are versioned and scoped by account.

## Account protection

- `test/account_protection_service_test.dart`
  - Unconfigured builds report device-only progress.
  - Identity restore failure cannot claim progress is protected.
  - Named local profiles never invoke the identity gateway.
  - Opening an existing Google account clears old sync ancestry.
  - Google protection is single-flight while the provider is open.
  - Replacement guests receive fresh identity after local removal.

- `test/cross_device_recovery_test.dart`
  - Cross-device recovery remains covered as a staged acceptance path, but the
    release gate remains open until the approved recovery method works on a
    clean second device or browser.

## Multiplayer and trading

- `test/multiplayer_service_test.dart`
  - Released hosted multiplayer rejects a missing identity token.
  - Hosted settlement is parsed and acknowledged explicitly.
  - Hosted matches preserve identity and resume after a dropped socket.
  - The match server rejects teams containing unknown animals.

- `test/trading_service_test.dart`
  - Released hosted trading rejects a missing identity token.
  - Two online players complete a confirmed animal trade.
  - Trading uses preset messages and animal request payloads rather than open
    chat.

- `cloudflare/multiplayer/test/worker.test.ts`
  - Missing Firebase tokens, tokens from another project and stale capability
    claims fail closed.
  - Battle and trade capabilities are enforced independently.
  - The server owns the online roster and rejects forged battle teams.
  - Online Roster trades commit exactly once.
  - Disconnected trades cancel without moving either roster.
  - Duplicate identity sessions are retired before accepting replacements.
  - Live hosted sessions retire when capability decisions are revoked.
  - Settlement receipts are redelivered until acknowledged without minting
    duplicate rewards.

- `cloudflare/multiplayer/test/safety_authority.test.ts`
  - Capability decisions issue, expire and revoke through the safety authority.

- `cloudflare/multiplayer/test/migration.test.ts`
  - Migration tools remain off the public HTTP surface and use the private
    binding path.

## Worker auth and trust boundary

- `cloudflare/multiplayer/src/auth.ts`
  - Non-local WebSocket sessions require the `firebase-auth.` protocol token.
  - Oversized tokens and missing/stale capability decisions fail closed.

- `cloudflare/multiplayer/src/index.ts`
  - The public worker verifies Firebase sessions before Durable Object routing.
  - Client-supplied `X-Nestarium-Uid` and `X-Nestarium-Capabilities` headers are
    deleted, then replaced with trusted values after verification.
  - Public migration requests are separate from the private binding protocol.
  - Moderation reports are bounded, deduplicated by day and pruned by retention
    maintenance.

## Verification checkpoint

On 2026-10-01, this review evidence was added after `flutter analyze` and the
full Flutter test suite were already clean for the previous release evidence
checkpoint. This file is now pinned to live regression coverage by
`test/release_code_review_evidence_test.dart`.
