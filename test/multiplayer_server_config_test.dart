import 'package:flutter_test/flutter_test.dart';

import '../tool/multiplayer_server.dart';

void main() {
  test('Nestarium environment names win while legacy names remain usable', () {
    const legacy = {
      'EGG_HATCHERS_HOST': 'legacy-host',
      'EGG_HATCHERS_PORT': '9001',
      'EGG_HATCHERS_WEB_ROOT': 'legacy-web',
    };
    final old = MultiplayerServerConfig.fromArgs([], environment: legacy);
    expect(
      (old.host, old.port, old.webRoot),
      ('legacy-host', 9001, 'legacy-web'),
    );
    final renamed = MultiplayerServerConfig.fromArgs(
      [],
      environment: {
        ...legacy,
        'NESTARIUM_HOST': 'new-host',
        'NESTARIUM_PORT': '9002',
        'NESTARIUM_WEB_ROOT': 'new-web',
      },
    );
    expect(
      (renamed.host, renamed.port, renamed.webRoot),
      ('new-host', 9002, 'new-web'),
    );
  });

  test('server config uses local defaults', () {
    final config = MultiplayerServerConfig.fromArgs(const []);

    expect(config.host, '127.0.0.1');
    expect(config.port, 53218);
    expect(config.webRoot, 'build/web');
  });

  test('server config reads common hosting environment values', () {
    final config = MultiplayerServerConfig.fromArgs(
      const [],
      environment: const {
        'HOST': '0.0.0.0',
        'PORT': '8080',
        'WEB_ROOT': '/app/public',
      },
    );

    expect(config.host, '0.0.0.0');
    expect(config.port, 8080);
    expect(config.webRoot, '/app/public');
  });

  test('command-line values override the environment', () {
    final config = MultiplayerServerConfig.fromArgs(
      const ['--host=localhost', '--port', '9000', '--web-root', 'site'],
      environment: const {'HOST': '0.0.0.0', 'PORT': '8080'},
    );

    expect(config.host, 'localhost');
    expect(config.port, 9000);
    expect(config.webRoot, 'site');
  });

  test('server config rejects invalid options and ports', () {
    expect(
      () => MultiplayerServerConfig.fromArgs(const ['--port', 'nope']),
      throwsFormatException,
    );
    expect(
      () => MultiplayerServerConfig.fromArgs(const ['--unknown', 'value']),
      throwsFormatException,
    );
  });
}
