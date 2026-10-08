import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const packetPath = 'docs/CLOSED_BETA_TESTER_PACKET.md';
const planPath = 'docs/CLOSED_BETA_PLAN.md';
const findingsPath = 'docs/CLOSED_BETA_FINDINGS_LOG_TEMPLATE.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const runbookPath = 'docs/RELEASE_VERIFICATION_RUNBOOK.md';
const evidenceIndexPath = 'docs/RELEASE_EVIDENCE_INDEX.md';
const workflowPath = '.github/workflows/verify.yml';

const packet = readFileSync(resolve(root, packetPath), 'utf8');
const plan = readFileSync(resolve(root, planPath), 'utf8');
const roadmap = readFileSync(resolve(root, roadmapPath), 'utf8');
const runbook = readFileSync(resolve(root, runbookPath), 'utf8');
const evidenceIndex = readFileSync(resolve(root, evidenceIndexPath), 'utf8');
const workflow = readFileSync(resolve(root, workflowPath), 'utf8');

const failures = [];

function requirePhrase(path, text, phrase) {
  if (!text.includes(phrase)) {
    failures.push(`${path}: missing phrase "${phrase}"`);
  }
}

for (const path of [
  packetPath,
  planPath,
  findingsPath,
  roadmapPath,
]) {
  if (!existsSync(resolve(root, path))) {
    failures.push(`${path}: required closed-beta file does not exist`);
  }
}

for (const phrase of [
  'not an invitation by itself',
  'release owner approves closed beta entry',
  'family/privacy plan is approved',
  'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md',
  'The beta link is private',
  'Do not send passwords',
  'one-time codes',
  'authentication tokens',
  'full browser storage dumps',
  'Save Transfer file is private account data',
  'child account or child tester',
  'Player communication remains preset-only',
  'ordinary fresh account',
  'Do not use seeded developer boosts',
]) {
  requirePhrase(packetPath, packet, phrase);
}

for (const phrase of [
  'fresh player',
  'returning/import',
  'multiplayer pair',
  'narrow phone',
  'larger screen',
  'Create a fresh player',
  'Export a Save Transfer file',
  'manual boss fight',
  'Bot Arena',
  'direct battle invitation',
  'trade invitation',
  "View another player's animals",
  'preset message',
  'Disconnect or refresh one player',
]) {
  requirePhrase(packetPath, packet, phrase);
}

for (const phrase of [
  'What you were doing',
  'What you expected to happen',
  'What happened instead',
  'Device, browser, and network type',
  'Approximate time',
  'Screenshot or short recording',
  'Critical and high-priority issues block release',
  'release owner and rollback decision maker',
  'Tester message',
]) {
  requirePhrase(packetPath, packet, phrase);
}

for (const phrase of [
  packetPath,
  'node tool/audit_closed_beta_tester_packet.mjs',
]) {
  requirePhrase(runbookPath, runbook, phrase);
}

for (const phrase of [
  packetPath,
  'Open release dependencies: approved beta entry',
]) {
  requirePhrase(evidenceIndexPath, evidenceIndex, phrase);
}

for (const phrase of [
  'node tool/audit_closed_beta_tester_packet.mjs',
  'Verify closed beta tester packet',
]) {
  requirePhrase(workflowPath, workflow, phrase);
}

for (const item of [
  '[ ] Give testers ordinary fresh accounts and written reporting instructions.',
  '[ ] Track crashes, save failures, progression confusion and multiplayer abuse.',
]) {
  requirePhrase(roadmapPath, roadmap, item);
}

for (const phrase of [
  'Do not ask testers to send passwords',
  'Save Transfer file',
  'preset-only',
]) {
  requirePhrase(planPath, plan, phrase);
}

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  'Closed beta tester packet audit: tester instructions, privacy boundaries and open beta gates verified.',
);
