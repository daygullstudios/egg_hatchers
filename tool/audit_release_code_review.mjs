import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const evidencePath = 'docs/RELEASE_CODE_REVIEW.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const evidenceIndexPath = 'docs/RELEASE_EVIDENCE_INDEX.md';
const saveTransferTestPath = 'test/save_transfer_service_test.dart';
const progressSyncTestPath = 'test/progress_sync_service_test.dart';
const progressRecoveryTestPath = 'test/progress_recovery_test.dart';
const unsavedProgressTestPath = 'test/unsaved_progress_test.dart';
const checkpointTestPath = 'test/checkpoint_persistence_test.dart';
const accountProtectionTestPath = 'test/account_protection_service_test.dart';
const crossDeviceRecoveryTestPath = 'test/cross_device_recovery_test.dart';
const multiplayerTestPath = 'test/multiplayer_service_test.dart';
const tradingTestPath = 'test/trading_service_test.dart';
const workerTestPath = 'cloudflare/multiplayer/test/worker.test.ts';
const safetyTestPath = 'cloudflare/multiplayer/test/safety_authority.test.ts';
const migrationTestPath = 'cloudflare/multiplayer/test/migration.test.ts';
const authPath = 'cloudflare/multiplayer/src/auth.ts';
const workerPath = 'cloudflare/multiplayer/src/index.ts';

const files = {
  [evidencePath]: readFileSync(resolve(root, evidencePath), 'utf8'),
  [roadmapPath]: readFileSync(resolve(root, roadmapPath), 'utf8'),
  [evidenceIndexPath]: readFileSync(resolve(root, evidenceIndexPath), 'utf8'),
  [saveTransferTestPath]: readFileSync(resolve(root, saveTransferTestPath), 'utf8'),
  [progressSyncTestPath]: readFileSync(resolve(root, progressSyncTestPath), 'utf8'),
  [progressRecoveryTestPath]: readFileSync(resolve(root, progressRecoveryTestPath), 'utf8'),
  [unsavedProgressTestPath]: readFileSync(resolve(root, unsavedProgressTestPath), 'utf8'),
  [checkpointTestPath]: readFileSync(resolve(root, checkpointTestPath), 'utf8'),
  [accountProtectionTestPath]: readFileSync(resolve(root, accountProtectionTestPath), 'utf8'),
  [crossDeviceRecoveryTestPath]: readFileSync(resolve(root, crossDeviceRecoveryTestPath), 'utf8'),
  [multiplayerTestPath]: readFileSync(resolve(root, multiplayerTestPath), 'utf8'),
  [tradingTestPath]: readFileSync(resolve(root, tradingTestPath), 'utf8'),
  [workerTestPath]: readFileSync(resolve(root, workerTestPath), 'utf8'),
  [safetyTestPath]: readFileSync(resolve(root, safetyTestPath), 'utf8'),
  [migrationTestPath]: readFileSync(resolve(root, migrationTestPath), 'utf8'),
  [authPath]: readFileSync(resolve(root, authPath), 'utf8'),
  [workerPath]: readFileSync(resolve(root, workerPath), 'utf8'),
};

const failures = [];

function requirePhrase(path, phrase) {
  if (!files[path].includes(phrase)) {
    failures.push(`${path}: missing phrase "${phrase}"`);
  }
}

for (const phrase of [
  'release-focused code review for crashes, data loss and',
  'Scope reviewed',
  'No new critical release blocker was found',
  'Save and sync integrity',
  'Account protection',
  'Multiplayer and trading',
  'Worker auth and trust boundary',
  'test/release_code_review_evidence_test.dart',
]) {
  requirePhrase(evidencePath, phrase);
}

for (const phrase of [
  'Complete an approved cross-device account-recovery method.',
  'Complete trusted authenticated sessions in the production environment.',
  'Obtain the audience/privacy review and approved family capability flow.',
  'Add production error monitoring, backup/restore procedures and operational',
  'Perform the final authentication, multiplayer and trading security review.',
  'Run the two-device internet playtest outside the developer network.',
]) {
  requirePhrase(evidencePath, phrase);
}

const evidenceLinks = new Map([
  [
    saveTransferTestPath,
    [
      'Import review and staging never replace existing players',
      'A second staging attempt cannot replace the reviewed pending file.',
      'Supported settings are restored without importing foreign identity',
      'Legacy files with dormant custom eggs remain importable',
    ],
  ],
  [
    progressSyncTestPath,
    [
      'Local save failures preserve unresolved cloud choices',
      'Changed cloud state blocks both reviewed device and cloud replacement.',
      'Unknown cloud state never authorizes an upload.',
      'Player switches during explicit choices are isolated from stale work.',
      'Confirmed empty cloud upload records checkpoint ancestry.',
    ],
  ],
  [
    progressRecoveryTestPath,
    [
      'Storage outages surface `storageUnavailable`.',
      'Runtime corruption blocks autosave and cloud replacement.',
      'Interrupted backup restore can resume or cancel without losing originals.',
      'Stale previews and changed copies fail closed.',
    ],
  ],
  [
    unsavedProgressTestPath,
    [
      'Failed live saves freeze mutation, cloud acknowledgement, import and player',
      'Queued writes serialize backup rotation and revision increments.',
    ],
  ],
  [
    checkpointTestPath,
    [
      'Sync checkpoints are versioned and scoped by account.',
    ],
  ],
  [
    accountProtectionTestPath,
    [
      'Unconfigured builds report device-only progress.',
      'Opening an existing Google account clears old sync ancestry.',
      'Google protection is single-flight while the provider is open.',
      'Replacement guests receive fresh identity after local removal.',
    ],
  ],
  [
    crossDeviceRecoveryTestPath,
    [
      'Cross-device recovery remains covered as a staged acceptance path',
    ],
  ],
  [
    multiplayerTestPath,
    [
      'Released hosted multiplayer rejects a missing identity token.',
      'Hosted settlement is parsed and acknowledged explicitly.',
      'Hosted matches preserve identity and resume after a dropped socket.',
      'The match server rejects teams containing unknown animals.',
    ],
  ],
  [
    tradingTestPath,
    [
      'Released hosted trading rejects a missing identity token.',
      'Two online players complete a confirmed animal trade.',
      'Trading uses preset messages and animal request payloads rather than open',
    ],
  ],
  [
    workerTestPath,
    [
      'Missing Firebase tokens, tokens from another project and stale capability',
      'Battle and trade capabilities are enforced independently.',
      'The server owns the online roster and rejects forged battle teams.',
      'Online Roster trades commit exactly once.',
      'Disconnected trades cancel without moving either roster.',
      'Duplicate identity sessions are retired before accepting replacements.',
      'Settlement receipts are redelivered until acknowledged without minting',
    ],
  ],
  [
    safetyTestPath,
    [
      'Capability decisions issue, expire and revoke through the safety authority.',
    ],
  ],
  [
    migrationTestPath,
    [
      'Migration tools remain off the public HTTP surface',
    ],
  ],
]);

for (const [path, phrases] of evidenceLinks) {
  requirePhrase(evidencePath, path);
  for (const phrase of phrases) {
    requirePhrase(evidencePath, phrase);
  }
}

for (const [path, phrases] of [
  [
    saveTransferTestPath,
    [
      'review and staging never replace existing players or session',
      'a second staging attempt cannot replace the reviewed pending file',
      'release legacy transfer keeps old local profile and dormant custom eggs',
    ],
  ],
  [
    progressSyncTestPath,
    [
      'changed cloud blocks reviewed',
      'unknown cloud never authorizes an upload',
      'player switch during ${keepDevice ? \'device\' : \'cloud\'} choice is isolated',
      'confirmed empty cloud uploads local progress and records ancestry',
    ],
  ],
  [
    progressRecoveryTestPath,
    [
      'storageUnavailable',
      'runtime corruption blocks autosave and cloud replacement',
      'interrupted restore mutation',
      'stale preview and changed copies at restart both fail closed',
    ],
  ],
  [
    unsavedProgressTestPath,
    [
      'failed live save freezes mutations, cloud acknowledgment, import and switching',
      'queued writes serialize backup rotation and revision increments',
    ],
  ],
  [
    checkpointTestPath,
    [
      'checkpoint ${removing ? \'removal\' : \'write\'} checks $mode and retries exact data',
    ],
  ],
  [
    accountProtectionTestPath,
    [
      'unconfigured builds report device-only progress',
      'opening an existing Google account clears old sync ancestry',
      'Google protection is single-flight while the provider is open',
      'replacement guest receives a fresh identity after local removal',
    ],
  ],
  [
    crossDeviceRecoveryTestPath,
    [
      'existing identity recovery requires a choice and preserves cloud progress',
    ],
  ],
  [
    multiplayerTestPath,
    [
      'released hosted multiplayer rejects a missing identity token',
      'hosted settlement is parsed and acknowledged explicitly',
      'hosted match preserves identity and resumes after a dropped socket',
      'match server rejects teams containing unknown animals',
    ],
  ],
  [
    tradingTestPath,
    [
      'hosted trading authenticates and consumes only server inventory',
      'two online players complete a confirmed animal trade',
      'sendChat(TradeChatTag.isThisFair)',
      'TradeChatTag.requestAnimal',
    ],
  ],
  [
    workerTestPath,
    [
      'rejects an upgrade without a Firebase token',
      'rejects a validly signed token for another Firebase project',
      'enforces battle and trade permissions independently after connection',
      'owns the online roster and rejects a forged battle team',
      'commits a two-sided Online Roster trade exactly once',
      'cancels a disconnected trade without moving either roster',
      'retires a live hosted session when its capability decision is revoked',
      'settles a hosted result once and redelivers it until acknowledged',
    ],
  ],
  [
    safetyTestPath,
    [
      'issues, expires, and revokes bounded capability decisions',
    ],
  ],
  [
    migrationTestPath,
    [
      'public HTTP surface',
      'binding',
    ],
  ],
]) {
  for (const phrase of phrases) {
    requirePhrase(path, phrase);
  }
}

for (const phrase of [
  'firebase-auth.',
  'trusted_registry',
  'trusted_claims',
]) {
  requirePhrase(authPath, phrase);
}

for (const phrase of [
  'headers.delete("X-Nestarium-Uid")',
  'headers.delete("X-Nestarium-Capabilities")',
  'trustedBattleTeam',
  'completeTrade',
  'recordModerationReport',
]) {
  requirePhrase(workerPath, phrase);
}

for (const item of [
  '[x] Run a release-focused code review for crashes, data loss and security bugs.',
  '[x] Perform a security review of authentication, multiplayer and trading.',
  '[ ] Complete trusted authenticated sessions in the production environment.',
  '[ ] Run two-device internet play outside the developer network.',
]) {
  requirePhrase(roadmapPath, item);
}

for (const phrase of [
  'docs/RELEASE_CODE_REVIEW.md',
  'docs/RELEASE_SECURITY_REVIEW.md',
]) {
  requirePhrase(evidenceIndexPath, phrase);
}

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  'Release code review audit: save integrity, sync, account protection, multiplayer, trading and worker trust evidence verified.',
);
