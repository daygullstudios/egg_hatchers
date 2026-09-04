import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/models/cloud_progress_read.dart';
import 'package:egg_hatchers/models/progress_sync_checkpoint.dart';
import 'package:egg_hatchers/models/progress_sync_plan.dart';
import 'package:egg_hatchers/services/progress_sync_assessment_service.dart';
import 'package:egg_hatchers/services/progress_sync_checkpoint_store.dart';
import 'package:egg_hatchers/services/save_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('cloud exception becomes unknown and never authorizes upload', () async {
    final local = SaveService(accountId: 'local');
    await local.save(GameData.startingPlayerState().copyWith(coins: 900));
    final service = ProgressSyncAssessmentService(
      local: local,
      checkpoints: ProgressSyncCheckpointStore(accountId: 'local'),
      cloud: _CloudSource(() => throw StateError('offline')),
    );

    final assessment = await service.assess('protected-player');

    expect(assessment.action, ProgressSyncAction.waitForCloud);
    expect(assessment.cloud.state, CloudProgressState.unknown);
    expect(assessment.local, isNotNull);
  });

  test('confirmed empty cloud permits upload of existing local save', () async {
    final local = SaveService(accountId: 'local');
    await local.save(GameData.startingPlayerState().copyWith(coins: 900));
    final service = ProgressSyncAssessmentService(
      local: local,
      checkpoints: ProgressSyncCheckpointStore(accountId: 'local'),
      cloud: _CloudSource(() async => const CloudProgressRead.missing()),
    );

    final assessment = await service.assess('protected-player');

    expect(assessment.action, ProgressSyncAction.uploadLocal);
  });

  test('invalid remote fingerprint is unknown rather than trusted', () async {
    final remoteState = GameData.startingPlayerState().copyWith(coins: 400);
    final service = ProgressSyncAssessmentService(
      local: SaveService(accountId: 'local'),
      checkpoints: ProgressSyncCheckpointStore(accountId: 'local'),
      cloud: _CloudSource(
        () async => CloudProgressRead.present(
          CloudProgressSnapshot(
            state: remoteState,
            contentFingerprint:
                'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
            cloudRevision: 3,
            savedAt: DateTime.utc(2026),
          ),
        ),
      ),
    );

    final assessment = await service.assess('protected-player');

    expect(assessment.action, ProgressSyncAction.waitForCloud);
    expect(assessment.cloud.state, CloudProgressState.unknown);
  });

  test('checkpoint allows a one-sided local change to upload', () async {
    final sharedState = GameData.startingPlayerState().copyWith(coins: 400);
    final sharedFingerprint = SaveService.contentFingerprint(sharedState);
    final local = SaveService(accountId: 'local');
    await local.save(sharedState.copyWith(coins: 500));
    final checkpoints = ProgressSyncCheckpointStore(accountId: 'local');
    await checkpoints.write(
      ProgressSyncCheckpoint(
        contentFingerprint: sharedFingerprint,
        cloudRevision: 8,
        recordedAt: DateTime.utc(2026),
      ),
    );
    final service = ProgressSyncAssessmentService(
      local: local,
      checkpoints: checkpoints,
      cloud: _CloudSource(
        () async => CloudProgressRead.present(
          CloudProgressSnapshot(
            state: sharedState,
            contentFingerprint: sharedFingerprint,
            cloudRevision: 8,
            savedAt: DateTime.utc(2026),
          ),
        ),
      ),
    );

    final assessment = await service.assess('protected-player');

    expect(assessment.action, ProgressSyncAction.uploadLocal);
    expect(assessment.checkpoint!.cloudRevision, 8);
  });
}

final class _CloudSource implements CloudProgressSource {
  const _CloudSource(this.readValue);

  final Future<CloudProgressRead> Function() readValue;

  @override
  Future<CloudProgressRead> read(String protectedPlayerId) => readValue();
}
