# Egg Hatchers private web playtest

This directory is the checked-in Cloudflare delivery boundary for the compiled
Flutter web game. It follows the proven Railcade shape while the current Egg
Hatchers name remains an internal migration label.

The initial configuration is deliberately unreachable: `workers_dev` and
preview URLs are disabled, and no route or custom domain is checked in. A dry
run can validate and package the release build without publishing it. Do not
add a route or deploy until the playtest hostname and its Cloudflare Access
application are ready.

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

The dry run does not create or update a Cloudflare Worker. The `deploy` script
exists for the later approved playtest release, after Wrangler CLI
authentication and the external setup gates below are complete.

## External setup gates before first deployment

1. Choose a private playtest hostname. This does not need to be the final
   public product name, but it must be intentionally selected.
2. Create a self-hosted Cloudflare Access application for that exact hostname.
3. Add an allow policy containing the owner and approved testers only.
4. Add the custom-domain route to `wrangler.jsonc`, keep `workers_dev` and
   preview URLs disabled, then re-run the test, web build, and dry run.
5. Deploy and verify that an unauthenticated browser is redirected to Access
   while an approved identity reaches the game.

Never place Cloudflare API tokens, Firebase credentials, Access assertions, or
tester email lists in this directory or in the Flutter web bundle.
