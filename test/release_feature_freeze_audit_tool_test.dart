import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release feature-freeze audit passes', () async {
    final result = await Process.run('node', [
      'tool/audit_release_feature_freeze.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains(
        'Release feature-freeze audit: scope boundary, dev surface, freeze exceptions and candidate exit evidence verified.',
      ),
    );
  });

  test('release docs and CI include feature-freeze audit', () {
    final checklist = File('docs/RELEASE_FEATURE_FREEZE_CHECKLIST.md').readAsStringSync();
    final surface = File('docs/RELEASE_FREEZE_SURFACE_EVIDENCE.md').readAsStringSync();
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();
    final evidenceIndex = File('docs/RELEASE_EVIDENCE_INDEX.md').readAsStringSync();

    expect(checklist, contains('Allowed changes during freeze'));
    expect(checklist, contains('Changes that reopen the candidate'));
    expect(surface, contains('docs/RELEASE_FEATURE_FREEZE_CHECKLIST.md'));
    expect(runbook, contains('node tool/audit_release_feature_freeze.mjs'));
    expect(workflow, contains('node tool/audit_release_feature_freeze.mjs'));
    expect(evidenceIndex, contains('docs/RELEASE_FEATURE_FREEZE_CHECKLIST.md'));
  });
}
