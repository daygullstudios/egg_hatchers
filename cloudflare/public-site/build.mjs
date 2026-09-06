import { copyFile, lstat, mkdir, readdir, readFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export const root = dirname(fileURLToPath(import.meta.url));
export const output = resolve(root, '../../build/nestarium-public-site');
export const pages = ['index.html', 'support.html', 'privacy.html', 'terms.html', 'delete-account.html', '404.html'];
export const sources = new Map([
  ...[...pages, 'site.css', '_headers', 'robots.txt'].map(name => [name, join(root, 'src', name)]),
  ['brand.png', resolve(root, '../../web/icons/Icon-512.png')],
  ['favicon.png', resolve(root, '../../web/favicon.png')],
]);

export async function build() {
  // Never copy build/web, arbitrary folders, or caller-supplied assets. The
  // public build has no game code, Firebase config, account state, or scripts.
  await mkdir(output, { recursive: true });
  if ((await lstat(output)).isSymbolicLink()) throw new Error('Output must not be a symlink.');
  for (const entry of await readdir(output)) {
    if (!sources.has(entry)) throw new Error(`Unexpected output file: ${entry}; inspect before publishing.`);
  }
  for (const [name, source] of sources) {
    if (!(await lstat(source)).isFile()) throw new Error(`Source must be a regular file: ${name}`);
    const destination = join(output, name);
    try {
      if (!(await lstat(destination)).isFile()) throw new Error(`Unsafe output target: ${name}`);
    } catch (error) {
      if (error.code !== 'ENOENT') throw error;
    }
    await copyFile(source, destination);
  }
  // Defense in depth: no active forms, scripts, embedded game, or legacy origin.
  for (const page of pages) {
    const html = await readFile(join(output, page), 'utf8');
    if (/<(?:script|iframe|form)\b|main\.dart|flutter_bootstrap|firebaseapp\.com|egg-hatchers-playtest|playtest\.playnestarium/i.test(html)) {
      throw new Error(`Private or active content is not allowed in ${page}.`);
    }
  }
  return output;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  await build();
  console.log(`Built ${sources.size} allowlisted public-site files. No deployment performed.`);
}
