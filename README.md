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

The development multiplayer server stores active rooms in memory. A public
release still requires durable hosted accounts, authenticated sessions,
transactional trade storage, TLS, and platform signing credentials.
