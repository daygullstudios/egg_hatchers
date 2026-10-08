import { readdirSync, readFileSync, statSync } from 'node:fs';
import { extname, join, resolve, relative } from 'node:path';

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

function listFilesRecursive(relativePath, extension) {
  const directory = resolve(root, relativePath);
  const files = [];
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const absolutePath = join(directory, entry.name);
    const repositoryPath = relative(root, absolutePath).replaceAll('\\', '/');
    if (entry.isDirectory()) {
      files.push(...listFilesRecursive(repositoryPath, extension));
    } else if (extname(entry.name).toLowerCase() === extension) {
      files.push(repositoryPath);
    }
  }
  return files.sort();
}

function readWavStats(relativePath) {
  const buffer = readFileSync(resolve(root, relativePath));
  if (buffer.toString('ascii', 0, 4) !== 'RIFF' || buffer.toString('ascii', 8, 12) !== 'WAVE') {
    throw new Error(`${relativePath}: not a RIFF/WAVE file`);
  }

  let offset = 12;
  let format;
  let channels;
  let sampleRate;
  let byteRate;
  let blockAlign;
  let bitsPerSample;
  let dataStart;
  let dataSize;
  while (offset + 8 <= buffer.length) {
    const chunkId = buffer.toString('ascii', offset, offset + 4);
    const chunkSize = buffer.readUInt32LE(offset + 4);
    const chunkStart = offset + 8;
    if (chunkId === 'fmt ') {
      format = buffer.readUInt16LE(chunkStart);
      channels = buffer.readUInt16LE(chunkStart + 2);
      sampleRate = buffer.readUInt32LE(chunkStart + 4);
      byteRate = buffer.readUInt32LE(chunkStart + 8);
      blockAlign = buffer.readUInt16LE(chunkStart + 12);
      bitsPerSample = buffer.readUInt16LE(chunkStart + 14);
    } else if (chunkId === 'data') {
      dataStart = chunkStart;
      dataSize = chunkSize;
      break;
    }
    offset = chunkStart + chunkSize + (chunkSize % 2);
  }

  if (!format || !channels || !sampleRate || !byteRate || !blockAlign || !bitsPerSample || !dataStart || !dataSize) {
    throw new Error(`${relativePath}: missing wav format or data chunk`);
  }
  if (![1, 3].includes(format)) {
    throw new Error(`${relativePath}: unsupported wav format ${format}`);
  }
  if (format === 3 && bitsPerSample !== 32) {
    throw new Error(`${relativePath}: unsupported float wav bit depth ${bitsPerSample}`);
  }
  if (format === 1 && ![8, 16, 24, 32].includes(bitsPerSample)) {
    throw new Error(`${relativePath}: unsupported PCM wav bit depth ${bitsPerSample}`);
  }

  const bytesPerSample = bitsPerSample / 8;
  let sampleCount = 0;
  let peak = 0;
  let sumSquares = 0;
  let clippingSamples = 0;
  for (let frameOffset = dataStart; frameOffset + blockAlign <= dataStart + dataSize; frameOffset += blockAlign) {
    for (let channel = 0; channel < channels; channel += 1) {
      const sampleOffset = frameOffset + channel * bytesPerSample;
      let sample;
      if (format === 3) {
        sample = buffer.readFloatLE(sampleOffset);
      } else if (bitsPerSample === 8) {
        sample = (buffer.readUInt8(sampleOffset) - 128) / 128;
      } else if (bitsPerSample === 16) {
        sample = buffer.readInt16LE(sampleOffset) / 32768;
      } else if (bitsPerSample === 24) {
        let value =
          buffer[sampleOffset] |
          (buffer[sampleOffset + 1] << 8) |
          (buffer[sampleOffset + 2] << 16);
        if ((value & 0x800000) !== 0) {
          value |= 0xff000000;
        }
        sample = value / 8388608;
      } else {
        sample = buffer.readInt32LE(sampleOffset) / 2147483648;
      }

      const absoluteSample = Math.abs(sample);
      if (!Number.isFinite(absoluteSample)) {
        throw new Error(`${relativePath}: non-finite wav sample`);
      }
      if (absoluteSample >= 0.999) {
        clippingSamples += 1;
      }
      peak = Math.max(peak, absoluteSample);
      sumSquares += sample * sample;
      sampleCount += 1;
    }
  }

  return {
    durationMicros: Math.floor((dataSize / byteRate) * 1000000),
    peak,
    rms: Math.sqrt(sumSquares / sampleCount),
    clippingSamples,
    sampleCount,
  };
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

const bossMusicStats = readWavStats('assets/sounds/music/boss_music.wav');
const bossDuration = bossMusicStats.durationMicros;
const finalLoopEnd = expectedBossMarkers.at(-1).loopEnd;
if (bossDuration + 1000 < finalLoopEnd) {
  failures.push(
    `assets/sounds/music/boss_music.wav: duration ${bossDuration}us is shorter than final loop end ${finalLoopEnd}us`,
  );
}

const wavFiles = listFilesRecursive('assets/sounds', '.wav');
for (const relativePath of wavFiles) {
  const stats = relativePath === 'assets/sounds/music/boss_music.wav'
    ? bossMusicStats
    : readWavStats(relativePath);
  if (stats.sampleCount <= 0) {
    failures.push(`${relativePath}: contains no decoded wav samples`);
  }
  if (stats.peak < 0.001 || stats.rms < 0.0005) {
    failures.push(`${relativePath}: appears silent or too quiet for a shipped release asset`);
  }
  if (stats.peak > 1 || stats.clippingSamples > 0) {
    failures.push(`${relativePath}: contains clipped wav samples`);
  }
  if (stats.rms > 0.5) {
    failures.push(`${relativePath}: RMS level ${stats.rms.toFixed(3)} is unusually loud`);
  }
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
  'Automated WAV normalization guardrail',
  'Release SFX mix scales',
  'releaseVolumeScale',
  'AudioService.effectiveSfxVolume',
  'Owner listening approval',
  'Volume normalization approval',
  'Platform audio behavior checks',
  'Source/license confirmation',
]) {
  if (!checklist.includes(phrase)) {
    failures.push(`${checklistPath}: missing release audio phrase "${phrase}"`);
  }
}

if (!registry.includes('releaseVolumeScale')) {
  failures.push(`${audioRegistryPath}: missing release SFX mix scales`);
}
if (!audioService.includes('effectiveSfxVolume')) {
  failures.push(`${audioServicePath}: missing release SFX volume helper`);
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
  `Audio release audit: ${requiredMusic.length} music tracks, ${expectedBossMarkers.length} boss sections and ${wavFiles.length} WAV loudness checks verified.`,
);
