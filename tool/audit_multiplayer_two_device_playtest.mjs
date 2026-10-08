import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const scriptPath = 'docs/MULTIPLAYER_TWO_DEVICE_PLAYTEST_SCRIPT.md';
const acceptancePath = 'docs/MULTIPLAYER_PRODUCTION_ACCEPTANCE.md';
const securityPath = 'docs/RELEASE_SECURITY_REVIEW.md';
const matrixPath = 'docs/CROSS_PLATFORM_ACCEPTANCE_MATRIX_TEMPLATE.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const evidenceIndexPath = 'docs/RELEASE_EVIDENCE_INDEX.md';
const runbookPath = 'docs/RELEASE_VERIFICATION_RUNBOOK.md';
const workflowPath = '.github/workflows/verify.yml';
const releaseEvidenceAuditPath = 'tool/audit_release_evidence.mjs';

const script = readFileSync(resolve(root, scriptPath), 'utf8');
const acceptance = readFileSync(resolve(root, acceptancePath), 'utf8');
const security = readFileSync(resolve(root, securityPath), 'utf8');
const matrix = readFileSync(resolve(root, matrixPath), 'utf8');
const roadmap = readFileSync(resolve(root, roadmapPath), 'utf8');
const evidenceIndex = readFileSync(resolve(root, evidenceIndexPath), 'utf8');
const runbook = readFileSync(resolve(root, runbookPath), 'utf8');
const workflow = readFileSync(resolve(root, workflowPath), 'utf8');
const releaseEvidenceAudit = readFileSync(resolve(root, releaseEvidenceAuditPath), 'utf8');

const failures = [];

function requirePhrase(path, text, phrase) {
  if (!text.includes(phrase)) {
    failures.push(`${path}: missing phrase "${phrase}"`);
  }
}

for (const heading of [
  '## Session identity',
  '## Setup checks',
  '## Battle invitation path',
  '## Matchmaking path',
  '## Trading path',
  '## Block and report path',
  '## Capacity spot check',
  '## Stop conditions',
  '## Evidence to attach',
]) {
  requirePhrase(scriptPath, script, heading);
}

for (const phrase of [
  'does not authorize public multiplayer',
  'outside the developer network',
  'Candidate Git commit',
  'Multiplayer Worker version ID',
  'Protected playtest Worker version ID',
  'ordinary fresh account',
  'nestarium-v1',
  'firebase-auth.<token>',
  'capability decisions fail',
  'preset-only',
  'Do not use developer boosts',
]) {
  requirePhrase(scriptPath, script, phrase);
}

for (const phrase of [
  'direct battle invitation',
  'receives the invitation',
  'reconnect window',
  'Battle reward receipt is delivered once',
  'reward is not duplicated',
  'random matchmaking',
  'times out gracefully',
  'stuck in queue',
]) {
  requirePhrase(scriptPath, script, phrase);
}

for (const phrase of [
  'direct trade invitation',
  'server-owned Online Roster',
  'Is this fair?',
  'both rosters are unchanged',
  'both roster moves happened exactly once',
  'disconnect one device',
  'cancels without moving either roster',
]) {
  requirePhrase(scriptPath, script, phrase);
}

for (const phrase of [
  'blocks Device B',
  'future battle and trade matching is blocked',
  'bounded preset reasons',
  'open text',
  'protected 32-session guardrail',
  '503',
  'Retry-After',
]) {
  requirePhrase(scriptPath, script, phrase);
}

for (const phrase of [
  'client mints rewards without a server receipt',
  'battle reward is delivered more than once',
  'trade moves only one side',
  'duplicate session can play as the same UID',
  'denied or revoked capability',
  'Open text chat is possible',
  'Blocking does not prevent future matching',
  'Report flow accepts free text',
  'loses progress',
]) {
  requirePhrase(scriptPath, script, phrase);
}

for (const phrase of [
  'Direct battle invitation succeeds',
  'Battle reconnect window works',
  'Battle reward receipt is delivered once',
  'Direct trade invitation succeeds',
  'Trade cancel/disconnect preserves both rosters',
  'Completed trade moves both roster items exactly once',
  'Preset trade messages work; open text is unavailable',
  'Block/report flow is available after the interaction',
]) {
  requirePhrase(acceptancePath, acceptance, phrase);
}

for (const phrase of [
  'two-device-internet',
  'load-test gates remain open',
  'Server-run battle settlement creates UID-scoped receipts',
  'Trade completion is transactional',
  'Player communication remains preset-only',
]) {
  requirePhrase(securityPath, security, phrase);
}

for (const phrase of [
  'Online battle invitation or matchmaking verified',
  'Online battle reward receipt delivered once',
  'Online trade invite/cancel/complete verified',
  'Preset messages available; open text unavailable',
  'Blocked-player/report flow verified',
]) {
  requirePhrase(matrixPath, matrix, phrase);
}

for (const item of [
  '[ ] Complete trusted authenticated sessions in the production environment.',
  '[ ] Run two-device internet play outside the developer network.',
  '[ ] Run load and capacity tests for the intended launch size.',
]) {
  requirePhrase(roadmapPath, roadmap, item);
}

for (const phrase of [
  scriptPath,
  'node tool/audit_multiplayer_two_device_playtest.mjs',
]) {
  requirePhrase(evidenceIndexPath, evidenceIndex, phrase);
  requirePhrase(runbookPath, runbook, phrase);
}

for (const phrase of [
  'node tool/audit_multiplayer_two_device_playtest.mjs',
  'Verify multiplayer two-device playtest script',
]) {
  requirePhrase(workflowPath, workflow, phrase);
}

requirePhrase(releaseEvidenceAuditPath, releaseEvidenceAudit, scriptPath);

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  'Multiplayer two-device playtest audit: battle, matchmaking, trading, block/report and stop-condition script verified.',
);
