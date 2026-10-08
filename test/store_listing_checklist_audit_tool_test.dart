import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'store listing checklist audit passes for current release evidence',
    () async {
      final result = await Process.run('node', [
        'tool/audit_store_listing_checklist.mjs',
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(
        result.stdout.toString(),
        contains(
          'Store listing checklist audit: metadata, screenshot manifest, ratings, privacy answers and open store gates verified.',
        ),
      );
    },
  );

  test('release verification runbook and CI include store listing audit', () {
    final runbook = File(
      'docs/RELEASE_VERIFICATION_RUNBOOK.md',
    ).readAsStringSync();
    final evidenceIndex = File('docs/RELEASE_EVIDENCE_INDEX.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();

    expect(runbook, contains('node tool/audit_store_listing_checklist.mjs'));
    expect(runbook, contains('docs/STORE_SCREENSHOT_MANIFEST_TEMPLATE.md'));
    expect(evidenceIndex, contains('docs/STORE_SCREENSHOT_MANIFEST_TEMPLATE.md'));
    expect(workflow, contains('node tool/audit_store_listing_checklist.mjs'));
    expect(workflow, contains('Verify store listing checklist'));
  });

  test('store screenshot manifest protects candidate screenshots', () {
    final manifest = File(
      'docs/STORE_SCREENSHOT_MANIFEST_TEMPLATE.md',
    ).readAsStringSync();
    final checklist = File('docs/STORE_LISTING_DRAFT_CHECKLIST.md').readAsStringSync();
    final candidate = File(
      'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md',
    ).readAsStringSync();

    for (final required in [
      'Capture only the exact release candidate build',
      'Hide developer-only controls before capture',
      'Do not use Cloudflare temporary tunnel URLs',
      'private Save Transfer files',
      'Future-event/monetization claims absent',
      'Hatchery first-player flow',
      'Egg Shop',
      'Manual boss fight',
      'Settings account/save controls',
      'Narrow phone layout',
    ]) {
      expect(manifest, contains(required), reason: required);
    }

    expect(checklist, contains('docs/STORE_SCREENSHOT_MANIFEST_TEMPLATE.md'));
    expect(candidate, contains('Store screenshot manifest result'));
  });
}
