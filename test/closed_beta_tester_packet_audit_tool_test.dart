import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('closed beta tester packet audit passes', () async {
    final result = await Process.run('node', [
      'tool/audit_closed_beta_tester_packet.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains(
        'Closed beta tester packet audit: tester instructions, privacy boundaries and open beta gates verified.',
      ),
    );
  });

  test('release runbook and CI include tester packet audit', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final evidenceIndex = File('docs/RELEASE_EVIDENCE_INDEX.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();

    expect(runbook, contains('docs/CLOSED_BETA_TESTER_PACKET.md'));
    expect(runbook, contains('docs/CLOSED_BETA_COVERAGE_MATRIX.md'));
    expect(evidenceIndex, contains('docs/CLOSED_BETA_COVERAGE_MATRIX.md'));
    expect(runbook, contains('node tool/audit_closed_beta_tester_packet.mjs'));
    expect(workflow, contains('node tool/audit_closed_beta_tester_packet.mjs'));
    expect(workflow, contains('Verify closed beta tester packet'));
  });
}
