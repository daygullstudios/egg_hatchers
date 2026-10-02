import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release monitoring evidence keeps client telemetry out for now', () {
    final pubspec = File('pubspec.yaml').readAsStringSync().toLowerCase();
    final evidence = File(
      'docs/RELEASE_MONITORING_EVIDENCE.md',
    ).readAsStringSync();
    final familyRequirements = File(
      'docs/FAMILY_AUDIENCE_V1.md',
    ).readAsStringSync();

    const disallowedClientTelemetry = [
      'firebase_crashlytics',
      'firebase_analytics',
      'sentry_flutter',
      'appcenter',
      'mixpanel',
      'amplitude_flutter',
    ];

    for (final dependency in disallowedClientTelemetry) {
      expect(pubspec, isNot(contains(dependency)), reason: dependency);
    }

    expect(evidence, contains('Flutter client has no production crash'));
    expect(evidence, contains('Monitoring must support operations'));
    expect(evidence, contains('Do not'));
    expect(evidence, contains('intentionally log player profile payloads'));
    expect(
      familyRequirements,
      contains('Analytics and Crashlytics are not added.'),
    );
  });

  test('release monitoring evidence matches protected Worker observability', () {
    final evidence = File(
      'docs/RELEASE_MONITORING_EVIDENCE.md',
    ).readAsStringSync();
    final playtest = File(
      'cloudflare/playtest/wrangler.jsonc',
    ).readAsStringSync();
    final multiplayer = File(
      'cloudflare/multiplayer/wrangler.jsonc',
    ).readAsStringSync();
    final canary = File(
      'cloudflare/multiplayer/wrangler.canary.jsonc',
    ).readAsStringSync();

    expect(playtest, contains('"observability"'));
    expect(playtest, contains('"enabled": true'));

    for (final config in [multiplayer, canary]) {
      expect(config, contains('"observability"'));
      expect(config, contains('"logs"'));
      expect(config, contains('"enabled": true'));
      expect(config, contains('"invocation_logs": true'));
      expect(config, contains('"head_sampling_rate": 1'));
    }

    expect(evidence, contains('Cloudflare Worker Observability'));
    expect(evidence, contains('roadmap item'));
    expect(evidence, contains('remains open'));
  });
}
