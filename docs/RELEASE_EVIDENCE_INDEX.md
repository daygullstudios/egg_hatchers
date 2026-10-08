# Nestarium release evidence index

Use this index while walking `docs/RELEASE_ROADMAP.md`. It points each release
gate at the current evidence record, template or decision packet. This index
does not close any unchecked roadmap item by itself; final clearance still
requires a frozen candidate and the owner approvals named in the roadmap.

## 1. Scope and ownership

- Scope boundary: `docs/RELEASE_ROADMAP.md`
- Owner decisions still needed: `docs/RELEASE_DECISION_PACKET.md`
- Release candidate identity: `docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md`

Open release dependencies: launch platforms, launch countries, release owner
and rollback decision maker.

## 2. Accounts and save recovery

- Account-switch and local/cloud save matrix:
  `docs/RELEASE_ACCOUNT_MATRIX_EVIDENCE.md`
- Clean-device account recovery:
  `docs/RELEASE_ACCOUNT_RECOVERY_EVIDENCE.md`
- Complete cloud-account deletion:
  `docs/RELEASE_CLOUD_ACCOUNT_DELETION_EVIDENCE.md`
- Candidate acceptance matrix:
  `docs/CROSS_PLATFORM_ACCEPTANCE_MATRIX_TEMPLATE.md`

Open release dependencies: selected platforms and real candidate device/browser
coverage.

## 3. Family safety and privacy

- Current audience position: `docs/FAMILY_AUDIENCE_V1.md`
- Family capability evidence: `docs/RELEASE_FAMILY_CAPABILITY_EVIDENCE.md`
- Public policy readiness: `docs/PUBLIC_POLICY_READINESS.md`
- Release decisions still needed: `docs/RELEASE_DECISION_PACKET.md`

Open release dependencies: professional review, approved guardian flow, parent
controls, retention rules and candidate-accurate policy/support pages.

## 4. Multiplayer and trading

- Multiplayer production checklist:
  `docs/MULTIPLAYER_PRODUCTION_ACCEPTANCE.md`
- Security review: `docs/RELEASE_SECURITY_REVIEW.md`
- Monitoring evidence: `docs/RELEASE_MONITORING_EVIDENCE.md`
- Operations evidence: `docs/RELEASE_OPERATIONS_EVIDENCE.md`

Open release dependencies: trusted production sessions, two-device internet play
outside the developer network and load/capacity testing for the selected launch
size.

## 5. Gameplay and economy

- New-player path: `docs/NEW_PLAYER_PATH_BASELINE.md`
- Economy audit: `docs/ECONOMY_AUDIT.md`
- Boss balance: `docs/BOSS_BALANCE_AUDIT.md`
- DayGull/endgame economy: `docs/DAYGULL_ENDGAME_ECONOMY_AUDIT.md`
- Reward systems: `docs/REWARD_SYSTEMS_ECONOMY_AUDIT.md`
- Save-stage playability: `docs/SAVE_STAGE_PLAYABILITY_EVIDENCE.md`

Open release dependencies: candidate playtest confirmation that no practical
progression blocker or farming exploit remains.

## 6. Visuals, audio and accessibility

- Visual/audio/accessibility audit:
  `docs/VISUAL_AUDIO_ACCESSIBILITY_AUDIT.md`
- Audio acceptance checklist: `docs/AUDIO_RELEASE_ACCEPTANCE.md`
- Asset rights audit: `docs/ASSET_RIGHTS_RELEASE_AUDIT.md`
- Platform branding readiness: `docs/PLATFORM_BRANDING_READINESS.md`

Open release dependencies: music rights, volume normalization and platform audio
behavior checks. Final logo approval and regenerated platform branding are
recorded in `docs/PLATFORM_BRANDING_READINESS.md`.

## 7. Reliability and security

- Release code review: `docs/RELEASE_CODE_REVIEW.md`
- Reliability evidence: `docs/RELEASE_RELIABILITY_EVIDENCE.md`
- Security review: `docs/RELEASE_SECURITY_REVIEW.md`
- Monitoring evidence: `docs/RELEASE_MONITORING_EVIDENCE.md`
- Operations evidence: `docs/RELEASE_OPERATIONS_EVIDENCE.md`
- Operations dry-run checklist: `docs/OPERATIONS_DRY_RUN_CHECKLIST.md`
- Release-surface evidence: `docs/RELEASE_FREEZE_SURFACE_EVIDENCE.md`

Open release dependencies: approved production monitoring, alert destinations,
backup cadence and restore ownership.

## 8. Platform and store readiness

- Platform store readiness: `docs/PLATFORM_STORE_READINESS.md`
- Store listing draft checklist: `docs/STORE_LISTING_DRAFT_CHECKLIST.md`
- Platform branding readiness: `docs/PLATFORM_BRANDING_READINESS.md`
- Public policy readiness: `docs/PUBLIC_POLICY_READINESS.md`
- Monetization boundary: `docs/MONETIZATION_AND_AD_OPERATIONS.md`

Open release dependencies: selected platforms, Android/iOS signing where chosen,
store metadata, ratings, privacy answers and store support/deletion links.

## 9. Closed beta

- Closed beta plan: `docs/CLOSED_BETA_PLAN.md`
- Tester packet: `docs/CLOSED_BETA_TESTER_PACKET.md`
- Findings log template: `docs/CLOSED_BETA_FINDINGS_LOG_TEMPLATE.md`
- Release candidate record: `docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md`

Open release dependencies: approved beta entry, trusted testers, ordinary fresh
accounts, tracked findings and one complete candidate pass after blocker fixes.

## 10. Release candidate and launch

- Release verification runbook: `docs/RELEASE_VERIFICATION_RUNBOOK.md`
- Release candidate record: `docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md`
- Cross-platform acceptance matrix:
  `docs/CROSS_PLATFORM_ACCEPTANCE_MATRIX_TEMPLATE.md`
- Rollback rehearsal: `docs/ROLLBACK_REHEARSAL_TEMPLATE.md`
- Monitoring alert runbook: `docs/MONITORING_ALERT_RUNBOOK_TEMPLATE.md`
- Operations dry-run checklist: `docs/OPERATIONS_DRY_RUN_CHECKLIST.md`

Open release dependencies: frozen candidate, exact commit/build evidence,
rollback test, explicit owner approval, gradual release and live monitoring.

## Use During Release

1. Start with `docs/RELEASE_DECISION_PACKET.md`.
2. Freeze a candidate only after the owner-dependent answers are recorded.
3. Fill a dated copy of `docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md`.
4. Attach or cite every evidence file above from that candidate record.
5. Keep unchecked roadmap items open unless the evidence is from the exact candidate build being approved.
