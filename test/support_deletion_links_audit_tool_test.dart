import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('support deletion links audit passes', () async {
    final result = await Process.run('node', [
      'tool/audit_support_deletion_links.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains(
        'Support/deletion link audit: public routes, store links, in-app deletion, inbox checks and stop conditions verified.',
      ),
    );
  });

  test('release docs and CI include support deletion links audit', () {
    final checklist = File('docs/SUPPORT_DELETION_LINK_VERIFICATION.md').readAsStringSync();
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();
    final evidenceIndex = File('docs/RELEASE_EVIDENCE_INDEX.md').readAsStringSync();

    expect(checklist, contains('Public routes to verify'));
    expect(checklist, contains('Store-entry checks'));
    expect(checklist, contains('Stop conditions'));
    expect(runbook, contains('node tool/audit_support_deletion_links.mjs'));
    expect(workflow, contains('node tool/audit_support_deletion_links.mjs'));
    expect(evidenceIndex, contains('docs/SUPPORT_DELETION_LINK_VERIFICATION.md'));
  });
}
