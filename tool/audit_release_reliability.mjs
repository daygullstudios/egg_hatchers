import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const evidencePath = 'docs/RELEASE_RELIABILITY_EVIDENCE.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const runbookPath = 'docs/RELEASE_VERIFICATION_RUNBOOK.md';
const evidenceIndexPath = 'docs/RELEASE_EVIDENCE_INDEX.md';
const offlineStartupTestPath = 'test/offline_startup_test.dart';
const unsavedProgressTestPath = 'test/unsaved_progress_test.dart';
const progressRecoveryTestPath = 'test/progress_recovery_test.dart';
const progressRecoveryUiTestPath = 'test/progress_recovery_ui_test.dart';
const settingsPersistenceTestPath = 'test/settings_persistence_test.dart';
const saveTransferTestPath = 'test/save_transfer_service_test.dart';
const releaseSurfacePath = 'docs/RELEASE_FREEZE_SURFACE_EVIDENCE.md';

const files = {
  [evidencePath]: readFileSync(resolve(root, evidencePath), 'utf8'),
  [roadmapPath]: readFileSync(resolve(root, roadmapPath), 'utf8'),
  [runbookPath]: readFileSync(resolve(root, runbookPath), 'utf8'),
  [evidenceIndexPath]: readFileSync(resolve(root, evidenceIndexPath), 'utf8'),
  [offlineStartupTestPath]: readFileSync(resolve(root, offlineStartupTestPath), 'utf8'),
  [unsavedProgressTestPath]: readFileSync(resolve(root, unsavedProgressTestPath), 'utf8'),
  [progressRecoveryTestPath]: readFileSync(resolve(root, progressRecoveryTestPath), 'utf8'),
  [progressRecoveryUiTestPath]: readFileSync(resolve(root, progressRecoveryUiTestPath), 'utf8'),
  [settingsPersistenceTestPath]: readFileSync(resolve(root, settingsPersistenceTestPath), 'utf8'),
  [saveTransferTestPath]: readFileSync(resolve(root, saveTransferTestPath), 'utf8'),
  [releaseSurfacePath]: readFileSync(resolve(root, releaseSurfacePath), 'utf8'),
};

const failures = [];

function requirePhrase(path, phrase) {
  if (!files[path].includes(phrase)) {
    failures.push(`${path}: missing phrase "${phrase}"`);
  }
}

for (const phrase of [
  'Slow and offline startup',
  'Interrupted and uncertain saves',
  'Damaged progress and recovery',
  'Settings and import safety',
  'full Flutter suite passed',
  'test/release_reliability_evidence_test.dart',
]) {
  requirePhrase(evidencePath, phrase);
}

const documentedCoverage = new Map([
  [
    offlineStartupTestPath,
    [
      'Slow storage checks explain the wait without a bypass or overlapping retry.',
      'Slow local-player loading shows scrollable guidance and does not start',
      'Slow cloud initialization is single-flight, accepts late success and',
      'Valid local players can open and save with hanging or failed Firebase',
      'Hanging identity does not block local play',
    ],
  ],
  [
    unsavedProgressTestPath,
    [
      'Failed live saves freeze mutation, cloud acknowledgement, import and player',
      'Slow writes are single-flight and keep the latest coalesced in-memory',
      'Failed write positions are retriable without losing the previous primary or',
      'Stale retries and stale loaded players cannot overwrite newer primary saves.',
      'Queued writes serialize backup rotation and revision increments.',
    ],
  ],
  [
    progressRecoveryTestPath,
    [
      'Autosave preserves the fresh primary as backup instead of using stale cache.',
      'Storage outages surface `storageUnavailable` instead of inventing an empty',
      'Unsupported envelopes and malformed containers cannot become legacy saves.',
      'Interrupted backup restore can resume or cancel without losing originals.',
      'Stale previews and changed copies fail closed.',
      'Runtime corruption blocks autosave and cloud replacement.',
    ],
  ],
  [
    progressRecoveryUiTestPath,
    [
      'Damaged primary progress pauses the app, keeps the original data and allows',
      'Backup review and confirmation fit narrow and enlarged-text screens.',
      'Runtime damage replaces gameplay with the recovery screen instead of saving',
    ],
  ],
  [
    settingsPersistenceTestPath,
    [
      'Read outages do not mutate storage or manufacture saved defaults.',
      'Slow settings writes show guidance without retry overlap.',
      'Import is refused before writers are paused.',
    ],
  ],
]);

for (const [path, phrases] of documentedCoverage) {
  requirePhrase(evidencePath, path);
  for (const phrase of phrases) {
    requirePhrase(evidencePath, phrase);
  }
}

for (const [path, phrases] of [
  [
    offlineStartupTestPath,
    [
      'slow storage check explains the wait without a bypass or parallel retry',
      'slow local player load has scrollable guidance without starting identity',
      'slow cloud initialization stays single-flight and late success is accepted',
      'valid local player opens and saves with',
    ],
  ],
  [
    unsavedProgressTestPath,
    [
      'failed live save freezes mutations, cloud acknowledgment, import and switching; retry resumes same memory',
      'slow write is single-flight and latest coalesced memory wins after success',
      'stale retry refuses another valid save without changing either copy',
      'a loaded stale player cannot overwrite a newer primary on an ordinary save',
    ],
  ],
  [
    progressRecoveryTestPath,
    [
      'autosave preserves fresh primary as backup instead of using stale cache',
      'storageUnavailable',
      'interrupted restore mutation',
      'stale preview and changed copies at restart both fail closed',
      'runtime corruption blocks autosave and cloud replacement',
    ],
  ],
  [
    progressRecoveryUiTestPath,
    [
      'runtime damage replaces gameplay with recovery screen',
      'backup preview and confirmation fit',
    ],
  ],
  [
    settingsPersistenceTestPath,
    [
      'read outages do not mutate storage or manufacture saved defaults',
      'slow writes show guidance without retry overlap or blocking mute',
      'root keeps gameplay and player intact and refuses import before pausing writers',
    ],
  ],
  [
    saveTransferTestPath,
    [
      'valid pre-directory legacy save remains importable through real preferences',
      'pending input is validated again before the recovery snapshot or replacement',
      'interrupted replacement retains journal and restores exact original identity on restart',
    ],
  ],
]) {
  for (const phrase of phrases) {
    requirePhrase(path, phrase);
  }
}

for (const item of [
  '[x] Test slow/offline startup, refreshes, interrupted saves and service outages.',
  '[x] Test older supported Save Transfer files against the candidate.',
  '[ ] Add production error monitoring that matches the approved privacy model.',
  '[ ] Confirm backups, restore procedures, rate limits and operational alerts.',
]) {
  requirePhrase(roadmapPath, item);
}

for (const phrase of [
  'docs/RELEASE_RELIABILITY_EVIDENCE.md',
  'Open release dependencies: approved production monitoring, alert destinations',
]) {
  requirePhrase(evidenceIndexPath, phrase);
}

for (const phrase of [
  'Release-surface audit',
  'node tool/audit_release_surface.mjs',
  'flutter build web --release --no-pub',
]) {
  requirePhrase(runbookPath, phrase);
}

for (const phrase of [
  'Legacy save field `fullDeveloperToolsUnlocked` is still readable',
  'release surface audit scans `build/web/main.dart.js`',
  'Developer Tools (Debug)',
]) {
  requirePhrase(releaseSurfacePath, phrase);
}

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  'Release reliability audit: offline startup, interrupted saves, recovery, settings, legacy saves and release-surface evidence verified.',
);
