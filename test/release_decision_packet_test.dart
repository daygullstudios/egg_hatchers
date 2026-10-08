import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release decision packet names every owner decision blocker', () {
    final packet = File('docs/RELEASE_DECISION_PACKET.md').readAsStringSync();
    final roadmap = File('docs/RELEASE_ROADMAP.md').readAsStringSync();

    const decisions = [
      'Launch platforms',
      'Launch countries',
      'Release owner and rollback decision maker',
      'Final logo and platform branding approval',
      'Music and shipped-asset rights',
      'Monitoring, backups and alerts',
      'Family/privacy review path',
    ];

    for (final decision in decisions) {
      expect(packet, contains(decision), reason: decision);
    }

    const stillOpenRoadmapItems = [
      '[ ] Confirm launch platforms: web, Android and/or iOS.',
      '[ ] Confirm launch countries.',
      '[ ] Name one release owner and one rollback decision maker.',
      '[ ] Confirm commercial rights and source records for every shipped asset.',
      '[ ] Add production error monitoring that matches the approved privacy model.',
      '[ ] Confirm backups, restore procedures, rate limits and operational alerts.',
    ];

    for (final item in stillOpenRoadmapItems) {
      expect(roadmap, contains(item), reason: item);
    }

    expect(
      roadmap,
      contains('[x] Approve the final Nestarium logo and regenerate platform branding assets.'),
    );

    expect(
      roadmap,
      contains('Collect the owner decisions in `docs/RELEASE_DECISION_PACKET.md`'),
    );
    expect(
      roadmap,
      contains('Configure selected platform signing/store readiness only after launch'),
    );
    expect(packet, contains('docs/RELEASE_OWNER_DECISION_FORM.md'));
  });

  test('release decision packet matches current platform files', () {
    final packet = File('docs/RELEASE_DECISION_PACKET.md').readAsStringSync();
    final androidBuild = File(
      'android/app/build.gradle.kts',
    ).readAsStringSync();
    final keyExample = File(
      'android/key.properties.example',
    ).readAsStringSync();
    final manifest = File('web/manifest.json').readAsStringSync();
    final migration = File('docs/NESTARIUM_MIGRATION.md').readAsStringSync();

    expect(packet, contains('android/app/build.gradle.kts'));
    expect(packet, contains('android/key.properties'));
    expect(androidBuild, contains('hasReleaseSigning'));
    expect(androidBuild, contains('signingConfigs'));
    expect(keyExample, contains('storeFile=../upload-keystore.jks'));
    expect(manifest, contains('"name": "Nestarium"'));
    expect(migration, contains('playtest.playnestarium.com'));
    expect(migration, contains('playnestarium.com'));
  });

  test('release decision packet lists the unresolved shipped music files', () {
    final packet = File('docs/RELEASE_DECISION_PACKET.md').readAsStringSync();
    final assetAudit = File(
      'docs/ASSET_RIGHTS_RELEASE_AUDIT.md',
    ).readAsStringSync();

    const musicFiles = [
      'assets/sounds/music/hatchery_chill_loop.mp3',
      'assets/sounds/music/boss_music.wav',
      'assets/sounds/music/final_boss_music.mp3',
    ];

    for (final file in musicFiles) {
      expect(packet, contains(file), reason: file);
      expect(assetAudit, contains(file), reason: file);
    }
  });

  test('release owner decision form captures final owner answers', () {
    final form = File('docs/RELEASE_OWNER_DECISION_FORM.md').readAsStringSync();

    for (final phrase in [
      'Decision Identity',
      'Launch Scope',
      'First release platforms',
      'First launch countries/regions',
      'Public playable route approval',
      'Store submission approval',
      'Bot Arena remains in 1.0',
      'Music rights confirmed for `assets/sounds/music/hatchery_chill_loop.mp3`',
      'Music rights confirmed for `assets/sounds/music/boss_music.wav`',
      'Music rights confirmed for `assets/sounds/music/final_boss_music.mp3`',
      'Parent/guardian capability flow approved',
      'Production monitoring/alerts owner',
      'Trusted production session owner',
      'Closed beta entry approved',
      'Support/deletion link verification owner',
      'Explicit Stop Conditions',
    ]) {
      expect(form, contains(phrase), reason: phrase);
    }
  });
}
