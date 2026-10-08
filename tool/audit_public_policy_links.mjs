import { readFile, readdir } from 'node:fs/promises';
import { join } from 'node:path';
import {
  build,
  output,
  pages,
  root as publicSiteRoot,
  sources,
} from '../cloudflare/public-site/build.mjs';
import { verifyRelease } from '../cloudflare/public-site/verify-release.mjs';

await build();

const html = new Map(
  await Promise.all(
    pages.map(async (page) => [page, await readFile(join(output, page), 'utf8')]),
  ),
);

const expectedPages = [
  'index.html',
  'support.html',
  'privacy.html',
  'terms.html',
  'delete-account.html',
  '404.html',
];

const requiredRoutes = [
  '/',
  '/support',
  '/privacy',
  '/terms',
  '/delete-account',
];

const approvedMailboxes = new Set([
  'support@playnestarium.com',
  'launch@playnestarium.com',
  'legal@daygullstudios.com',
]);

const failures = [];

const outputFiles = (await readdir(output)).sort();
const expectedFiles = [...sources.keys()].sort();
if (JSON.stringify(outputFiles) !== JSON.stringify(expectedFiles)) {
  failures.push(
    `Public-site output changed. Expected ${expectedFiles.join(', ')}, got ${outputFiles.join(', ')}`,
  );
}

for (const page of expectedPages) {
  if (!html.has(page)) {
    failures.push(`Missing public policy/support page: ${page}`);
  }
}

for (const [page, content] of html) {
  if (!/<title>[^<]*Nestarium[^<]*<\/title>/.test(content)) {
    failures.push(`${page}: missing Nestarium title`);
  }
  if (!/<main\b/.test(content)) {
    failures.push(`${page}: missing main landmark`);
  }
  if (/<(?:script|iframe|form)\b|\bon\w+\s*=|javascript:|main\.dart|flutter_bootstrap|firebaseapp\.com|playtest\.playnestarium|egg-hatchers-playtest/i.test(content)) {
    failures.push(`${page}: contains active, private, or protected-game content`);
  }
  for (const [, link] of content.matchAll(/(?:href|src)="([^"]+)"/g)) {
    if (link.startsWith('#')) {
      if (!content.includes(`id="${link.slice(1)}"`)) {
        failures.push(`${page}: broken fragment link ${link}`);
      }
    } else if (link.startsWith('mailto:')) {
      const mailbox = link.slice(7).split('?')[0];
      if (!approvedMailboxes.has(mailbox)) {
        failures.push(`${page}: unapproved mailbox ${mailbox}`);
      }
    } else if (link.startsWith('https://')) {
      const { hostname } = new URL(link);
      if (!['playnestarium.com', 'daygullstudios.com'].includes(hostname)) {
        failures.push(`${page}: unapproved external host ${hostname}`);
      }
    } else {
      if (!link.startsWith('/') || link.startsWith('//')) {
        failures.push(`${page}: non-rooted local link ${link}`);
        continue;
      }
      const file = link === '/' ? 'index.html' : link.slice(1);
      if (!sources.has(file) && !sources.has(`${file}.html`)) {
        failures.push(`${page}: broken local link ${link}`);
      }
    }
  }
}

const support = html.get('support.html') ?? '';
const privacy = html.get('privacy.html') ?? '';
const deletion = html.get('delete-account.html') ?? '';
for (const [page, content, phrase] of [
  ['support.html', support, 'Delete cloud account to delete the active protected cloud account'],
  ['support.html', support, 'Removing a local player still does not delete cloud records by itself'],
  ['privacy.html', privacy, 'children, teens, and adults'],
  ['privacy.html', privacy, 'updated disclosures before launch'],
  ['delete-account.html', deletion, 'active Nestarium cloud account and synced cloud progress'],
]) {
  if (!content.includes(phrase)) {
    failures.push(`${page}: missing required disclosure "${phrase}"`);
  }
}

const sitemap = await readFile(join(output, 'sitemap.xml'), 'utf8');
for (const route of requiredRoutes) {
  if (!sitemap.includes(`https://playnestarium.com${route === '/' ? '/' : route}`)) {
    failures.push(`sitemap.xml: missing route ${route}`);
  }
}

const headers = await readFile(join(output, '_headers'), 'utf8');
for (const header of [
  "default-src 'none'",
  "form-action 'none'",
  "frame-ancestors 'none'",
]) {
  if (!headers.includes(header)) {
    failures.push(`_headers: missing ${header}`);
  }
}

try {
  await verifyRelease();
} catch (error) {
  failures.push(`Public-site release readiness failed: ${error.message}`);
}

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  `Public policy link audit: ${expectedPages.length} pages and ${requiredRoutes.length} routes verified from ${publicSiteRoot}.`,
);
