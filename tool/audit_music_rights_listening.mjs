import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const signoffPath = 'docs/MUSIC_RIGHTS_AND_LISTENING_SIGNOFF.md';
const audioAcceptancePath = 'docs/AUDIO_RELEASE_ACCEPTANCE.md';
const assetRightsPath = 'docs/ASSET_RIGHTS_RELEASE_AUDIT.md';
const visualAuditPath = 'docs/VISUAL_AUDIO_ACCESSIBILITY_AUDIT.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const evidenceIndexPath = 'docs/RELEASE_EVIDENCE_INDEX.md';
const runbookPath = 'docs/RELEASE_VERIFICATION_RUNBOOK.md';
const workflowPath = '.github/workflows/verify.yml';
const releaseEvidenceAuditPath = 'tool/audit_release_evidence.mjs';

const signoff = readFileSync(resolve(root, signoffPath), 'utf8');
const audioAcceptance = readFileSync(resolve(root, audioAcceptancePath), 'utf8');
const assetRights = readFileSync(resolve(root, assetRightsPath), 'utf8');
const visualAudit = readFileSync(resolve(root, visualAuditPath), 'utf8');
const roadmap = readFileSync(resolve(root, roadmapPath), 'utf8');
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

for (const heading of [
  '## Signoff identity',
  '## Music source records to fill',
  '## Normal boss listening pass',
  '## Whole-game listening pass',
  '## Required technical evidence',
  '## Stop conditions',
]) {
  requirePhrase(signoffPath, signoff, heading);
}

for (const phrase of [
  'does not confirm commercial rights',
  'exact release candidate',
  'Candidate commit',
  'Release owner',
  'Audio reviewer',
  'Rights/source reviewer',
  'Selected launch platforms',
]) {
  requirePhrase(signoffPath, signoff, phrase);
}

const musicFiles = [
  'assets/sounds/music/hatchery_chill_loop.mp3',
  'assets/sounds/music/boss_music.wav',
  'assets/sounds/music/final_boss_music.mp3',
];

for (const file of musicFiles) {
  requirePhrase(signoffPath, signoff, file);
  requirePhrase(audioAcceptancePath, audioAcceptance, file);
  requirePhrase(assetRightsPath, assetRights, file);
}

for (const phrase of [
  'Suno, BandLab, or another music tool',
  'account',
  'subscription/license status',
  'export date',
  'project or post link',
  'commercial game use',
  'docs/ASSET_RIGHTS_RELEASE_AUDIT.md',
]) {
  requirePhrase(signoffPath, signoff, phrase);
}

for (const phrase of [
  '0:00.000',
  '0:01.667',
  '0:13.333',
  '0:16.667',
  '0:26.667',
  '0:30.000',
  '0:40.000',
  '1:06.667',
  'instead of restarting the track',
  'selected platforms',
]) {
  requirePhrase(signoffPath, signoff, phrase);
  requirePhrase(audioAcceptancePath, audioAcceptance, phrase);
}

for (const phrase of [
  'Hatchery music starts',
  'Rotten Shell final boss music',
  'Reward, hit, finisher, purchase, hatch, fusion, UI, and cinematic sounds',
  'Music and SFX sliders',
  'Music and SFX mute toggles persist',
  'Pause/resume does not stack duplicate music',
  'App background/foreground behavior',
  'Reduced Battle Effects',
]) {
  requirePhrase(signoffPath, signoff, phrase);
}

for (const phrase of [
  'node tool/audit_audio_release.mjs',
  'node tool/audit_asset_rights.mjs',
  'test/audio_assets_test.dart',
  'test/manual_battle_test.dart',
  'docs/AUDIO_RELEASE_ACCEPTANCE.md',
  'docs/ASSET_RIGHTS_RELEASE_AUDIT.md',
  'docs/VISUAL_AUDIO_ACCESSIBILITY_AUDIT.md',
]) {
  requirePhrase(signoffPath, signoff, phrase);
}

for (const phrase of [
  'lacks source/license confirmation',
  'Commercial game use is not approved',
  'boss phase restarts at `0:00`',
  'loops outside its approved BandLab red range',
  'painfully loud at default volume',
  'Mute or slider settings do not persist',
  'background/foreground behavior breaks',
  'unregistered audio file',
  'release candidate record does not cite',
]) {
  requirePhrase(signoffPath, signoff, phrase);
}

for (const phrase of [
  'Owner listening approval',
  'Volume normalization approval',
  'Platform audio behavior checks',
  'Source/license confirmation',
]) {
  requirePhrase(audioAcceptancePath, audioAcceptance, phrase);
}

for (const phrase of [
  'need final owner confirmation',
  'commercial-use rights',
]) {
  requirePhrase(assetRightsPath, assetRights, phrase);
}

for (const phrase of [
  'Boss phase music loop approval',
  'Music and SFX volume normalization',
  'Audio unlock, pause/resume and background/foreground behavior',
]) {
  requirePhrase(visualAuditPath, visualAudit, phrase);
}

for (const item of [
  '[ ] Finalize boss phase music loops and all other music transitions.',
  '[ ] Normalize music and sound-effect volume.',
  '[ ] Verify audio unlock, pause/resume and background/foreground behavior on',
  '[ ] Confirm commercial rights and source records for every shipped asset.',
]) {
  requirePhrase(roadmapPath, roadmap, item);
}

for (const phrase of [
  signoffPath,
  'node tool/audit_music_rights_listening.mjs',
]) {
  requirePhrase(evidenceIndexPath, evidenceIndex, phrase);
  requirePhrase(runbookPath, runbook, phrase);
}

for (const phrase of [
  'node tool/audit_music_rights_listening.mjs',
  'Verify music rights and listening signoff',
]) {
  requirePhrase(workflowPath, workflow, phrase);
}

requirePhrase(releaseEvidenceAuditPath, releaseEvidenceAudit, signoffPath);

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  'Music rights/listening audit: source records, boss loop checks, whole-game mix and stop conditions verified.',
);
