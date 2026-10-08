import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release verification runbook lists local candidate commands', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();

    for (final command in [
      'flutter pub get',
      'flutter analyze',
      'node tool/audit_brand.mjs',
      'flutter test',
      'flutter build web --release --no-pub',
      'node tool/audit_release_surface.mjs',
      'dart compile exe tool/multiplayer_server.dart',
      'npm run deploy:dry-run',
      'npm run typecheck',
    ]) {
      expect(runbook, contains(command), reason: command);
    }
  });

  test('release verification runbook matches CI verification workflow', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = Directory('.github/workflows')
        .listSync()
        .whereType<File>()
        .map((file) => file.readAsStringSync())
        .join('\n');

    for (final phrase in [
      'flutter analyze',
      'node tool/audit_brand.mjs',
      'flutter test',
      'flutter build web --release --no-pub',
      'node tool/audit_release_surface.mjs',
      'dart compile exe tool/multiplayer_server.dart',
      'docker build',
    ]) {
      expect(runbook, contains(phrase), reason: phrase);
      expect(workflow, contains(phrase), reason: phrase);
    }

    expect(runbook, contains('CI run URL'));
    expect(runbook, contains('artifact reference'));
  });

  test('release verification runbook keeps candidate gate open', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final roadmap = File('docs/RELEASE_ROADMAP.md').readAsStringSync();
    final candidate = File(
      'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md',
    ).readAsStringSync();

    for (final field in [
      'Protected playtest Worker version ID',
      'Multiplayer Worker version ID',
      'Android App Bundle checksum',
      'iOS archive/build identifier',
      'Release build artifact backup location',
      'Brand/legacy compatibility audit',
      'Release-surface audit',
      'Cross-platform account/save/multiplayer matrix',
    ]) {
      expect(runbook, contains(field), reason: field);
    }

    expect(
      roadmap,
      contains('[ ] Run analysis, all tests, compatibility audit and every release build.'),
    );
    expect(candidate, contains('flutter analyze'));
    expect(candidate, contains('Brand audit'));
    expect(candidate, contains('Account/save/multiplayer acceptance matrix'));
  });
}

