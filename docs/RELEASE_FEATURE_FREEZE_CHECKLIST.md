# Nestarium release feature-freeze checklist

Updated: 2026-10-08

Use this checklist only when preparing a named release candidate. It does not mark the roadmap item
"Freeze features and remove or hide development-only
controls" complete by itself. The item closes only after this checklist is
filled for the exact candidate commit and the release owner records approval in
`docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md`.

## Freeze identity

- Candidate name: TBD
- Candidate Git commit: TBD
- Candidate tag/build: TBD
- Release owner: TBD
- Rollback decision maker: TBD
- Freeze start time: TBD
- Freeze exceptions owner: TBD

## Feature boundary

Before feature freeze, confirm:

- Version 1.0 scope matches `docs/RELEASE_ROADMAP.md`.
- Halloween, Christmas, Easter, Corruption and 3D Corruption future events
  remain excluded from the candidate.
- Custom eggs remain retired and legacy Save Transfer records stay readable.
- Bot Arena remains available until multiplayer is complete and the owner
  approves removal.
- Player communication remains preset-only.
- Monetization remains dormant unless its separate operations plan is complete.
- No new animal ships without Classic, Retro Pixel and Realistic art variants.
- The Rotten Shell and DayGull discovery flow remains preserved.

## Development-only surface

Before public routing or store submission, confirm:

- Developer Tools are hidden outside debug builds.
- `node tool/audit_release_surface.mjs` passes against the exact release web
  bundle.
- The release bundle does not expose known developer labels such as
  `Developer Tools (Debug)`, `Force Next Single Hatch`,
  `Unlock Rotten Shell reqs`, `Preview DayGull Unlock`, or
  `Collect All Animals`.
- No temporary playtest host, preview alias or worker dev route is treated as a
  public release surface.
- Save Transfer import/export remains visible because it is a player recovery
  feature, not a developer tool.

## Allowed changes during freeze

After freeze starts, only these changes are allowed without reopening the
candidate:

- Critical or high-priority bug fixes.
- Security, privacy, data-loss or crash-loop fixes.
- Store-policy, support-link or public-policy corrections required for release.
- Build, deployment, monitoring, rollback or backup corrections required to make
  the exact candidate reversible.
- Text changes that clarify already-approved release behavior without changing
  gameplay, economy, account state, multiplayer settlement or privacy behavior.

Every allowed freeze change must record:

- Git commit.
- Reason for the change.
- Risk level.
- Focused retest result.
- Whether the full release matrix must be repeated.
- Release owner approval.

## Changes that reopen the candidate

Reopen the candidate and restart release verification if any change:

- Adds an animal, egg, boss, event, mutation, reward system or economy curve.
- Changes account creation, cloud save ownership, Save Transfer compatibility or
  deletion behavior.
- Changes multiplayer settlement, trading settlement, invitations or preset
  messaging semantics.
- Changes the family/privacy capability model or public data collection.
- Changes production routing, authentication, backup ownership or monitoring
  destinations.
- Replaces music, logo, platform branding or any shipped asset that still needs
  rights approval.
- Changes Android/iOS signing, package identity or store-disclosed behavior.

## Exit evidence

Attach or cite:

- Dated copy of this completed checklist.
- `docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md` record for the same commit.
- `docs/RELEASE_FREEZE_SURFACE_EVIDENCE.md`.
- `docs/RELEASE_VERIFICATION_RUNBOOK.md` command results.
- CI run URL and artifact reference.
- Release-surface audit result.
- Closed beta findings status, if beta has started.
- Rollback rehearsal result for the exact candidate.

Do not release if any critical or high-priority freeze finding remains open
unless the release owner and rollback decision maker explicitly accept the risk.
