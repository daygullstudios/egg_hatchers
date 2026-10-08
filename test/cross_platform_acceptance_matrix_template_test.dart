import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cross-platform acceptance matrix captures candidate identity', () {
    final matrix = File(
      'docs/CROSS_PLATFORM_ACCEPTANCE_MATRIX_TEMPLATE.md',
    ).readAsStringSync();
    final releaseCandidate = File(
      'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md',
    ).readAsStringSync();

    for (final field in [
      'Candidate Git commit',
      'Version name/build number',
      'Selected launch platforms',
      'Selected launch countries',
      'Release owner',
      'Rollback decision maker',
      'Protected playtest Worker version',
      'Multiplayer Worker version',
    ]) {
      expect(matrix, contains(field), reason: field);
    }

    expect(releaseCandidate, contains('Account/save/multiplayer acceptance matrix'));
  });

  test('cross-platform acceptance matrix covers account save and multiplayer', () {
    final matrix = File(
      'docs/CROSS_PLATFORM_ACCEPTANCE_MATRIX_TEMPLATE.md',
    ).readAsStringSync();

    for (final field in [
      'Fresh account starts with no progress',
      'Returning account loads expected progress',
      'Save Transfer export/import succeeds',
      'Cloud restore or approved recovery path succeeds',
      'Account deletion/support path verified',
      'Conflict review preserves both copies until confirmation',
      'Offline or interrupted startup fails safely',
      'Manual boss battle playable',
      'Audio unlock/pause/resume acceptable',
      'Online battle invitation or matchmaking verified',
      'Online battle reward receipt delivered once',
      'Online trade invite/cancel/complete verified',
      'Preset messages available; open text unavailable',
      'Blocked-player/report flow verified',
      'Narrow layout and selected text scale acceptable',
    ]) {
      expect(matrix, contains(field), reason: field);
    }
  });

  test('cross-platform acceptance matrix links supporting evidence and roadmap gate', () {
    final matrix = File(
      'docs/CROSS_PLATFORM_ACCEPTANCE_MATRIX_TEMPLATE.md',
    ).readAsStringSync();
    final roadmap = File('docs/RELEASE_ROADMAP.md').readAsStringSync();

    for (final evidence in [
      'docs/RELEASE_ACCOUNT_MATRIX_EVIDENCE.md',
      'docs/MULTIPLAYER_PRODUCTION_ACCEPTANCE.md',
      'docs/PLATFORM_STORE_READINESS.md',
      'docs/AUDIO_RELEASE_ACCEPTANCE.md',
      'docs/PUBLIC_POLICY_READINESS.md',
    ]) {
      expect(matrix, contains(evidence), reason: evidence);
      expect(File(evidence).existsSync(), isTrue, reason: evidence);
    }

    expect(
      roadmap,
      contains('[ ] Complete the cross-platform account/save/multiplayer acceptance matrix.'),
    );
    expect(matrix, contains('release-owner-approved Pass'));
  });

  test('cross-platform acceptance matrix blocks hidden failures', () {
    final matrix = File(
      'docs/CROSS_PLATFORM_ACCEPTANCE_MATRIX_TEMPLATE.md',
    ).readAsStringSync();
    final releaseCandidate = File(
      'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md',
    ).readAsStringSync();

    for (final phrase in [
      'Failed Or Deferred Rows',
      'Exact failed row field',
      'Whether the selected launch platform list must change',
      'Focused retest command and result',
      'Release owner decision',
      'Rollback decision maker decision',
      'Any Critical or High failure keeps the release candidate blocked',
    ]) {
      expect(matrix, contains(phrase), reason: phrase);
    }

    expect(
      releaseCandidate,
      contains('Failed/deferred platform rows and accepted-risk references'),
    );
  });
}

