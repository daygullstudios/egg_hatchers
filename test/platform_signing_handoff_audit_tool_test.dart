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
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();
    final evidenceIndex = File('docs/RELEASE_EVIDENCE_INDEX.md').readAsStringSync();

    expect(handoff, contains('Android signing handoff'));
    expect(handoff, contains('iOS signing handoff'));
    expect(handoff, contains('Repository safety check'));
    expect(runbook, contains('node tool/audit_platform_signing_handoff.mjs'));
    expect(workflow, contains('node tool/audit_platform_signing_handoff.mjs'));
    expect(evidenceIndex, contains('docs/PLATFORM_SIGNING_HANDOFF.md'));
  });
}
