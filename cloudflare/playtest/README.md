# Egg Hatchers private web playtest

This directory is the checked-in Cloudflare delivery boundary for the compiled
Flutter web game. It follows the proven Railcade shape while the current Egg
Hatchers name remains an internal migration label.

The current configuration is deliberately unreachable: `workers_dev` and
preview URLs are disabled, and no route or custom domain is checked in. The
verified release assets have been uploaded as Worker version
`38e9ca2e-94d3-4b68-a960-c38c76bf6dd6`, but Cloudflare reports **No targets
deployed**, so there is no public game URL yet.

The temporary private hostname is
`egg-hatchers-playtest.daygullstudios.com`. It is intentionally beneath the
studio domain so the final product-name decision remains independent. Do not
attach that hostname until its Cloudflare Access application and allow policy
exist.

## Release boundary

- Flutter produces the shared web client in `build/web`.
- Cloudflare Workers Static Assets serves that directory as a single-page app.
- `web/_headers` keeps the private build out of search results and applies the
  browser hardening that does not conflict with Flutter.
- Firebase will own protected identity and durable progress. Cloudflare does
  not become a second save database.
- A later multiplayer Worker or Durable Object must be a separate service from
  this static-delivery project.

## Local verification

From this directory:

```powershell
npm test
npm run build:web
npm run deploy:dry-run
```

The dry run does not create or update a Cloudflare Worker. `npm run deploy`
uploads a new version; with the checked-in no-target configuration it still
does not expose a URL.

## External setup gates before first deployment

1. Create a self-hosted Cloudflare Access application for
   `egg-hatchers-playtest.daygullstudios.com`.
2. Attach Railcade's existing reusable approved-tester allow policy.
3. Add the custom-domain route to `wrangler.jsonc`, keep `workers_dev` and
   preview URLs disabled, then re-run the test, web build, and dry run.
4. Deploy and verify that an unauthenticated browser is redirected to Access
   while an approved identity reaches the game.

Never place Cloudflare API tokens, Firebase credentials, Access assertions, or
tester email lists in this directory or in the Flutter web bundle.
