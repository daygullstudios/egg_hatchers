import { readFileSync, statSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const readinessPath = 'docs/PLATFORM_BRANDING_READINESS.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const decisionPacketPath = 'docs/RELEASE_DECISION_PACKET.md';
const brandingReadmePath = 'assets/branding/README.md';
const generatorPath = 'tool/generate_brand_assets.dart';

const readiness = readFileSync(resolve(root, readinessPath), 'utf8');
const roadmap = readFileSync(resolve(root, roadmapPath), 'utf8');
const decisionPacket = readFileSync(resolve(root, decisionPacketPath), 'utf8');
const brandingReadme = readFileSync(resolve(root, brandingReadmePath), 'utf8');
const generator = readFileSync(resolve(root, generatorPath), 'utf8');

const pngTargets = [
  'assets/branding/nestarium_source.png',
  'assets/images/ui/app_logo.png',
  'web/favicon.png',
  'web/icons/Icon-192.png',
  'web/icons/Icon-512.png',
  'web/icons/Icon-maskable-192.png',
  'web/icons/Icon-maskable-512.png',
  'android/app/src/main/res/drawable-nodpi/launch_image.png',
  'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
  'android/app/src/main/res/mipmap-hdpi/ic_launcher.png',
  'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png',
  'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png',
  'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
  'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png',
];

const nonPngTargets = [
  'windows/runner/resources/app_icon.ico',
];

function pngSize(relativePath) {
  const bytes = readFileSync(resolve(root, relativePath));
  if (
    bytes[0] !== 0x89 ||
    bytes[1] !== 0x50 ||
    bytes[2] !== 0x4e ||
    bytes[3] !== 0x47
  ) {
    throw new Error(`${relativePath}: not a PNG file`);
  }
  return {
    width: bytes.readUInt32BE(16),
    height: bytes.readUInt32BE(20),
  };
}

const failures = [];

for (const relativePath of [...pngTargets, ...nonPngTargets]) {
  const stats = statSync(resolve(root, relativePath), { throwIfNoEntry: false });
  if (!stats?.isFile()) {
    failures.push(`${relativePath}: missing branding target`);
    continue;
  }
  if (stats.size <= 1024) {
    failures.push(`${relativePath}: branding target is unexpectedly small`);
  }
}

const sourceSize = pngSize('assets/branding/nestarium_source.png');
if (sourceSize.width !== sourceSize.height || sourceSize.width < 1024) {
  failures.push(
    `assets/branding/nestarium_source.png: expected square source >=1024px, got ${sourceSize.width}x${sourceSize.height}`,
  );
}

for (const relativePath of pngTargets) {
  const size = pngSize(relativePath);
  if (size.width <= 0 || size.height <= 0) {
    failures.push(`${relativePath}: invalid PNG dimensions ${size.width}x${size.height}`);
  }
}

for (const requiredText of [
  'nestarium_source.png',
  'NESTARIUM',
  'central safe area',
  'No old text',
]) {
  if (!brandingReadme.includes(requiredText)) {
    failures.push(`${brandingReadmePath}: missing source record text "${requiredText}"`);
  }
}

for (const requiredText of [
  'nestarium_source.png',
  "'web/icons'",
  "path.contains('maskable')",
  'image.encodeIco',
  'android/app/src/main/res/drawable-nodpi/launch_image.png',
  'windows/runner/resources/app_icon.ico',
]) {
  if (!generator.includes(requiredText)) {
    failures.push(`${generatorPath}: missing generator target text "${requiredText}"`);
  }
}

for (const requiredText of [
  'assets/branding/nestarium_source.png',
  'assets/images/ui/app_logo.png',
  'tool/generate_brand_assets.dart',
  'windows/runner/resources/app_icon.ico',
  'owner approved the final three-style',
  'Commit `99bd909`',
  'Platform-specific visual inspection',
]) {
  if (!readiness.includes(requiredText)) {
    failures.push(`${readinessPath}: missing readiness text "${requiredText}"`);
  }
}

if (!roadmap.includes('[x] Approve the final Nestarium logo and regenerate platform branding assets.')) {
  failures.push(`${roadmapPath}: final logo approval gate is not marked complete`);
}

for (const requiredText of [
  'Final logo approved: yes',
  'Final logo and platform branding approval',
]) {
  if (!decisionPacket.includes(requiredText)) {
    failures.push(`${decisionPacketPath}: missing decision text "${requiredText}"`);
  }
}

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  `Platform branding audit: ${pngTargets.length} PNG targets and ${nonPngTargets.length} icon targets verified.`,
);
