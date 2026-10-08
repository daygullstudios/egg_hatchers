import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('platform signing handoff audit passes', () async {
    final result = await Process.run('node', [
      'tool/audit_platform_signing_handoff.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains(
        'Platform signing handoff audit: credential boundaries, Android/iOS evidence, and store submission gates verified.',
      ),
    );
  });

  test('release docs and CI include platform signing handoff audit', () {
    final handoff = File('docs/PLATFORM_SIGNING_HANDOFF.md').readAsStringSync();
    final buildInspection = File(
      'docs/PLATFORM_BUILD_INSPECTION_TEMPLATE.md',
    ).readAsStringSync();
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();
    final evidenceIndex = File('docs/RELEASE_EVIDENCE_INDEX.md').readAsStringSync();

    expect(handoff, contains('Android signing handoff'));
    expect(handoff, contains('iOS signing handoff'));
    expect(handoff, contains('Repository safety check'));
    expect(handoff, contains('docs/PLATFORM_BUILD_INSPECTION_TEMPLATE.md'));
    expect(buildInspection, contains('Android App Bundle Inspection'));
    expect(buildInspection, contains('iOS Archive Inspection'));
    expect(runbook, contains('node tool/audit_platform_signing_handoff.mjs'));
    expect(runbook, contains('docs/PLATFORM_BUILD_INSPECTION_TEMPLATE.md'));
    expect(workflow, contains('node tool/audit_platform_signing_handoff.mjs'));
    expect(evidenceIndex, contains('docs/PLATFORM_SIGNING_HANDOFF.md'));
    expect(evidenceIndex, contains('docs/PLATFORM_BUILD_INSPECTION_TEMPLATE.md'));
  });

  test('platform build inspection captures native build checks', () {
    final inspection = File(
      'docs/PLATFORM_BUILD_INSPECTION_TEMPLATE.md',
    ).readAsStringSync();
    final candidate = File(
      'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md',
    ).readAsStringSync();

    for (final phrase in [
      'App Bundle checksum',
      'Package name',
      'Version code',
      'Upload key fingerprint reference',
      'Permissions review',
      'Archive/build identifier',
      'Bundle identifier',
      'Signing team',
      'Provisioning profile reference',
      'Entitlements review',
      'Real-device test result',
      'Secrets absent from artifact notes/logs',
      'Store privacy answers do not match the inspected candidate',
    ]) {
      expect(inspection, contains(phrase), reason: phrase);
    }

    expect(candidate, contains('Platform build inspection result'));
  });
}
