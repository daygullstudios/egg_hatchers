import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('asset rights audit passes for current shipped assets', () async {
    final result = await Process.run('node', [
      'tool/audit_asset_rights.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains('Asset rights audit: 13 media roots'),
    );
  });

  test('release verification runbook and CI include asset rights audit', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();

    expect(runbook, contains('node tool/audit_asset_rights.mjs'));
    expect(workflow, contains('node tool/audit_asset_rights.mjs'));
    expect(workflow, contains('Verify asset rights inventory'));
  });
}
