import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rollback rehearsal template captures candidate and version identity', () {
    final template = File('docs/ROLLBACK_REHEARSAL_TEMPLATE.md').readAsStringSync();
    final releaseTemplate = File(
      'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md',
    ).readAsStringSync();

    for (final field in [
      'Release owner',
      'Rollback decision maker',
      'Candidate Git commit',
      'Previous protected playtest Worker version ID',
      'Candidate protected playtest Worker version ID',
      'Previous multiplayer Worker version ID',
      'Candidate multiplayer Worker version ID',
      'Public-site Worker version ID',
    ]) {
      expect(template, contains(field), reason: field);
    }

    expect(releaseTemplate, contains('Previous protected version ID'));
    expect(releaseTemplate, contains('Rollback test result'));
  });

  test('rollback rehearsal template captures backup and verification commands', () {
    final template = File('docs/ROLLBACK_REHEARSAL_TEMPLATE.md').readAsStringSync();
    final playtestPackage = File('cloudflare/playtest/package.json').readAsStringSync();
    final multiplayerPackage = File(
      'cloudflare/multiplayer/package.json',
    ).readAsStringSync();

    for (final field in [
      'Firebase/Firestore backup reference',
      'D1 safety database backup/export reference',
      'Multiplayer Durable Object migration/export reference',
      'Release build artifact backup location',
      'flutter analyze',
      'flutter test',
      'flutter build web --release',
      'node tool/audit_release_surface.mjs',
      'Cloudflare playtest build/test/dry-run',
      'Multiplayer Worker tests/dry-run',
    ]) {
      expect(template, contains(field), reason: field);
    }

    expect(playtestPackage, contains('deploy:dry-run'));
    expect(playtestPackage, contains('build:web'));
    expect(multiplayerPackage, contains('deploy:dry-run'));
    expect(multiplayerPackage, contains('test'));
  });

  test('rollback rehearsal template keeps roadmap rollback gate open', () {
    final template = File('docs/ROLLBACK_REHEARSAL_TEMPLATE.md').readAsStringSync();
    final roadmap = File('docs/RELEASE_ROADMAP.md').readAsStringSync();
    final operations = File('docs/RELEASE_OPERATIONS_EVIDENCE.md').readAsStringSync();

    for (final smokeCheck in [
      'App loads',
      'Existing protected player still loads',
      'Fresh player can start',
      'Save export/import still reachable',
      'Manual boss screen reachable',
      'Online lobby connects or fails closed as expected',
      'Trading connects or fails closed as expected',
    ]) {
      expect(template, contains(smokeCheck), reason: smokeCheck);
    }

    expect(
      roadmap,
      contains('[ ] Test rollback to the previous protected version.'),
    );
    expect(operations, contains('restore rehearsal'));
    expect(template, contains('Do not mark the release roadmap rollback item complete'));
  });
}

