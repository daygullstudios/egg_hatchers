import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

const configUrl = new URL("../wrangler.jsonc", import.meta.url);
const headersUrl = new URL("../../../web/_headers", import.meta.url);
const identityUrl = new URL("../deployment_identity.json", import.meta.url);

test("playtest publishes only to the Access-protected hostname", async () => {
  const config = JSON.parse(await readFile(configUrl, "utf8"));

  assert.equal(config.name, "egg-hatchers-playtest");
  assert.equal(config.workers_dev, false);
  assert.equal(config.preview_urls, false);
  assert.deepEqual(config.routes, [
    {
      pattern: "egg-hatchers-playtest.daygullstudios.com",
      custom_domain: true,
    },
  ]);
  assert.deepEqual(config.assets, {
    directory: "../../build/web",
    not_found_handling: "single-page-application",
  });
  assert.equal(config.observability?.enabled, true);
});

test("Nestarium's staged domain cannot be exposed by an ordinary deployment", async () => {
  const config = JSON.parse(await readFile(configUrl, "utf8"));
  const identity = JSON.parse(await readFile(identityUrl, "utf8"));
  assert.equal(identity.productName, "Nestarium");
  assert.equal(identity.publicDomain, "playnestarium.com");
  assert.equal(identity.stagedHostnameRouted, false);
  assert.equal(identity.accessEagerRedirectCookie, false);
  assert.equal(config.name, identity.workerName);
  assert.deepEqual(config.routes.map(route => route.pattern), [identity.activePlaytestHostname]);
  assert.ok(!config.routes.some(route => route.pattern.includes(identity.publicDomain)));
  const html = await readFile(new URL("../../../web/index.html", import.meta.url), "utf8");
  const manifest = JSON.parse(await readFile(new URL("../../../web/manifest.json", import.meta.url), "utf8"));
  assert.match(html, /<title>Nestarium<\/title>/);
  assert.equal(manifest.name, identity.productName);
  assert.equal(manifest.short_name, identity.productName);
});

test("private web responses carry the baseline hardening headers", async () => {
  const headers = await readFile(headersUrl, "utf8");

  assert.match(headers, /X-Frame-Options: DENY/);
  assert.match(headers, /X-Content-Type-Options: nosniff/);
  assert.match(headers, /X-Robots-Tag: noindex/);
  assert.match(headers, /Cache-Control: private, no-cache, must-revalidate/);
});
