import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const planPath = 'docs/CLOSED_BETA_PLAN.md';
const findingsPath = 'docs/CLOSED_BETA_FINDINGS_LOG_TEMPLATE.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const decisionsPath = 'docs/RELEASE_DECISION_PACKET.md';
const candidatePath = 'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md';
const evidenceIndexPath = 'docs/RELEASE_EVIDENCE_INDEX.md';

const plan = readFileSync(resolve(root, planPath), 'utf8');
const findings = readFileSync(resolve(root, findingsPath), 'utf8');
const roadmap = readFileSync(resolve(root, roadmapPath), 'utf8');
const decisions = readFileSync(resolve(root, decisionsPath), 'utf8');
const candidate = readFileSync(resolve(root, candidatePath), 'utf8');
const evidenceIndex = readFileSync(resolve(root, evidenceIndexPath), 'utf8');

const failures = [];

function requirePhrase(path, text, phrase) {
  if (!text.includes(phrase)) {
    failures.push(`${path}: missing phrase "${phrase}"`);
  }
}

for (const path of [
  planPath,
  findingsPath,
  decisionsPath,
  candidatePath,
]) {
  if (!existsSync(resolve(root, path))) {
    failures.push(`${path}: required closed-beta evidence file does not exist`);
  }
}

for (const phrase of [
  'does not authorize',
  'Gates 2 through 7',
  'Launch platforms and countries must be chosen',
  'release owner and rollback decision maker',
  'Family/privacy review',
  'Production monitoring, backup, restore and alert procedures',
  'ordinary fresh accounts',
]) {
  requirePhrase(planPath, plan, phrase);
}

for (const phrase of [
  'fresh-player tester',
  'returning-player tester',
  'multiplayer/trading pair',
  'narrow-phone layout tester',
  'preset-only',
  'one online battle',
  'one trade',
  'blocked-player/report flow',
  'Do not ask testers to send passwords',
  'Save Transfer file',
]) {
  requirePhrase(planPath, plan, phrase);
}

for (const phrase of [
  'Critical:',
  'High:',
  'Medium:',
  'Low:',
  'block release',
  'focused retest',
  'complete candidate pass',
  'Rollback to the previous protected version',
  'Tester message template',
]) {
  requirePhrase(planPath, plan, phrase);
}

for (const phrase of [
  'not fill it with real tester details',
  'Candidate name',
  'Git commit',
  'Release owner',
  'Triage owner',
  'Fresh-player testers',
  'Returning/import testers',
  'Multiplayer/trading pairs',
  'Severity: Critical / High / Medium / Low',
  "Status: New / Investigating / Fixed / Retest passed / Accepted risk / Won't fix",
  'Private data received',
  'Focused retest result',
  'Critical findings open',
  'High findings open',
  'Account/save/multiplayer regressions open',
  'Privacy/family-safety findings open',
  'Candidate pass after last risky fix',
  'Rollback test after candidate',
]) {
  requirePhrase(findingsPath, findings, phrase);
}

for (const item of [
  '[ ] Recruit a small trusted group across supported devices and networks.',
  '[ ] Give testers ordinary fresh accounts and written reporting instructions.',
  '[ ] Track crashes, save failures, progression confusion and multiplayer abuse.',
  '[ ] Resolve all critical and high-priority findings.',
  '[ ] Repeat focused tests for every fix and one complete candidate pass.',
]) {
  requirePhrase(roadmapPath, roadmap, item);
}

for (const phrase of [
  'Launch platforms',
  'Launch countries',
  'Release owner and rollback decision maker',
  'Family/privacy review path',
  'Monitoring, backups and alerts',
]) {
  requirePhrase(decisionsPath, decisions, phrase);
}

for (const phrase of [
  'Critical risks',
  'High risks',
  'Release owner approval',
  'Rollback decision maker approval',
  'Rollback test result',
]) {
  requirePhrase(candidatePath, candidate, phrase);
}

for (const phrase of [
  'docs/CLOSED_BETA_PLAN.md',
  'docs/CLOSED_BETA_FINDINGS_LOG_TEMPLATE.md',
  'Open release dependencies: approved beta entry',
]) {
  requirePhrase(evidenceIndexPath, evidenceIndex, phrase);
}

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  'Closed beta readiness audit: entry gates, tester safety, triage and exit blockers verified.',
);
