import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile, readdir } from 'node:fs/promises';
import { join } from 'node:path';
import { build, root, output, pages, sources } from './build.mjs';
import { verifyRelease } from './verify-release.mjs';

await build();
const html = new Map(await Promise.all(pages.map(async page => [page, await readFile(join(output, page), 'utf8')])));
const config = JSON.parse(await readFile(join(root, 'wrangler.jsonc'), 'utf8'));

test('public output is the exact allowlist and contains no game bundle', async () => {
  assert.deepEqual((await readdir(output)).sort(), [...sources.keys()].sort());
  for (const name of sources.keys()) assert.doesNotMatch(name, /\.js$|\.wasm$|\.json$|\.map$|service.worker|flutter/i);
  assert.equal(config.assets.directory, '../../build/nestarium-public-site');
  assert.equal(config.assets.not_found_handling, '404-page');
});

test('marketing artwork is copied byte-for-byte from owned game assets', async () => {
  for (const name of ['brand.png', 'favicon.png', 'chicken.png', 'cloud-bunny.png', 'dragon.png', 'cosmic-phoenix.png', 'basic-egg.png', 'magic-egg.png', 'space-egg.png']) {
    assert.deepEqual(await readFile(join(output, name)), await readFile(sources.get(name)), name);
  }
});

test('pages are accessible, titled, and ready for the public information site', () => {
  for (const [name, content] of html) {
    assert.match(content, /<html lang="en">/, name);
    assert.match(content, /name="viewport"/, name);
    assert.match(content, /<title>[^<]*Nestarium[^<]*<\/title>/, name);
    assert.match(content, /name="description" content="[^"]+"/, name);
    assert.equal((content.match(/<h1\b/g) || []).length, 1, name);
    assert.match(content, /<main\b/, name);
    assert.doesNotMatch(content, /data-review-draft|AUDIENCE_REVIEW_REQUIRED|noindex, nofollow/, name);
    if (name !== '404.html') assert.match(content, /class="skip" href="#main"/, name);
  }
});

test('homepage is indexable, preview-rich, and offers one-time launch notice mail', () => {
  const home = html.get('index.html');
  assert.match(home, /index,follow,max-image-preview:large/);
  assert.match(home, /Coming to iOS, Android, and web/);
  assert.match(home, /Get one launch notice/);
  assert.match(home, /mailto:launch@playnestarium\.com/);
  assert.match(home, /chicken\.png|cloud-bunny\.png/);
  assert.match(home, /og:image/);
  assert.doesNotMatch(home, /public downloads are not available|Review preview/);
});

test('local links resolve and mail links use only approved role addresses', () => {
  for (const [name, content] of html) {
    for (const [, link] of content.matchAll(/(?:href|src)="([^"]+)"/g)) {
      if (link.startsWith('#')) assert.ok(content.includes(`id="${link.slice(1)}"`), `${name}: ${link}`);
      else if (link.startsWith('mailto:')) assert.ok(['support@playnestarium.com', 'launch@playnestarium.com', 'legal@daygullstudios.com'].includes(link.slice(7).split('?')[0]), link);
      else if (link.startsWith('https://')) assert.ok(['playnestarium.com', 'daygullstudios.com'].includes(new URL(link).hostname), link);
      else {
        assert.ok(link.startsWith('/') && !link.startsWith('//'), link);
        const file = link === '/' ? 'index.html' : link.slice(1);
        assert.ok(sources.has(file) || sources.has(`${file}.html`), `${name}: ${link}`);
      }
    }
  }
});

test('no scripts, forms, trackers, credentials, or playtest links are published', () => {
  for (const [name, content] of html) {
    assert.doesNotMatch(content, /<(?:script|iframe|form)\b|\bon\w+\s*=|javascript:|\.workers\.dev|firebaseapp\.com|main\.dart|flutter_bootstrap|https?:\/\/[^"<\s]*playtest\.|egg.hatchers|@gmail\.com/i, name);
  }
});

test('security headers fail closed while crawlers can index public pages', async () => {
  const headers = await readFile(join(output, '_headers'), 'utf8');
  assert.match(headers, /default-src 'none'/);
  assert.match(headers, /form-action 'none'/);
  assert.match(headers, /frame-ancestors 'none'/);
  assert.doesNotMatch(headers, /X-Robots-Tag: noindex/);
  assert.match(await readFile(join(output, 'robots.txt'), 'utf8'), /Allow: \/|sitemap\.xml/);
  assert.match(await readFile(join(output, 'sitemap.xml'), 'utf8'), /playnestarium\.com\/support/);
});

test('support and privacy explain current recovery, deletion, and family boundaries', () => {
  assert.match(html.get('support.html'), /Removing a local player does not automatically delete cloud records/);
  assert.match(html.get('delete-account.html'), /does not delete Firebase Authentication or Firestore records/);
  assert.match(html.get('privacy.html'), /children, teens, and adults/);
  assert.match(html.get('privacy.html'), /limited private test, not a publicly released child-directed service/);
  assert.match(html.get('privacy.html'), /updated disclosures before launch/);
});

test('release gate approves only the public apex and never the protected game', async () => {
  assert.equal(config.workers_dev, false);
  assert.equal(config.preview_urls, false);
  assert.deepEqual(config.routes, [{ pattern: 'playnestarium.com', custom_domain: true }]);
  await assert.doesNotReject(verifyRelease());
  const playtest = JSON.parse(await readFile(join(root, '../playtest/wrangler.jsonc'), 'utf8'));
  assert.notEqual(config.name, playtest.name);
  assert.deepEqual(playtest.routes, [
    { pattern: 'egg-hatchers-playtest.daygullstudios.com', custom_domain: true },
    { pattern: 'playtest.playnestarium.com', custom_domain: true },
  ]);
});
