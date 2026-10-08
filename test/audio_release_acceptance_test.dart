import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:egg_hatchers/data/audio_assets.dart';
import 'package:egg_hatchers/services/audio_service.dart';

void main() {
  test('audio acceptance checklist references shipped music and tests', () {
    final checklist = File('docs/AUDIO_RELEASE_ACCEPTANCE.md').readAsStringSync();
    final visualAudit = File(
      'docs/VISUAL_AUDIO_ACCESSIBILITY_AUDIT.md',
    ).readAsStringSync();
    final rightsAudit = File(
      'docs/ASSET_RIGHTS_RELEASE_AUDIT.md',
    ).readAsStringSync();

    for (final track in MusicTrack.values) {
      final path = 'assets/${track.assetPath}';
      expect(checklist, contains(path), reason: track.name);
      expect(rightsAudit, contains(path), reason: track.name);
    }

    expect(checklist, contains('test/audio_assets_test.dart'));
    expect(checklist, contains('test/manual_battle_test.dart'));
    expect(checklist, contains('docs/PLATFORM_AUDIO_BEHAVIOR_MATRIX.md'));
    expect(visualAudit, contains('Boss phase music loop approval'));
    expect(visualAudit, contains('Music and SFX volume normalization'));
  });

  test('audio acceptance checklist matches boss section timing code', () {
    final checklist = File('docs/AUDIO_RELEASE_ACCEPTANCE.md').readAsStringSync();
    final sections = AudioService.battleMusicSections;

    expect(sections, hasLength(4));
    expect(checklist, contains('0:00.000'));
    expect(checklist, contains('0:01.667'));
    expect(checklist, contains('0:13.333'));
    expect(checklist, contains('0:16.667'));
    expect(checklist, contains('0:26.667'));
    expect(checklist, contains('0:30.000'));
    expect(checklist, contains('0:40.000'));
    expect(checklist, contains('1:06.667'));

    expect(sections[0].start, Duration.zero);
    expect(sections[0].loopStart.inMicroseconds, 1666667);
    expect(sections[0].loopEnd.inMicroseconds, 13333333);
    expect(sections[1].start.inMicroseconds, 13333333);
    expect(sections[1].loopStart.inMicroseconds, 16666667);
    expect(sections[1].loopEnd.inMicroseconds, 26666667);
    expect(sections[2].start.inMicroseconds, 26666667);
    expect(sections[2].loopStart.inMicroseconds, 30000000);
    expect(sections[2].loopEnd.inMicroseconds, 40000000);
    expect(sections[3].start.inMicroseconds, 40000000);
    expect(sections[3].loopStart.inMicroseconds, 40000000);
    expect(sections[3].loopEnd.inMicroseconds, 66666667);
  });

  test('roadmap keeps audio approval gates open for platform listening', () {
    final roadmap = File('docs/RELEASE_ROADMAP.md').readAsStringSync();

    for (final item in [
      '[ ] Finalize boss phase music loops and all other music transitions.',
      '[ ] Normalize music and sound-effect volume.',
      '[ ] Verify audio unlock, pause/resume and background/foreground behavior on',
    ]) {
      expect(roadmap, contains(item), reason: item);
    }
  });

  test('platform audio behavior matrix covers release audio behavior', () {
    final matrix = File(
      'docs/PLATFORM_AUDIO_BEHAVIOR_MATRIX.md',
    ).readAsStringSync();
    final candidate = File(
      'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md',
    ).readAsStringSync();

    for (final phrase in [
      'First user tap unlocks audio',
      'Boss-life hit advances to the next phase without restarting at 0:00',
      'Each boss phase loops inside its approved BandLab red range',
      'Music slider changes volume without reload',
      'SFX slider changes volume without reload',
      'Music mute persists after refresh/restart',
      'SFX mute persists after refresh/restart',
      'Pause/resume does not stack duplicate music',
      'Background/foreground behavior acceptable',
      'Reduced Battle Effects keeps critical audio feedback',
      'Result: Pass / Fail / Deferred',
    ]) {
      expect(matrix, contains(phrase), reason: phrase);
    }

    expect(candidate, contains('Platform audio behavior matrix result'));
  });
}

