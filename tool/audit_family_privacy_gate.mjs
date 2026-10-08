import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const familyPath = 'docs/FAMILY_AUDIENCE_V1.md';
const capabilityEvidencePath = 'docs/RELEASE_FAMILY_CAPABILITY_EVIDENCE.md';
const publicPolicyPath = 'docs/PUBLIC_POLICY_READINESS.md';
const decisionPacketPath = 'docs/RELEASE_DECISION_PACKET.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const evidenceIndexPath = 'docs/RELEASE_EVIDENCE_INDEX.md';
const workerTestPath = 'cloudflare/multiplayer/test/worker.test.ts';
const safetyTestPath = 'cloudflare/multiplayer/test/safety_authority.test.ts';
const safetyAuthorityPath = 'cloudflare/multiplayer/src/safety_authority.ts';
const tradingTestPath = 'test/trading_service_test.dart';
const multiplayerTestPath = 'test/multiplayer_service_test.dart';

const family = readFileSync(resolve(root, familyPath), 'utf8');
const capabilityEvidence = readFileSync(resolve(root, capabilityEvidencePath), 'utf8');
const publicPolicy = readFileSync(resolve(root, publicPolicyPath), 'utf8');
const decisionPacket = readFileSync(resolve(root, decisionPacketPath), 'utf8');
const roadmap = readFileSync(resolve(root, roadmapPath), 'utf8');
const evidenceIndex = readFileSync(resolve(root, evidenceIndexPath), 'utf8');
const workerTest = readFileSync(resolve(root, workerTestPath), 'utf8');
const safetyTest = readFileSync(resolve(root, safetyTestPath), 'utf8');
const safetyAuthority = readFileSync(resolve(root, safetyAuthorityPath), 'utf8');
const tradingTest = readFileSync(resolve(root, tradingTestPath), 'utf8');
const multiplayerTest = readFileSync(resolve(root, multiplayerTestPath), 'utf8');

const failures = [];

function requirePhrase(path, text, phrase) {
  if (!text.includes(phrase)) {
    failures.push(`${path}: missing phrase "${phrase}"`);
  }
}

for (const phrase of [
  'ages 8–12 are actively intended players',
  'Professional review required',
  'This is implementation planning, not legal clearance.',
  'Do not mark the milestone complete',
  'use Roblox as the age/parent-control',
  'Nestarium remains preset-',
  'Five bounded requirements',
  'F1 — Determine eligibility before optional data connections',
  'F2 — Parent-managed cloud save',
  'F3 — Keep public presence and sharing off until independently ready',
  'F4 — Operable notices, retention and deletion',
  'F5 — Truthful platform and territory acceptance',
  'No age/parent-permission gate precedes this path',
  'Analytics and Crashlytics are not added.',
]) {
  requirePhrase(familyPath, family, phrase);
}

for (const phrase of [
  'technical evidence only',
  'professional audience/privacy review',
  'approved guardian flow',
  'parent-managed controls',
  'final retention ownership',
  'candidate legal policy work',
]) {
  requirePhrase(capabilityEvidencePath, capabilityEvidence, phrase);
}

const evidenceMap = new Map([
  [
    workerTestPath,
    [
      'fails closed unless trusted capability claims use the current policy',
      'fails closed in registry mode and accepts only a resolved hosted capability',
      'enforces battle and trade permissions independently after connection',
      'matches two verified identities without disclosing supplied names or ids',
      'records preset reports and persists two-way matchmaking blocks',
      'retires a live hosted session when its capability decision is revoked',
    ],
  ],
  [
    safetyTestPath,
    [
      'stores idempotent pseudonymous reports and prunes them after retention',
      'issues, expires, and revokes bounded capability decisions',
    ],
  ],
  [
    safetyAuthorityPath,
    [
      'profile discovery is not approved in family policy v1',
      'preset messages require trading permission',
      'moderationReportRetentionMs',
      'deniedCapabilities',
      'capabilityDecisionForUid',
    ],
  ],
  [
    tradingTestPath,
    [
      'hosted trading authenticates and consumes only server inventory',
      'TradeChatTag.isThisFair',
      'TradeChatTag.requestAnimal',
    ],
  ],
  [
    multiplayerTestPath,
    ['hosted battle sends preset player safety actions'],
  ],
]);

const sourceByPath = new Map([
  [workerTestPath, workerTest],
  [safetyTestPath, safetyTest],
  [safetyAuthorityPath, safetyAuthority],
  [tradingTestPath, tradingTest],
  [multiplayerTestPath, multiplayerTest],
]);

for (const [path, phrases] of evidenceMap.entries()) {
  requirePhrase(capabilityEvidencePath, capabilityEvidence, path);
  const source = sourceByPath.get(path);
  for (const phrase of phrases) {
    requirePhrase(capabilityEvidencePath, capabilityEvidence, phrase);
    requirePhrase(path, source, phrase);
  }
}

for (const phrase of [
  'audienceDecisionRecorded',
  'policyAndSupportCopyApproved',
  'supportDeliveryAndReplyVerified',
  'Complete professional family/privacy review.',
  'Support and privacy pages explain current recovery, deletion, and family',
]) {
  requirePhrase(publicPolicyPath, publicPolicy, phrase);
}

for (const phrase of [
  'Family/privacy review path',
  'ages 8-12, teens and adults',
  'Hosted capabilities fail closed when policy claims are missing',
  'Player communication is preset-only',
  'Parent-managed controls',
]) {
  requirePhrase(decisionPacketPath, decisionPacket, phrase);
}

for (const item of [
  '[ ] Obtain professional audience/privacy review for the intended ages 8-12,',
  '[ ] Implement the approved age/guardian capability flow before optional data',
  '[ ] Add parent-managed permissions, review, revocation and deletion controls.',
  '[ ] Finalize retention rules and provider responsibilities.',
  '[ ] Publish candidate-accurate Privacy Policy, Terms and support instructions.',
]) {
  requirePhrase(roadmapPath, roadmap, item);
}

for (const phrase of [
  'docs/FAMILY_AUDIENCE_V1.md',
  'docs/RELEASE_FAMILY_CAPABILITY_EVIDENCE.md',
  'docs/PUBLIC_POLICY_READINESS.md',
  'Open release dependencies: professional review',
]) {
  requirePhrase(evidenceIndexPath, evidenceIndex, phrase);
}

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  'Family privacy gate audit: review blockers, fail-closed capabilities, preset safety and policy readiness verified.',
);
