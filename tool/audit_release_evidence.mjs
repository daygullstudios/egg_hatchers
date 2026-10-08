import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const indexPath = 'docs/RELEASE_EVIDENCE_INDEX.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';

const index = readFileSync(resolve(root, indexPath), 'utf8');
const roadmap = readFileSync(resolve(root, roadmapPath), 'utf8');

const requiredGateHeadings = [
  '## 1. Scope and ownership',
  '## 2. Accounts and save recovery',
  '## 3. Family safety and privacy',
  '## 4. Multiplayer and trading',
  '## 5. Gameplay and economy',
  '## 6. Visuals, audio and accessibility',
  '## 7. Reliability and security',
  '## 8. Platform and store readiness',
  '## 9. Closed beta',
  '## 10. Release candidate and launch',
];

const requiredWarnings = [
  'does not close any unchecked roadmap item',
  'exact candidate build',
  'Open release dependencies',
];

const requiredEvidence = [
  'docs/RELEASE_DECISION_PACKET.md',
  'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md',
  'docs/RELEASE_ACCOUNT_MATRIX_EVIDENCE.md',
  'docs/RELEASE_ACCOUNT_RECOVERY_EVIDENCE.md',
  'docs/RELEASE_CLOUD_ACCOUNT_DELETION_EVIDENCE.md',
  'docs/CROSS_PLATFORM_ACCEPTANCE_MATRIX_TEMPLATE.md',
  'docs/FAMILY_AUDIENCE_V1.md',
  'docs/RELEASE_FAMILY_CAPABILITY_EVIDENCE.md',
  'docs/PUBLIC_POLICY_READINESS.md',
  'docs/MULTIPLAYER_PRODUCTION_ACCEPTANCE.md',
  'docs/RELEASE_SECURITY_REVIEW.md',
  'docs/NEW_PLAYER_PATH_BASELINE.md',
  'docs/ECONOMY_AUDIT.md',
  'docs/BOSS_BALANCE_AUDIT.md',
  'docs/VISUAL_AUDIO_ACCESSIBILITY_AUDIT.md',
  'docs/AUDIO_RELEASE_ACCEPTANCE.md',
  'docs/ASSET_RIGHTS_RELEASE_AUDIT.md',
  'docs/RELEASE_CODE_REVIEW.md',
  'docs/RELEASE_RELIABILITY_EVIDENCE.md',
  'docs/RELEASE_MONITORING_EVIDENCE.md',
  'docs/RELEASE_OPERATIONS_EVIDENCE.md',
  'docs/RELEASE_FREEZE_SURFACE_EVIDENCE.md',
  'docs/PLATFORM_STORE_READINESS.md',
  'docs/MONETIZATION_AND_AD_OPERATIONS.md',
  'docs/CLOSED_BETA_PLAN.md',
  'docs/CLOSED_BETA_FINDINGS_LOG_TEMPLATE.md',
  'docs/RELEASE_VERIFICATION_RUNBOOK.md',
  'docs/ROLLBACK_REHEARSAL_TEMPLATE.md',
  'docs/MONITORING_ALERT_RUNBOOK_TEMPLATE.md',
];

const failures = [];

for (const heading of requiredGateHeadings) {
  if (!roadmap.includes(heading.replace('## ', '### '))) {
    failures.push(`${roadmapPath}: missing roadmap gate "${heading.replace('## ', '### ')}"`);
  }
  if (!index.includes(heading)) {
    failures.push(`${indexPath}: missing evidence index gate "${heading}"`);
  }
}

for (const warning of requiredWarnings) {
  if (!index.includes(warning)) {
    failures.push(`${indexPath}: missing release boundary warning "${warning}"`);
  }
}

for (const evidencePath of requiredEvidence) {
  if (!index.includes(evidencePath)) {
    failures.push(`${indexPath}: missing evidence link "${evidencePath}"`);
  }
  if (!existsSync(resolve(root, evidencePath))) {
    failures.push(`${evidencePath}: linked release evidence file does not exist`);
  }
}

if (!index.includes('docs/RELEASE_ROADMAP.md')) {
  failures.push(`${indexPath}: missing release roadmap link`);
}

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  `Release evidence audit: ${requiredGateHeadings.length} gates and ${requiredEvidence.length} evidence links verified.`,
);
