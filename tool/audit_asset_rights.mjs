import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const auditPath = 'docs/ASSET_RIGHTS_RELEASE_AUDIT.md';
const soundSourcesPath = 'assets/sounds/SOURCES.md';
const audioRegistryPath = 'lib/data/audio_assets.dart';
const pubspecPath = 'pubspec.yaml';

const audit = readFileSync(resolve(root, auditPath), 'utf8');
const soundSources = readFileSync(resolve(root, soundSourcesPath), 'utf8');
const audioRegistry = readFileSync(resolve(root, audioRegistryPath), 'utf8');
const pubspec = readFileSync(resolve(root, pubspecPath), 'utf8');

const mediaExtensions = new Set([
  '.png',
  '.jpg',
  '.jpeg',
  '.webp',
  '.gif',
  '.mp3',
  '.wav',
  '.ogg',
]);

const inventoryRoots = [
  'assets/images/animals/',
  'assets/images/animal_themes/retro_pixel/',
  'assets/images/animal_themes/realistic/',
  'assets/images/eggs/',
  'assets/images/egg_themes/retro_pixel/',
  'assets/images/egg_themes/realistic/',
  'assets/images/bosses/',
  'assets/images/boss_backgrounds/realistic/',
  'assets/images/hatched_egg_heads/',
  'assets/images/projectiles/',
  'assets/images/ui/',
  'assets/sounds/music/',
  'assets/sounds/sfx/',
];

function mediaFileCount(relativeDir) {
  const absoluteDir = resolve(root, relativeDir);
  let count = 0;
  const stack = [absoluteDir];
  while (stack.length > 0) {
    const current = stack.pop();
    for (const entry of readdirSync(current, { withFileTypes: true })) {
      const absolute = join(current, entry.name);
      if (entry.isDirectory()) {
        stack.push(absolute);
        continue;
      }
      if (!entry.isFile()) continue;
      const dot = entry.name.lastIndexOf('.');
      const extension = dot === -1 ? '' : entry.name.slice(dot).toLowerCase();
      if (mediaExtensions.has(extension)) count += 1;
    }
  }
  return count;
}

const failures = [];

for (const relativeDir of inventoryRoots) {
  const count = mediaFileCount(relativeDir);
  const expectedLine = `- \`${relativeDir}\` - ${count} ${count === 1 ? 'file' : 'files'}.`;
  if (!audit.includes(expectedLine)) {
    failures.push(`${auditPath}: expected inventory line "${expectedLine}"`);
  }
  if (!pubspec.includes(`- ${relativeDir}`)) {
    failures.push(`${pubspecPath}: missing Flutter asset root ${relativeDir}`);
  }
}

for (const relativeDir of [
  'assets/images/hatched_egg_heads/classic/',
  'assets/images/hatched_egg_heads/retroPixel/',
  'assets/images/mutations/',
]) {
  if (!pubspec.includes(`- ${relativeDir}`)) {
    failures.push(`${pubspecPath}: missing Flutter asset root ${relativeDir}`);
  }
}

const registeredAudio = new Set(
  [...audioRegistry.matchAll(/'sounds\/(?:music|sfx)\/[^']+\.(?:mp3|wav|ogg)'/g)].map(
    (match) => `assets/${match[0].slice(1, -1)}`,
  ),
);

for (const relativePath of registeredAudio) {
  if (!statSync(resolve(root, relativePath)).isFile()) {
    failures.push(`${audioRegistryPath}: registered missing audio asset ${relativePath}`);
  }
  if (relativePath.startsWith('assets/sounds/music/') && !audit.includes(relativePath)) {
    failures.push(`${auditPath}: missing music rights blocker for ${relativePath}`);
  }
}

const shippedAudio = new Set();
for (const relativeDir of ['assets/sounds/music/', 'assets/sounds/sfx/']) {
  const absoluteDir = resolve(root, relativeDir);
  for (const entry of readdirSync(absoluteDir, { withFileTypes: true })) {
    if (!entry.isFile()) continue;
    const relativePath = `${relativeDir}${entry.name}`;
    if (mediaExtensions.has(entry.name.slice(entry.name.lastIndexOf('.')).toLowerCase())) {
      shippedAudio.add(relativePath);
    }
  }
}

for (const relativePath of shippedAudio) {
  if (!registeredAudio.has(relativePath)) {
    failures.push(`${audioRegistryPath}: shipped audio is not registered: ${relativePath}`);
  }
}

const externalEffects = [
  'assets/sounds/sfx/purchase_real.mp3',
  'assets/sounds/sfx/finisher_slash_real.mp3',
  'assets/sounds/sfx/egg_crack_reference.mp3',
];

for (const relativePath of externalEffects) {
  if (!audit.includes(relativePath)) {
    failures.push(`${auditPath}: missing external sound record for ${relativePath}`);
  }
  if (!soundSources.includes(relativePath.replace('assets/sounds/', ''))) {
    failures.push(`${soundSourcesPath}: missing source details for ${relativePath}`);
  }
}

const auditLower = audit.toLowerCase();
for (const phrase of [
  'need owner confirmation',
  'Suno, BandLab, or another music tool',
  'commercial rights and source records',
]) {
  if (!auditLower.includes(phrase.toLowerCase())) {
    failures.push(`${auditPath}: missing release-blocking phrase "${phrase}"`);
  }
}

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  `Asset rights audit: ${inventoryRoots.length} media roots and ${registeredAudio.size} audio assets verified.`,
);
