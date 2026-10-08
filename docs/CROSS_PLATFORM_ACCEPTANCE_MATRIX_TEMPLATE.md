# Cross-Platform Acceptance Matrix Template

Use this template only for a frozen release candidate. Do not mark a platform
complete unless that platform was selected for launch and tested with the exact
candidate build.

## Candidate Identity

- Candidate Git commit:
- Version name/build number:
- Selected launch platforms:
- Selected launch countries:
- Release owner:
- Rollback decision maker:
- Protected playtest Worker version:
- Multiplayer Worker version:
- Public site version, if changed:

## Platform Rows

Copy one row for each selected platform: Web, Android and/or iOS.

```text
Platform:
Build artifact:
Device/browser/OS:
Fresh account starts with no progress:
Returning account loads expected progress:
Save Transfer export/import succeeds:
Cloud restore or approved recovery path succeeds:
Account deletion/support path verified:
Conflict review preserves both copies until confirmation:
Offline or interrupted startup fails safely:
Manual boss battle playable:
Audio unlock/pause/resume acceptable:
Online battle invitation or matchmaking verified:
Online battle reward receipt delivered once:
Online trade invite/cancel/complete verified:
Preset messages available; open text unavailable:
Blocked-player/report flow verified:
Narrow layout and selected text scale acceptable:
Result: Pass / Fail / Deferred
Evidence link or notes:
```

## Required Supporting Evidence

- `docs/RELEASE_ACCOUNT_MATRIX_EVIDENCE.md` for automated local account/save
  coverage.
- `docs/MULTIPLAYER_PRODUCTION_ACCEPTANCE.md` for trusted sessions,
  two-device play and capacity/load results.
- `docs/PLATFORM_STORE_READINESS.md` for selected platform build/signing
  blockers.
- `docs/AUDIO_RELEASE_ACCEPTANCE.md` for audio listening and platform behavior.
- `docs/PUBLIC_POLICY_READINESS.md` for support, privacy, terms and
  account-deletion link readiness.

## Failed Or Deferred Rows

Do not hide a failed or deferred platform row in notes. For each failure or
deferral, record:

- Platform and build artifact.
- Exact failed row field.
- User impact: data loss, account recovery, multiplayer/trading, audio,
  accessibility, policy/support, store readiness, or other.
- Whether the selected launch platform list must change.
- Fix commit or accepted-risk reference.
- Focused retest command and result.
- Release owner decision.
- Rollback decision maker decision if the issue affects saves, identity,
  rewards, trades, privacy, support links, or launch routing.

Any Critical or High failure keeps the release candidate blocked unless the
release owner and rollback decision maker explicitly accept the risk in
`docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md`.

## Exit Rule

The release roadmap item "Complete the cross-platform account/save/multiplayer
acceptance matrix" remains open until every selected platform row has a
release-owner-approved Pass or a written accepted risk in the release candidate
record.

