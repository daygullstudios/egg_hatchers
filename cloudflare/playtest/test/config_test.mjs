import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

const configUrl = new URL("../wrangler.jsonc", import.meta.url);
const headersUrl = new URL("../../../web/_headers", import.meta.url);

test("playtest config cannot publish to a public preview URL", async () => {
  const config = JSON.parse(await readFile(configUrl, "utf8"));

  assert.equal(config.name, "egg-hatchers-playtest");
  assert.equal(config.workers_dev, false);
  assert.equal(config.preview_urls, false);
  assert.equal(config.routes, undefined);
  assert.deepEqual(config.assets, {
    directory: "../../build/web",
    not_found_handling: "single-page-application",
  });
  assert.equal(config.observability?.enabled, true);
});

test("private web responses carry the baseline hardening headers", async () => {
  const headers = await readFile(headersUrl, "utf8");

  assert.match(headers, /X-Frame-Options: DENY/);
  assert.match(headers, /X-Content-Type-Options: nosniff/);
  assert.match(headers, /X-Robots-Tag: noindex/);
  assert.match(headers, /Cache-Control: private, no-cache, must-revalidate/);
});
