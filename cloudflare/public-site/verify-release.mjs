import { readFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { root, pages } from './build.mjs';

export async function verifyRelease() {
  const readiness = JSON.parse(await readFile(join(root, 'release-readiness.json'), 'utf8'));
  const required = ['audienceDecisionRecorded', 'policyAndSupportCopyApproved', 'supportDeliveryAndReplyVerified', 'hostnameAndHeadersVerified'];
  const missing = required.filter(key => readiness[key] !== true);
  if (missing.length) throw new Error(`Publication blocked: ${missing.join(', ')}. Record verified evidence before changing these gates.`);
  const config = JSON.parse(await readFile(join(root, 'wrangler.jsonc'), 'utf8'));
  if (config.workers_dev !== false || config.preview_urls !== false ||
      JSON.stringify(config.routes) !== JSON.stringify([{ pattern: 'playnestarium.com', custom_domain: true }])) {
    throw new Error('Publication requires only the reviewed public apex route; no playtest routes or preview aliases.');
  }
  for (const page of pages) {
    if (/data-review-draft|AUDIENCE_REVIEW_REQUIRED/.test(await readFile(join(root, 'src', page), 'utf8'))) {
      throw new Error(`Publication blocked by unapproved draft: ${page}`);
    }
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  await verifyRelease();
  console.log('Public-site release gates passed. This does not authorize a playable hostname cutover.');
}
