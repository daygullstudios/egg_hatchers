import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const checklistPath = 'docs/RELEASE_FEATURE_FREEZE_CHECKLIST.md';
const surfacePath = 'docs/RELEASE_FREEZE_SURFACE_EVIDENCE.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const runbookPath = 'docs/RELEASE_VERIFICATION_RUNBOOK.md';
const evidenceIndexPath = 'docs/RELEASE_EVIDENCE_INDEX.md';
const workflowPath = '.github/workflows/verify.yml';
const releaseEvidenceAuditPath = 'tool/audit_release_evidence.mjs';

const checklist = readFileSync(resolve(root, checklistPath), 'utf8');
const surface = readFileSync(resolve(root, surfacePath), 'utf8');
const roadmap = readFileSync(resolve(root, roadmapPath), 'utf8');
const runbook = readFileSync(resolve(root, runbookPath), 'utf8');
const evidenceIndex = readFileSync(resolve(root, evidenceIndexPath), 'utf8');
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
  surfacePath,
  roadmapPath,
  runbookPath,
]) {
  if (!existsSync(resolve(root, path))) {
    failures.push(`${path}: required release-freeze file does not exist`);
  }
}

for (const heading of [
  '## Freeze identity',
  '## Feature boundary',
  '## Development-only surface',
  '## Allowed changes during freeze',
  '## Changes that reopen the candidate',
  '## Exit evidence',
]) {
  requirePhrase(checklistPath, checklist, heading);
}

for (const phrase of [
  'does not mark the roadmap item',
  'exact candidate commit',
  'Release owner',
  'Rollback decision maker',
  'Freeze exceptions owner',
  'Version 1.0 scope matches',
  'future events',
  'Custom eggs remain retired',
  'Bot Arena remains available',
  'preset-only',
  'Monetization remains dormant',
  'Classic, Retro Pixel and Realistic',
  'Rotten Shell and DayGull discovery flow',
]) {
  requirePhrase(checklistPath, checklist, phrase);
}

for (const phrase of [
  'Developer Tools are hidden outside debug builds',
  'node tool/audit_release_surface.mjs',
  'Developer Tools (Debug)',
  'Force Next Single Hatch',
  'Unlock Rotten Shell reqs',
  'Preview DayGull Unlock',
  'Collect All Animals',
  'temporary playtest host',
  'worker dev route',
  'Save Transfer import/export remains visible',
]) {
  requirePhrase(checklistPath, checklist, phrase);
}

for (const phrase of [
  'Critical or high-priority bug fixes',
  'Security, privacy, data-loss or crash-loop fixes',
  'Git commit',
  'Focused retest result',
  'full release matrix must be repeated',
  'Adds an animal, egg, boss, event, mutation, reward system or economy curve',
  'Save Transfer compatibility',
  'multiplayer settlement',
  'family/privacy capability model',
  'production routing',
  'rights approval',
  'Android/iOS signing',
  'CI run URL and artifact reference',
  'Rollback rehearsal result for the exact candidate',
  'critical or high-priority freeze finding remains open',
]) {
  requirePhrase(checklistPath, checklist, phrase);
}

for (const phrase of [
  checklistPath,
  'candidate is frozen',
  'release surface audit',
]) {
  requirePhrase(surfacePath, surface, phrase);
}

for (const phrase of [
  '[ ] Freeze features and remove or hide development-only controls.',
  '[ ] Run analysis, all tests, compatibility audit and every release build.',
]) {
  requirePhrase(roadmapPath, roadmap, phrase);
}

for (const phrase of [
  checklistPath,
  'node tool/audit_release_feature_freeze.mjs',
]) {
  requirePhrase(runbookPath, runbook, phrase);
  requirePhrase(evidenceIndexPath, evidenceIndex, phrase);
}

for (const phrase of [
  'node tool/audit_release_feature_freeze.mjs',
  'Verify release feature-freeze checklist',
]) {
  requirePhrase(workflowPath, workflow, phrase);
}

requirePhrase(releaseEvidenceAuditPath, releaseEvidenceAudit, checklistPath);

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  'Release feature-freeze audit: scope boundary, dev surface, freeze exceptions and candidate exit evidence verified.',
);
