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
}

