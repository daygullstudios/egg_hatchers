import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile, readdir } from 'node:fs/promises';
import { join } from 'node:path';
import { build, root, output, pages, sources } from './build.mjs';
import { verifyRelease } from './verify-release.mjs';

await build();
const html = new Map(await Promise.all(pages.map(async page => [page, await readFile(join(output, page), 'utf8')])));
const config = JSON.parse(await readFile(join(root, 'wrangler.jsonc'), 'utf8'));

test('public output is exactly the explicit allowlist, with no game assets', async () => {
  assert.deepEqual((await readdir(output)).sort(), [...sources.keys()].sort());
  for (const name of sources.keys()) assert.doesNotMatch(name, /\.js$|\.wasm$|\.json$|\.map$|service.worker|flutter/i);
  assert.equal(config.assets.directory, '../../build/nestarium-public-site');
  assert.equal(config.assets.not_found_handling, '404-page');
});

test('copied brand artwork is byte-identical to the approved game asset', async () => {
  for (const name of ['brand.png', 'favicon.png']) {
    assert.deepEqual(await readFile(join(output, name)), await readFile(sources.get(name)));
  }
});

test('every page has basic document accessibility, titles and draft/no-index markers', () => {
  for (const [name, content] of html) {
    assert.match(content, /<html lang="en">/, name);
    assert.match(content, /name="viewport"/, name);
    assert.match(content, /<title>[^<]*Nestarium[^<]*<\/title>/, name);
    assert.match(content, /name="description" content="[^"]+"/, name);
    assert.match(content, /name="robots" content="noindex, nofollow"/, name);
    assert.match(content, /data-review-draft/, name);
    assert.equal((content.match(/<h1\b/g) || []).length, 1, name);
    assert.match(content, /<main\b/, name);
    if (name !== '404.html') assert.match(content, /class="skip" href="#main"/, name);
  }
});

test('local links resolve and contact links use only approved role addresses', () => {
  for (const [name, content] of html) {
    for (const [, link] of content.matchAll(/(?:href|src)="([^"]+)"/g)) {
      if (link.startsWith('#')) {
        assert.ok(content.includes(`id="${link.slice(1)}"`), `${name}: ${link}`);
      } else if (link.startsWith('mailto:')) {
        assert.ok(['support@playnestarium.com', 'legal@daygullstudios.com'].includes(link.slice(7).split('?')[0]), link);
      } else if (link.startsWith('https://')) {
        assert.ok(['playnestarium.com', 'daygullstudios.com'].includes(new URL(link).hostname), link);
      } else {
        assert.ok(link.startsWith('/') && !link.startsWith('//'), link);
        const file = link === '/' ? 'index.html' : link.slice(1);
        assert.ok(sources.has(file) || sources.has(`${file}.html`), `${name}: ${link}`);
      }
    }
  }
});

test('no script, form, tracker, credential or private-playtest linkage in pages', () => {
  for (const [name, content] of html) {
    assert.doesNotMatch(content, /<(?:script|iframe|form)\b|\bon\w+\s*=|javascript:|\.workers\.dev|firebaseapp\.com|main\.dart|flutter_bootstrap|https?:\/\/[^"<\s]*playtest\.|egg.hatchers|@gmail\.com/i, name);
  }
});

test('CSP blocks scripts and submissions; draft robots stay closed', async () => {
  const headers = await readFile(join(output, '_headers'), 'utf8');
  assert.match(headers, /default-src 'none'/);
  assert.match(headers, /form-action 'none'/);
  assert.match(headers, /frame-ancestors 'none'/);
  assert.match(headers, /X-Robots-Tag: noindex, nofollow/);
  assert.match(await readFile(join(output, 'robots.txt'), 'utf8'), /Disallow: \/\s*$/);
});

test('support accurately distinguishes local deletion, cloud sync and recovery', () => {
  assert.match(html.get('support.html'), /does not delete Firebase identity or cloud records/);
  assert.match(html.get('delete-account.html'), /does not delete Firebase Authentication or Firestore records/);
  assert.match(html.get('support.html'), /Google linking and cross-device account recovery are not enabled/);
  assert.match(html.get('support.html'), /Import replaces the destination/);
  assert.match(html.get('privacy.html'), /AUDIENCE_REVIEW_REQUIRED/);
});

test('draft cannot be deployed, and alternate public aliases remain disabled', async () => {
  assert.equal(config.workers_dev, false);
  assert.equal(config.preview_urls, false);
  assert.deepEqual(config.routes, []);
  await assert.rejects(verifyRelease(), /Publication blocked: audienceDecisionRecorded/);
});

test('public configuration does not change the protected game route', async () => {
  const playtest = JSON.parse(await readFile(join(root, '../playtest/wrangler.jsonc'), 'utf8'));
  assert.notEqual(config.name, playtest.name);
  assert.equal(playtest.assets.directory, '../../build/web');
  assert.deepEqual(playtest.routes, [{ pattern: 'egg-hatchers-playtest.daygullstudios.com', custom_domain: true }]);
});
