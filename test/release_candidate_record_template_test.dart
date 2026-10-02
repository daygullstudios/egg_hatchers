import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release candidate template captures required launch identity', () {
    final template = File(
      'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md',
    ).readAsStringSync();
    final roadmap = File('docs/RELEASE_ROADMAP.md').readAsStringSync();

    for (final field in [
      'Release owner',
      'Rollback decision maker',
      'Git commit',
      'Version name/build number',
      'Selected launch platforms',
      'Selected launch countries',
    ]) {
      expect(template, contains(field), reason: field);
    }

    expect(
      roadmap,
      contains('Record the exact commit, build numbers, infrastructure versions and backup.'),
    );
  });

  test('release candidate template captures verification and artifact evidence', () {
    final template = File(
      'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md',
    ).readAsStringSync();

    for (final field in [
      'flutter analyze',
      'flutter test',
      'flutter build web --release',
      'Protected playtest Worker version ID',
      'Multiplayer Worker version ID',
      'Brand audit',
      'Asset rights audit',
      'Two-device internet play',
      'Load/capacity test',
      'Account/save/multiplayer acceptance matrix',
    ]) {
      expect(template, contains(field), reason: field);
    }
  });

  test('release candidate template captures rollback privacy and monitoring', () {
    final template = File(
      'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md',
    ).readAsStringSync();

    for (final field in [
      'Firebase/Firestore backup reference',
      'D1 safety database backup/export reference',
      'Previous protected version ID',
      'Rollback test result',
      'Professional family/privacy review reference',
      'Candidate Privacy Policy URL/version',
      'Monitoring/alert owner and destinations',
      'Rollback trigger thresholds',
    ]) {
      expect(template, contains(field), reason: field);
    }
  });
}
