import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const operationsPath = 'docs/RELEASE_OPERATIONS_EVIDENCE.md';
const codeReviewPath = 'docs/RELEASE_CODE_REVIEW.md';
const accountRecoveryPath = 'docs/RELEASE_ACCOUNT_RECOVERY_EVIDENCE.md';
const gameServicePath = 'lib/services/game_service.dart';
const customEggServicePath = 'lib/services/custom_egg_service.dart';
const customEggLogicTestPath = 'test/custom_egg_logic_test.dart';
const saveTransferTestPath = 'test/save_transfer_service_test.dart';
const appPlayerSwitchTestPath = 'test/app_player_switch_test.dart';
const saveImportValidationPath = 'lib/services/save_import_validation.dart';

const files = {
  [roadmapPath]: readFileSync(resolve(root, roadmapPath), 'utf8'),
  [operationsPath]: readFileSync(resolve(root, operationsPath), 'utf8'),
  [codeReviewPath]: readFileSync(resolve(root, codeReviewPath), 'utf8'),
  [accountRecoveryPath]: readFileSync(resolve(root, accountRecoveryPath), 'utf8'),
  [gameServicePath]: readFileSync(resolve(root, gameServicePath), 'utf8'),
  [customEggServicePath]: readFileSync(resolve(root, customEggServicePath), 'utf8'),
  [customEggLogicTestPath]: readFileSync(resolve(root, customEggLogicTestPath), 'utf8'),
  [saveTransferTestPath]: readFileSync(resolve(root, saveTransferTestPath), 'utf8'),
  [appPlayerSwitchTestPath]: readFileSync(resolve(root, appPlayerSwitchTestPath), 'utf8'),
  [saveImportValidationPath]: readFileSync(resolve(root, saveImportValidationPath), 'utf8'),
};

const failures = [];

function requirePhrase(path, phrase) {
  if (!files[path].includes(phrase)) {
    failures.push(`${path}: missing phrase "${phrase}"`);
  }
}

for (const phrase of [
  'Custom eggs. Legacy records remain readable but are not playable.',
  '[x] Retire custom eggs without breaking old Save Transfer files.',
  '[x] Restrict purchases and hatches to canonical built-in eggs.',
]) {
  requirePhrase(roadmapPath, phrase);
}

for (const phrase of [
  'Legacy files with dormant custom eggs remain readable while custom eggs stay',
  'custom eggs',
]) {
  requirePhrase(operationsPath, phrase);
}

for (const phrase of [
  'Legacy files with dormant custom eggs remain importable while custom eggs',
]) {
  requirePhrase(codeReviewPath, phrase);
}

for (const phrase of [
  'Legacy files with dormant custom eggs remain importable while custom eggs',
  'not import foreign identity',
]) {
  requirePhrase(accountRecoveryPath, phrase);
}

for (const phrase of [
  'List<Egg> get visibleShopEggs => GameData.eggs',
  'final builtInEgg = GameData.eggById(egg.id);',
  'if (builtInEgg == null || !canBuyEgg(builtInEgg)) return false;',
  "throw ArgumentError.value(egg.id, 'egg.id', 'Unknown egg');",
  '_rollAndApplyHatch(',
]) {
  requirePhrase(gameServicePath, phrase);
}

for (const phrase of [
  'Checked device-local eggs, retaining unknown fields and records.',
  "static const _storageKey = 'customEggs';",
  'List<CustomEgg> get allEggs',
  'Future<void> initialize',
  'CustomEgg? getById',
]) {
  requirePhrase(customEggServicePath, phrase);
}

for (const phrase of [
  'custom egg objects cannot enter the built-in hatch pipeline',
  'expect(game.buyEgg(egg), isFalse);',
  'expect(() => game.hatchEgg(egg), throwsArgumentError);',
  'built-in egg hatching is unchanged',
  'DayGull animals stay secret in custom egg editor',
]) {
  requirePhrase(customEggLogicTestPath, phrase);
}

for (const phrase of [
  'release legacy transfer keeps old local profile and dormant custom eggs',
  'customEggs.account.legacy_player',
  'contains(\'custom_legacy_1\')',
  "'customEggs.account.imported': {'type': 'string', 'value': '[false]'}",
  "test('rejects unreadable \${entry.key} without mutations'",
]) {
  requirePhrase(saveTransferTestPath, phrase);
}

for (const phrase of [
  'unreadable custom eggs stay untouched and another player can open',
  "AccountStorage.key('customEggs'",
]) {
  requirePhrase(appPlayerSwitchTestPath, phrase);
}

for (const phrase of [
  "key == 'customEggs'",
  "key.startsWith('customEggs.account.')",
  'CustomEgg.fromJson',
]) {
  requirePhrase(saveImportValidationPath, phrase);
}

const forbiddenRuntimeImports = [
  'lib/screens/custom_eggs_screen.dart',
  'lib/screens/custom_egg_editor_screen.dart',
];

for (const path of [gameServicePath, 'lib/main.dart', 'lib/navigation/app_page_route.dart']) {
  for (const forbiddenImport of forbiddenRuntimeImports) {
    if (files[path]?.includes(forbiddenImport)) {
      failures.push(`${path}: custom egg gameplay route is still imported: ${forbiddenImport}`);
    }
  }
}

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  'Custom egg retirement audit: dormant legacy records, save transfer compatibility and built-in-only hatch pipeline verified.',
);
