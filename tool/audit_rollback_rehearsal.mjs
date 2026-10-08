import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const rollbackPath = 'docs/ROLLBACK_REHEARSAL_TEMPLATE.md';
const candidatePath = 'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const operationsPath = 'docs/RELEASE_OPERATIONS_EVIDENCE.md';
const alertRunbookPath = 'docs/MONITORING_ALERT_RUNBOOK_TEMPLATE.md';
const evidenceIndexPath = 'docs/RELEASE_EVIDENCE_INDEX.md';
const playtestPackagePath = 'cloudflare/playtest/package.json';
const multiplayerPackagePath = 'cloudflare/multiplayer/package.json';

const rollback = readFileSync(resolve(root, rollbackPath), 'utf8');
const candidate = readFileSync(resolve(root, candidatePath), 'utf8');
const roadmap = readFileSync(resolve(root, roadmapPath), 'utf8');
const operations = readFileSync(resolve(root, operationsPath), 'utf8');
const alertRunbook = readFileSync(resolve(root, alertRunbookPath), 'utf8');
const evidenceIndex = readFileSync(resolve(root, evidenceIndexPath), 'utf8');
const playtestPackage = readFileSync(resolve(root, playtestPackagePath), 'utf8');
const multiplayerPackage = readFileSync(resolve(root, multiplayerPackagePath), 'utf8');

const failures = [];

function requirePhrase(path, text, phrase) {
  if (!text.includes(phrase)) {
    failures.push(`${path}: missing phrase "${phrase}"`);
  }
}

for (const field of [
  'Release owner',
  'Rollback decision maker',
  'Candidate Git commit',
  'Previous protected playtest Worker version ID',
  'Candidate protected playtest Worker version ID',
  'Previous multiplayer Worker version ID',
  'Candidate multiplayer Worker version ID',
  'Public-site Worker version ID',
]) {
  requirePhrase(rollbackPath, rollback, field);
}

for (const field of [
  'Firebase/Firestore backup reference',
  'D1 safety database backup/export reference',
  'Multiplayer Durable Object migration/export reference',
  'Release build artifact backup location',
  'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md',
]) {
  requirePhrase(rollbackPath, rollback, field);
}

for (const command of [
  'flutter analyze',
  'flutter test',
  'flutter build web --release',
  'node tool/audit_release_surface.mjs',
  'Cloudflare playtest build/test/dry-run',
  'Multiplayer Worker tests/dry-run',
  'Public-site tests/dry-run',
]) {
  requirePhrase(rollbackPath, rollback, command);
}

for (const step of [
  'Record the current deployed version IDs.',
  'Deploy or route the candidate to the approved protected target.',
  'Run smoke checks for startup, account/save load, manual boss route',
  'Roll back the protected route or Worker to the previous version.',
  'Repeat smoke checks and confirm the previous protected version works.',
  'Confirm no backup restore was needed.',
]) {
  requirePhrase(rollbackPath, rollback, step);
}

for (const smokeCheck of [
  'App loads',
  'Existing protected player still loads',
  'Fresh player can start',
  'Save export/import still reachable',
  'Manual boss screen reachable',
  'Online lobby connects or fails closed as expected',
  'Trading connects or fails closed as expected',
  'Public support/deletion links reachable',
  'Observability shows expected requests/errors',
]) {
  requirePhrase(rollbackPath, rollback, smokeCheck);
}

for (const phrase of [
  'Previous protected version ID',
  'Rollback test result',
  'Restore rehearsal result',
  'Rollback trigger thresholds',
]) {
  requirePhrase(candidatePath, candidate, phrase);
}

for (const phrase of [
  '[ ] Test rollback to the previous protected version.',
  '[ ] Record the exact commit, build numbers, infrastructure versions and backup.',
]) {
  requirePhrase(roadmapPath, roadmap, phrase);
}

for (const phrase of [
  'restore rehearsal',
  'rollback path if a migration or deployment fails',
]) {
  requirePhrase(operationsPath, operations, phrase);
}

for (const phrase of [
  'docs/ROLLBACK_REHEARSAL_TEMPLATE.md',
  'rollback decision maker',
]) {
  requirePhrase(alertRunbookPath, alertRunbook, phrase);
}

for (const phrase of [
  'docs/ROLLBACK_REHEARSAL_TEMPLATE.md',
  'rollback test',
]) {
  requirePhrase(evidenceIndexPath, evidenceIndex, phrase);
}

for (const phrase of ['build:web', 'deploy:dry-run']) {
  requirePhrase(playtestPackagePath, playtestPackage, phrase);
}

for (const phrase of ['test', 'deploy:dry-run']) {
  requirePhrase(multiplayerPackagePath, multiplayerPackage, phrase);
}

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  'Rollback rehearsal audit: version identity, backups, smoke checks and open rollback gate verified.',
);
