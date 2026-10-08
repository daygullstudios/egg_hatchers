import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const checklistPath = 'docs/GRADUAL_RELEASE_MONITORING_CHECKLIST.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const candidatePath = 'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md';
const monitoringRunbookPath = 'docs/MONITORING_ALERT_RUNBOOK_TEMPLATE.md';
const rollbackPath = 'docs/ROLLBACK_REHEARSAL_TEMPLATE.md';
const freezePath = 'docs/RELEASE_FEATURE_FREEZE_CHECKLIST.md';
const evidenceIndexPath = 'docs/RELEASE_EVIDENCE_INDEX.md';
const runbookPath = 'docs/RELEASE_VERIFICATION_RUNBOOK.md';
const workflowPath = '.github/workflows/verify.yml';
const releaseEvidenceAuditPath = 'tool/audit_release_evidence.mjs';

const checklist = readFileSync(resolve(root, checklistPath), 'utf8');
const roadmap = readFileSync(resolve(root, roadmapPath), 'utf8');
const candidate = readFileSync(resolve(root, candidatePath), 'utf8');
const monitoringRunbook = readFileSync(resolve(root, monitoringRunbookPath), 'utf8');
const rollback = readFileSync(resolve(root, rollbackPath), 'utf8');
const freeze = readFileSync(resolve(root, freezePath), 'utf8');
const evidenceIndex = readFileSync(resolve(root, evidenceIndexPath), 'utf8');
const runbook = readFileSync(resolve(root, runbookPath), 'utf8');
const workflow = readFileSync(resolve(root, workflowPath), 'utf8');
const releaseEvidenceAudit = readFileSync(
  resolve(root, releaseEvidenceAuditPath),
  'utf8',
);

const failures = [];

function requirePhrase(path, text, phrase) {
  if (!text.includes(phrase)) {
    failures.push(`${path}: missing phrase "${phrase}"`);
  }
}

for (const path of [
  checklistPath,
  roadmapPath,
  candidatePath,
  monitoringRunbookPath,
  rollbackPath,
  freezePath,
]) {
  if (!existsSync(resolve(root, path))) {
    failures.push(`${path}: required gradual-release file does not exist`);
  }
}

for (const heading of [
  '## Rollout identity',
  '## Before rollout',
  '## First-hour checks',
  '## First-day checks',
  '## Pause or rollback triggers',
  '## Rollback evidence',
  '## Exit evidence',
]) {
  requirePhrase(checklistPath, checklist, heading);
}

for (const phrase of [
  'does not authorize launch by itself',
  'Release owner',
  'Rollback decision maker',
  'Monitoring owner',
  'Support inbox owner',
  'Public route or store track',
  'Previous protected version ID',
  'Candidate version ID',
]) {
  requirePhrase(checklistPath, checklist, phrase);
}

for (const phrase of [
  'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md',
  'docs/RELEASE_FEATURE_FREEZE_CHECKLIST.md',
  'docs/ROLLBACK_REHEARSAL_TEMPLATE.md',
  'docs/MONITORING_ALERT_RUNBOOK_TEMPLATE.md',
  'docs/CROSS_PLATFORM_ACCEPTANCE_MATRIX_TEMPLATE.md',
  'Support and account-deletion links are reachable',
  'critical or high-priority closed beta finding',
]) {
  requirePhrase(checklistPath, checklist, phrase);
}

for (const phrase of [
  'App loads from the public route or selected store track',
  'Fresh player creation succeeds',
  'Returning player save load succeeds',
  'Save Transfer export remains reachable',
  'Manual boss screen is reachable',
  'Online lobby connects or fails closed as expected',
  'Direct battle invitation succeeds or fails closed as expected',
  'Trade invitation succeeds or fails closed as expected',
  'Preset messages remain preset-only',
  'Worker error rate stays below approved thresholds',
  'multiplayer capacity guardrails',
  'Support/account-deletion links remain reachable',
]) {
  requirePhrase(checklistPath, checklist, phrase);
}

for (const phrase of [
  'Startup crash loop',
  'Widespread save-load failure',
  'Confirmed player data loss',
  'Account takeover',
  'Duplicated trades',
  'Public exposure of player private data',
  'Child/privacy report',
  'Support/account-deletion link outage',
  'Worker error spike',
  'multiplayer capacity saturation',
  'Store policy warning',
]) {
  requirePhrase(checklistPath, checklist, phrase);
}

for (const phrase of [
  'First-hour checks',
  'First-day checks',
  'Save/account checks',
  'Multiplayer/trading checks',
  'Support inbox checks',
  'Rollback trigger thresholds',
]) {
  requirePhrase(candidatePath, candidate, phrase);
}

for (const phrase of [
  'Rollback trigger thresholds',
  'Monitoring owner',
  'Alert destinations',
]) {
  requirePhrase(monitoringRunbookPath, monitoringRunbook, phrase);
}

for (const phrase of [
  'Rollback rehearsal passed',
  'Smoke Check Results',
]) {
  requirePhrase(rollbackPath, rollback, phrase);
}

for (const phrase of [
  'Rollback rehearsal result for the exact candidate',
  'Release owner',
]) {
  requirePhrase(freezePath, freeze, phrase);
}

for (const phrase of [
  '[ ] Release gradually and monitor saves, identity, crashes and multiplayer.',
  '[ ] Obtain explicit owner approval for public routing and store submission.',
]) {
  requirePhrase(roadmapPath, roadmap, phrase);
}

for (const phrase of [
  checklistPath,
  'node tool/audit_gradual_release_monitoring.mjs',
]) {
  requirePhrase(evidenceIndexPath, evidenceIndex, phrase);
  requirePhrase(runbookPath, runbook, phrase);
}

for (const phrase of [
  'node tool/audit_gradual_release_monitoring.mjs',
  'Verify gradual release monitoring checklist',
]) {
  requirePhrase(workflowPath, workflow, phrase);
}

requirePhrase(releaseEvidenceAuditPath, releaseEvidenceAudit, checklistPath);

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  'Gradual release monitoring audit: rollout checks, rollback triggers and exit evidence verified.',
);
