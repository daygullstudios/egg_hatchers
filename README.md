# Egg Hatchers

Egg Hatchers is a Flutter idle collection and battle game with three art styles,
boss fights, custom sprites and eggs, local player profiles, and live multiplayer
battles and trading.

## Run the game

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

Every successful GitHub `main` build creates an `egg-hatchers-linux-x64`
deployment artifact. Extract it on a Linux host and start the bundled server:

```bash
HOST=0.0.0.0 PORT=8080 ./egg-hatchers-server
```

The bundle keeps the web release in `build/web`, so the same process serves the
game, health endpoint, matchmaking, battles, and trading.

## Deploy the beta on Render

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
flutter run --dart-define=EGG_HATCHERS_SERVER_URL=wss://your-server.example
```

## Verify a change

```powershell
flutter analyze
flutter test
flutter build web --release
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
