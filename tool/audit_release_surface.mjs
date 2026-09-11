import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const bundlePath = resolve('build/web/main.dart.js');
let bundle;

try {
  bundle = readFileSync(bundlePath, 'utf8');
} catch (error) {
  throw new Error(
    `Release bundle not found at ${bundlePath}. Build web release first.`,
    { cause: error },
  );
}

const forbiddenReleaseMarkers = [
  'Developer Tools (Debug)',
  'Force Next Single Hatch',
  'Unlock Rotten Shell reqs',
  'Preview DayGull Unlock',
  'Collect All Animals',
];

const leakedMarkers = forbiddenReleaseMarkers.filter((marker) =>
  bundle.includes(marker),
);

if (leakedMarkers.length > 0) {
  throw new Error(
    `Developer-only controls leaked into the release bundle: ${leakedMarkers.join(', ')}`,
  );
}

console.log('Release surface audit: no developer-only controls found.');
