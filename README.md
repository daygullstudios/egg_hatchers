# Nestarium

Nestarium is a Flutter idle collection and battle game with three art styles,
boss fights, custom sprites and eggs, local player profiles, and live multiplayer
battles and trading.

The selected public domain is **playnestarium.com**. The current private game
continues at [the protected playtest](https://egg-hatchers-playtest.daygullstudios.com/)
while the new hostname completes its release gates. Existing players should
keep using that origin and retain an exported save; refreshing there preserves
their current browser storage and account session.

See [the Nestarium migration record](docs/NESTARIUM_MIGRATION.md) and
[the generated compatibility inventory](docs/LEGACY_BRAND_REFERENCES.json).
The repository, private Dart package, and persisted technical identifiers keep
their original names for compatibility; the product name is Nestarium.

## Run the game

### Importing a save safely

In web Settings > Account & Saves, export a backup first, then choose Import Save.
Review the file's players and progress before continuing to **Import & restart**.
This replaces all local players, settings and custom art; it does not merge saves,
transfer a Google sign-in, or delete cloud accounts. Close every other game tab,
including older versions. Updated tabs block replacement while they remain open.
The replacement happens at restart, before game/cloud services start, with a
checked temporary recovery copy. If recovery pauses, keep browser data and retry;
do not clear storage. The temporary recovery copy is not a permanent backup.
Existing-format exports remain supported. Import requires a current browser with
Web Locks; normal play remains available without that API.

The browser-only regression suite can be run on Windows Flutter 3.47.2 with:

```powershell
node tool/test_save_import_browser.mjs C:/path/to/pinned/flutter/bin/flutter.bat
```

That test-only adapter serves the pinned SDK's renderer into the disposable test
browser to work around the Windows test-server CanvasKit path/404 issue. It does
not change the SDK, production renderer, or personal browser data.

### Local development

```powershell
flutter pub get
flutter run -d chrome
```

## Run multiplayer locally

Start the WebSocket server in a separate terminal:

```powershell
dart run tool/multiplayer_server.dart
```

For a hosted server, bind to every network interface and use the host's port:

```powershell
dart run tool/multiplayer_server.dart --host 0.0.0.0 --port 8080
```

The server also reads the standard `HOST`, `PORT`, and `WEB_ROOT` environment
variables used by managed hosting services. Command-line options take priority.
`NESTARIUM_HOST`, `NESTARIUM_PORT`, and `NESTARIUM_WEB_ROOT` also work, with the
previous `EGG_HATCHERS_*` options retained as fallbacks. The Dart define
`NESTARIUM_SERVER_URL` similarly retains `EGG_HATCHERS_SERVER_URL` as a fallback.

Every successful GitHub `main` build creates a `nestarium-linux-x64`
deployment artifact. Extract it on a Linux host and start the bundled server:

```bash
HOST=0.0.0.0 PORT=8080 ./nestarium-server
```

The bundle keeps the web release in `build/web`, so the same process serves the
game, health endpoint, matchmaking, battles, and trading.

## Deploy the beta on Render

This is an optional future deployment recipe, not the active playtest. Do not
create or expose a Render service as part of an ordinary playtest update. If an
older Blueprint was linked externally, review its service identity before
applying the renamed recipe.

The included `Dockerfile` packages the web game and multiplayer server in one
non-root container. `render.yaml` configures a free beta service in Render's
Ohio region with automatic `/health` checks.

In Render, create a new Blueprint and connect this GitHub repository. Render
will read `render.yaml`, build the container, and provide a public HTTPS address.
The game automatically uses the matching secure WebSocket address at `/ws`.

The free service is suitable for testing, but its active rooms remain in memory
and can be interrupted when the service sleeps or redeploys. Durable accounts
and trades still require a database-backed production server.

The server listens at `http://127.0.0.1:53218`, serves the release web build
from `build/web`, and handles multiplayer at `/ws`. Native builds default to
`ws://127.0.0.1:53218/ws`; supply a reachable server for device builds:

```powershell
flutter run --dart-define=NESTARIUM_SERVER_URL=wss://your-server.example
```

## Verify a change

```powershell
flutter analyze
flutter test
flutter build web --release
node tool/audit_brand.mjs
```

## Sign the Android release

Local release builds use Android's debug key when no private signing setup is
present. Before publishing, create an upload keystore, copy
`android/key.properties.example` to `android/key.properties`, and replace every
example value. Both the credentials file and keystore are ignored by Git.

Confirm the private signing setup before uploading:

```powershell
flutter build appbundle --release
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

The development multiplayer server stores active rooms in memory. A public
release still requires durable hosted accounts, authenticated sessions,
transactional trade storage, TLS, and platform signing credentials.

## Regenerate product artwork

Run `dart run tool/generate_brand_assets.dart` after an approved change to
`assets/branding/nestarium_source.png`. It exports the in-app mark, web/PWA,
Android/iOS launchers and splash screens, macOS icons, and Windows ICO at their
existing dimensions. Animal/egg gameplay art and IDs are independent of the
product name.
