import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const readinessPath = 'docs/PLATFORM_STORE_READINESS.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const candidatePath = 'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md';
const decisionPath = 'docs/RELEASE_DECISION_PACKET.md';
const androidBuildPath = 'android/app/build.gradle.kts';
const androidIgnorePath = 'android/.gitignore';
const androidKeyExamplePath = 'android/key.properties.example';
const iosProjectPath = 'ios/Runner.xcodeproj/project.pbxproj';

const readiness = readFileSync(resolve(root, readinessPath), 'utf8');
const roadmap = readFileSync(resolve(root, roadmapPath), 'utf8');
const candidate = readFileSync(resolve(root, candidatePath), 'utf8');
const decision = readFileSync(resolve(root, decisionPath), 'utf8');
const androidBuild = readFileSync(resolve(root, androidBuildPath), 'utf8');
const androidIgnore = readFileSync(resolve(root, androidIgnorePath), 'utf8');
const androidKeyExample = readFileSync(resolve(root, androidKeyExamplePath), 'utf8');
const iosProject = readFileSync(resolve(root, iosProjectPath), 'utf8');

const failures = [];

for (const phrase of [
  'does not select a launch platform',
  'Android source is present',
  'iOS source is present',
  'otherwise falls back to debug signing',
  'Android remains blocked',
  'Store metadata and disclosure work must wait',
]) {
  if (!readiness.includes(phrase)) {
    failures.push(`${readinessPath}: missing platform-store boundary "${phrase}"`);
  }
}

for (const path of [
  androidBuildPath,
  androidKeyExamplePath,
  androidIgnorePath,
  iosProjectPath,
]) {
  if (!readiness.includes(path)) {
    failures.push(`${readinessPath}: missing prepared file reference ${path}`);
  }
}

for (const phrase of [
  'val hasReleaseSigning',
  'rootProject.file("key.properties")',
  'if (hasReleaseSigning)',
  'create("release")',
  'if (hasReleaseSigning) "release" else "debug"',
]) {
  if (!androidBuild.includes(phrase)) {
    failures.push(`${androidBuildPath}: missing signing guard "${phrase}"`);
  }
}

for (const ignored of ['key.properties', '**/*.keystore', '**/*.jks']) {
  if (!androidIgnore.includes(ignored)) {
    failures.push(`${androidIgnorePath}: missing ignored private credential "${ignored}"`);
  }
  if (!readiness.includes(ignored)) {
    failures.push(`${readinessPath}: missing credential-protection note "${ignored}"`);
  }
}

for (const field of [
  'storePassword=replace-with-keystore-password',
  'keyPassword=replace-with-key-password',
  'keyAlias=upload',
  'storeFile=../upload-keystore.jks',
]) {
  if (!androidKeyExample.includes(field)) {
    failures.push(`${androidKeyExamplePath}: missing example signing field "${field}"`);
  }
}

for (const privatePath of [
  'android/key.properties',
  'android/upload-keystore.jks',
  'android/upload-keystore.keystore',
]) {
  if (existsSync(resolve(root, privatePath))) {
    failures.push(`${privatePath}: private signing material must not be committed`);
  }
}

for (const phrase of [
  'PRODUCT_BUNDLE_IDENTIFIER = com.egghatchers.game',
  'CODE_SIGN_STYLE = Automatic',
]) {
  if (!iosProject.includes(phrase)) {
    failures.push(`${iosProjectPath}: missing iOS project marker "${phrase}"`);
  }
}

for (const item of [
  '[ ] Configure Android release signing and protect the signing credentials.',
  '[ ] Build and inspect a signed Android App Bundle if Android is selected.',
  '[ ] Configure iOS signing and run real-device testing if iOS is selected.',
  '[ ] Complete store names, descriptions, screenshots, ratings and disclosures.',
  '[ ] Complete Google Play Data Safety and Apple privacy answers from the actual',
  '[ ] Verify account-deletion and support links from each selected store.',
]) {
  if (!roadmap.includes(item)) {
    failures.push(`${roadmapPath}: store readiness gate is not open: ${item}`);
  }
}

if (!roadmap.includes('Configure selected platform signing/store readiness only after launch')) {
  failures.push(`${roadmapPath}: missing selected-platform ordering rule`);
}

for (const field of [
  'Android App Bundle path/checksum',
  'iOS archive/build identifier',
  'Store Data Safety/Privacy answers source reference',
  'Support/account-deletion URL',
]) {
  if (!candidate.includes(field)) {
    failures.push(`${candidatePath}: missing release candidate field "${field}"`);
  }
}

for (const phrase of [
  'First release platforms:',
  'First launch countries:',
]) {
  if (!decision.includes(phrase)) {
    failures.push(`${decisionPath}: missing owner decision prompt "${phrase}"`);
  }
}

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log('Platform store audit: Android signing guard, iOS markers, and store gates verified.');
