import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const matrixPath = 'docs/CROSS_PLATFORM_ACCEPTANCE_MATRIX_TEMPLATE.md';
const candidatePath = 'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const runbookPath = 'docs/RELEASE_VERIFICATION_RUNBOOK.md';
const evidenceIndexPath = 'docs/RELEASE_EVIDENCE_INDEX.md';

const matrix = readFileSync(resolve(root, matrixPath), 'utf8');
const candidate = readFileSync(resolve(root, candidatePath), 'utf8');
const roadmap = readFileSync(resolve(root, roadmapPath), 'utf8');
const runbook = readFileSync(resolve(root, runbookPath), 'utf8');
const evidenceIndex = readFileSync(resolve(root, evidenceIndexPath), 'utf8');

const failures = [];

function requirePhrase(path, text, phrase) {
  if (!text.includes(phrase)) {
    failures.push(`${path}: missing phrase "${phrase}"`);
  }
}

for (const field of [
  'Candidate Git commit',
  'Version name/build number',
  'Selected launch platforms',
  'Selected launch countries',
  'Release owner',
  'Rollback decision maker',
  'Protected playtest Worker version',
  'Multiplayer Worker version',
  'Public site version, if changed',
]) {
  requirePhrase(matrixPath, matrix, field);
}

for (const field of [
  'Platform:',
  'Build artifact:',
  'Device/browser/OS:',
  'Fresh account starts with no progress:',
  'Returning account loads expected progress:',
  'Save Transfer export/import succeeds:',
  'Cloud restore or approved recovery path succeeds:',
  'Account deletion/support path verified:',
  'Conflict review preserves both copies until confirmation:',
  'Offline or interrupted startup fails safely:',
  'Manual boss battle playable:',
  'Audio unlock/pause/resume acceptable:',
  'Online battle invitation or matchmaking verified:',
  'Online battle reward receipt delivered once:',
  'Online trade invite/cancel/complete verified:',
  'Preset messages available; open text unavailable:',
  'Blocked-player/report flow verified:',
  'Narrow layout and selected text scale acceptable:',
  'Result: Pass / Fail / Deferred',
  'Evidence link or notes:',
]) {
  requirePhrase(matrixPath, matrix, field);
}

for (const evidencePath of [
  'docs/RELEASE_ACCOUNT_MATRIX_EVIDENCE.md',
  'docs/MULTIPLAYER_PRODUCTION_ACCEPTANCE.md',
  'docs/PLATFORM_STORE_READINESS.md',
  'docs/AUDIO_RELEASE_ACCEPTANCE.md',
  'docs/PUBLIC_POLICY_READINESS.md',
]) {
  requirePhrase(matrixPath, matrix, evidencePath);
  requirePhrase(evidenceIndexPath, evidenceIndex, evidencePath);
  if (!existsSync(resolve(root, evidencePath))) {
    failures.push(`${evidencePath}: linked supporting evidence file does not exist`);
  }
}

for (const phrase of [
  'Copy one row for each selected platform: Web, Android and/or iOS.',
  'tested with the exact',
  'Failed Or Deferred Rows',
  'Exact failed row field',
  'Whether the selected launch platform list must change',
  'Focused retest command and result',
  'Release owner decision',
  'Rollback decision maker decision',
  'Any Critical or High failure keeps the release candidate blocked',
  'release-owner-approved Pass',
  'written accepted risk in the release candidate',
]) {
  requirePhrase(matrixPath, matrix, phrase);
}

for (const field of [
  'Account/save/multiplayer acceptance matrix',
  'Failed/deferred platform rows and accepted-risk references',
  'Selected launch platforms',
  'Selected launch countries',
  'Release owner',
  'Rollback decision maker',
  'Critical risks',
  'Release owner approval',
]) {
  requirePhrase(candidatePath, candidate, field);
}

for (const item of [
  '[ ] Complete the cross-platform account/save/multiplayer acceptance matrix.',
  '[ ] Run two-device internet play outside the developer network.',
  '[ ] Run load and capacity tests for the intended launch size.',
  '[ ] Verify audio unlock, pause/resume and background/foreground behavior on',
]) {
  requirePhrase(roadmapPath, roadmap, item);
}

for (const phrase of [
  'Cross-platform account/save/multiplayer matrix result',
  'docs/CROSS_PLATFORM_ACCEPTANCE_MATRIX_TEMPLATE.md',
]) {
  requirePhrase(runbookPath, runbook, phrase);
}

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  'Cross-platform acceptance audit: candidate identity, platform rows and supporting evidence verified.',
);
