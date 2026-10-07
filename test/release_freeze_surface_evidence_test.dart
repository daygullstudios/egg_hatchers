import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release freeze evidence documents the debug-only tools boundary', () {
    final evidence = File(
      'docs/RELEASE_FREEZE_SURFACE_EVIDENCE.md',
    ).readAsStringSync();
    final route = File('lib/navigation/app_page_route.dart').readAsStringSync();
    final secretTools = File(
      'lib/screens/secret_tools_screen.dart',
    ).readAsStringSync();

    expect(evidence, contains('pushDevToolsRoute'));
    expect(evidence, contains('kDebugMode'));
    expect(evidence, contains('Developer Tools (Debug)'));
    expect(evidence, contains('fullDeveloperToolsUnlocked'));
    expect(route, contains('if (!kDebugMode) return Future<T?>.value();'));
    expect(secretTools, contains('if (kDebugMode)'));
    expect(secretTools, contains('Developer Tools (Debug)'));
  });

  test('release audit scans the compiled web bundle for dev controls', () {
    final evidence = File(
      'docs/RELEASE_FREEZE_SURFACE_EVIDENCE.md',
    ).readAsStringSync();
    final audit = File('tool/audit_release_surface.mjs').readAsStringSync();

    for (final marker in [
      'Developer Tools (Debug)',
      'Force Next Single Hatch',
      'Unlock Rotten Shell reqs',
      'Preview DayGull Unlock',
      'Collect All Animals',
    ]) {
      expect(evidence, contains(marker), reason: marker);
      expect(audit, contains(marker), reason: marker);
    }

    expect(audit, contains('build/web/main.dart.js'));
    expect(audit, contains('Release surface audit'));
  });

  test('roadmap keeps feature freeze open until a candidate is frozen', () {
    final roadmap = File('docs/RELEASE_ROADMAP.md').readAsStringSync();
    final template = File(
      'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md',
    ).readAsStringSync();

    expect(
      roadmap,
      contains('[ ] Freeze features and remove or hide development-only controls.'),
    );
    expect(template, contains('Git commit'));
    expect(template, contains('flutter build web --release'));
  });
}

