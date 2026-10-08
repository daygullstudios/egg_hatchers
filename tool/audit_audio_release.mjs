import { readFileSync, statSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const audioRegistryPath = 'lib/data/audio_assets.dart';
const audioServicePath = 'lib/services/audio_service.dart';
const checklistPath = 'docs/AUDIO_RELEASE_ACCEPTANCE.md';
const visualAuditPath = 'docs/VISUAL_AUDIO_ACCESSIBILITY_AUDIT.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';

const registry = readFileSync(resolve(root, audioRegistryPath), 'utf8');
const audioService = readFileSync(resolve(root, audioServicePath), 'utf8');
const checklist = readFileSync(resolve(root, checklistPath), 'utf8');
const visualAudit = readFileSync(resolve(root, visualAuditPath), 'utf8');
const roadmap = readFileSync(resolve(root, roadmapPath), 'utf8');

const requiredMusic = [
  'assets/sounds/music/hatchery_chill_loop.mp3',
  'assets/sounds/music/boss_music.wav',
  'assets/sounds/music/final_boss_music.mp3',
];

const expectedBossMarkers = [
  {
    start: 0,
    loopStart: 1666667,
    loopEnd: 13333333,
    label: ['0:00.000', '0:01.667', '0:13.333'],
  },
  {
    start: 13333333,
    loopStart: 16666667,
    loopEnd: 26666667,
    label: ['0:13.333', '0:16.667', '0:26.667'],
  },
  {
    start: 26666667,
    loopStart: 30000000,
    loopEnd: 40000000,
    label: ['0:26.667', '0:30.000', '0:40.000'],
  },
  {
    start: 40000000,
    loopStart: 40000000,
    loopEnd: 66666667,
    label: ['0:40.000', '1:06.667'],
  },
];

const failures = [];

function wavDurationMicros(relativePath) {
  const buffer = readFileSync(resolve(root, relativePath));
  if (buffer.toString('ascii', 0, 4) !== 'RIFF' || buffer.toString('ascii', 8, 12) !== 'WAVE') {
    throw new Error(`${relativePath}: not a RIFF/WAVE file`);
  }

  let offset = 12;
  let byteRate;
  let dataSize;
  while (offset + 8 <= buffer.length) {
    const chunkId = buffer.toString('ascii', offset, offset + 4);
    const chunkSize = buffer.readUInt32LE(offset + 4);
    const chunkStart = offset + 8;
    if (chunkId === 'fmt ') {
      byteRate = buffer.readUInt32LE(chunkStart + 8);
    } else if (chunkId === 'data') {
      dataSize = chunkSize;
      break;
    }
    offset = chunkStart + chunkSize + (chunkSize % 2);
  }
  if (!byteRate || !dataSize) {
    throw new Error(`${relativePath}: missing wav byte rate or data chunk`);
  }
  return Math.floor((dataSize / byteRate) * 1000000);
}

for (const relativePath of requiredMusic) {
  const file = statSync(resolve(root, relativePath));
  if (!file.isFile()) {
    failures.push(`${relativePath}: missing release music file`);
    continue;
  }
  if (file.size <= 100 * 1024 || file.size >= 7 * 1024 * 1024) {
    failures.push(`${relativePath}: unexpected release music size ${file.size}`);
  }
  const registryPath = relativePath.replace('assets/', '');
  if (!registry.includes(`'${registryPath}'`)) {
    failures.push(`${audioRegistryPath}: missing registered music ${registryPath}`);
  }
  if (!checklist.includes(relativePath)) {
    failures.push(`${checklistPath}: missing release track ${relativePath}`);
  }
}

const bossDuration = wavDurationMicros('assets/sounds/music/boss_music.wav');
const finalLoopEnd = expectedBossMarkers.at(-1).loopEnd;
if (bossDuration + 1000 < finalLoopEnd) {
  failures.push(
    `assets/sounds/music/boss_music.wav: duration ${bossDuration}us is shorter than final loop end ${finalLoopEnd}us`,
  );
}

for (const section of expectedBossMarkers) {
  if (section.start === 0) {
    if (!audioService.includes('start: Duration.zero')) {
      failures.push(`${audioServicePath}: missing phase start Duration.zero`);
    }
  } else if (!audioService.includes(`start: Duration(microseconds: ${section.start})`)) {
    failures.push(`${audioServicePath}: missing phase start ${section.start}`);
  }
  if (!audioService.includes(`loopStart: Duration(microseconds: ${section.loopStart})`)) {
    failures.push(`${audioServicePath}: missing loopStart ${section.loopStart}`);
  }
  if (!audioService.includes(`loopEnd: Duration(microseconds: ${section.loopEnd})`)) {
    failures.push(`${audioServicePath}: missing loopEnd ${section.loopEnd}`);
  }
  for (const label of section.label) {
    if (!checklist.includes(label)) {
      failures.push(`${checklistPath}: missing boss phase label ${label}`);
    }
  }
}

for (const phrase of [
  'next section without intentionally restarting the whole track',
  'Owner listening approval',
  'Volume normalization approval',
  'Platform audio behavior checks',
  'Source/license confirmation',
]) {
  if (!checklist.includes(phrase)) {
    failures.push(`${checklistPath}: missing release audio phrase "${phrase}"`);
  }
}

for (const phrase of [
  'Boss phase music loop approval',
  'Music and SFX volume normalization',
  'Audio unlock, pause/resume and background/foreground behavior',
]) {
  if (!visualAudit.includes(phrase)) {
    failures.push(`${visualAuditPath}: missing visual/audio audit phrase "${phrase}"`);
  }
}

for (const item of [
  '[ ] Finalize boss phase music loops and all other music transitions.',
  '[ ] Normalize music and sound-effect volume.',
  '[ ] Verify audio unlock, pause/resume and background/foreground behavior on',
]) {
  if (!roadmap.includes(item)) {
    failures.push(`${roadmapPath}: audio approval gate is not open: ${item}`);
  }
}

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  `Audio release audit: ${requiredMusic.length} music tracks and ${expectedBossMarkers.length} boss sections verified.`,
);
