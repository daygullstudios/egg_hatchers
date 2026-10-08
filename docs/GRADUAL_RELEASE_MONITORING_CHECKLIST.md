# Nestarium gradual release monitoring checklist

Updated: 2026-10-08

Use this checklist only after the release candidate is frozen, rollback has been
rehearsed, monitoring ownership is approved, and public routing or store rollout
has explicit owner approval. It does not authorize launch by itself.

## Rollout identity

- Release candidate record: TBD
- Git commit: TBD
- Release owner: TBD
- Rollback decision maker: TBD
- Monitoring owner: TBD
- Support inbox owner: TBD
- Public route or store track: TBD
- Rollout start time: TBD
- Previous protected version ID: TBD
- Candidate version ID: TBD

## Before rollout

Confirm all of these before exposing the candidate to players:

- `docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md` is filled for the exact commit.
- `docs/RELEASE_FEATURE_FREEZE_CHECKLIST.md` is complete for the exact commit.
- `docs/ROLLBACK_REHEARSAL_TEMPLATE.md` passed for the exact candidate.
- `docs/MONITORING_ALERT_RUNBOOK_TEMPLATE.md` has approved alert thresholds.
- `docs/CROSS_PLATFORM_ACCEPTANCE_MATRIX_TEMPLATE.md` passed for selected
  platforms.
- Support and account-deletion links are reachable.
- The release owner and rollback decision maker are available during rollout.
- No critical or high-priority closed beta finding remains open unless
  explicitly accepted in the release candidate record.

## First-hour checks

Check every 10 to 15 minutes during the first hour:

- App loads from the public route or selected store track.
- Fresh player creation succeeds.
- Returning player save load succeeds.
- Save Transfer export remains reachable.
- Manual boss screen is reachable.
- Online lobby connects or fails closed as expected.
- Direct battle invitation succeeds or fails closed as expected.
- Trade invitation succeeds or fails closed as expected.
- Preset messages remain preset-only.
- Worker error rate stays below approved thresholds.
- multiplayer capacity guardrails are not repeatedly returning `503`.
- Support/account-deletion links remain reachable.
- No player reports data loss, account takeover, duplicated trades, minted
  rewards, private-data exposure, or crash loop on startup.

## First-day checks

Check at least three times during the first day:

- Save/account support volume.
- Multiplayer/trading support volume.
- Public policy/support page reachability.
- Worker errors and D1 safety database errors.
- Scheduled retention or maintenance job status, if scheduled jobs are enabled.
- Store review, rating, or policy messages, if stores are selected.
- Any reports involving child/privacy behavior.

## Pause or rollback triggers

Pause rollout and contact the rollback decision maker if any trigger appears:

- Startup crash loop.
- Widespread save-load failure.
- Confirmed player data loss.
- Account takeover, identity mix-up, or unauthorized profile access.
- Duplicated trades, one-sided trades, or minted multiplayer rewards.
- Public exposure of player private data.
- Child/privacy report that suggests the approved capability model is not being
  enforced.
- Support/account-deletion link outage.
- Sustained Worker error spike above approved thresholds.
- Repeated multiplayer capacity saturation outside the approved launch size.
- Store policy warning that requires an immediate build, listing, or routing
  change.

## Rollback evidence

If rollback happens, record:

- Decision time.
- Trigger.
- Decision maker.
- Previous version restored.
- Commands or dashboard actions used.
- Smoke checks after rollback.
- Player/support impact.
- Follow-up fix owner.
- Whether the candidate is reopened.

## Exit evidence

Do not mark the release roadmap gradual-release item complete until:

- First-hour checks are recorded.
- First-day checks are recorded.
- Support inbox review is recorded.
- Save/account and multiplayer/trading checks are recorded.
- Any pause or rollback decision is recorded.
- The release candidate record cites this checklist and final monitoring result.
