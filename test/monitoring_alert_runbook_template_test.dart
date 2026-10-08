import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('monitoring alert runbook captures ownership and privacy boundary', () {
    final runbook = File(
      'docs/MONITORING_ALERT_RUNBOOK_TEMPLATE.md',
    ).readAsStringSync();
    final monitoring = File(
      'docs/RELEASE_MONITORING_EVIDENCE.md',
    ).readAsStringSync();

    for (final field in [
      'Monitoring owner',
      'Backup responder',
      'Release owner',
      'Rollback decision maker',
      'Alert destinations',
      'Support inbox',
      'Incident log location',
    ]) {
      expect(runbook, contains(field), reason: field);
    }

    for (final forbidden in [
      'player profile payloads',
      'progress payloads',
      'custom art',
      'animal rosters',
    ]) {
      expect(runbook, contains(forbidden), reason: forbidden);
      expect(monitoring, contains(forbidden), reason: forbidden);
    }
    expect(runbook, contains('child/guardian information'));
    expect(monitoring, contains('child/guardian'));
    expect(runbook, contains('preset-message contents'));
    expect(monitoring, contains('chat/preset-message'));
    expect(runbook, contains('Save Transfer files'));
    expect(monitoring, contains('save-transfer files'));
    expect(runbook, contains('identity tokens'));
  });

  test('monitoring alert runbook covers operational triggers and rollback', () {
    final runbook = File(
      'docs/MONITORING_ALERT_RUNBOOK_TEMPLATE.md',
    ).readAsStringSync();
    final roadmap = File('docs/RELEASE_ROADMAP.md').readAsStringSync();
    final rollback = File('docs/ROLLBACK_REHEARSAL_TEMPLATE.md').readAsStringSync();

    for (final trigger in [
      'web Worker error spike',
      'Multiplayer Worker error spike',
      'capacity saturation',
      'D1 safety database errors',
      'retention-prune failure',
      'Failed deploy or dry-run',
      'Support/account-deletion link failure',
      'Save/account recovery support spike',
    ]) {
      expect(runbook, contains(trigger), reason: trigger);
    }

    expect(runbook, contains('docs/ROLLBACK_REHEARSAL_TEMPLATE.md'));
    expect(rollback, contains('Rollback Path'));
    expect(
      roadmap,
      contains('[ ] Add production error monitoring that matches the approved privacy model.'),
    );
  });

  test('monitoring alert runbook matches Worker observability evidence', () {
    final runbook = File(
      'docs/MONITORING_ALERT_RUNBOOK_TEMPLATE.md',
    ).readAsStringSync();
    final playtest = File('cloudflare/playtest/wrangler.jsonc').readAsStringSync();
    final multiplayer = File(
      'cloudflare/multiplayer/wrangler.jsonc',
    ).readAsStringSync();
    final candidate = File(
      'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md',
    ).readAsStringSync();

    expect(playtest, contains('"observability"'));
    expect(multiplayer, contains('"observability"'));
    expect(multiplayer, contains('"invocation_logs": true'));
    expect(runbook, contains('Worker Observability'));
    expect(runbook, contains('privacy-safe error visibility test'));
    expect(candidate, contains('Monitoring/alert owner and destinations'));
  });
}

