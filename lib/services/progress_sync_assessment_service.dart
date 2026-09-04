import '../models/cloud_progress_read.dart';
import '../models/progress_sync_checkpoint.dart';
import '../models/progress_sync_plan.dart';
import 'progress_sync_checkpoint_store.dart';
import 'save_service.dart';

abstract interface class CloudProgressSource {
  Future<CloudProgressRead> read(String protectedPlayerId);
}

class ProgressSyncAssessment {
  const ProgressSyncAssessment({
    required this.action,
    required this.local,
    required this.cloud,
    required this.checkpoint,
  });

  final ProgressSyncAction action;
  final ProgressSaveSnapshot? local;
  final CloudProgressRead cloud;
  final ProgressSyncCheckpoint? checkpoint;
}

/// Reads both sides and asks the conservative planner what may safely happen.
///
/// This service is intentionally read-only. Upload, download, and conflict UI
/// are separate operations that must confirm the assessment is still current.
class ProgressSyncAssessmentService {
  ProgressSyncAssessmentService({
    required this.local,
    required this.checkpoints,
    required this.cloud,
  });

  final SaveService local;
  final ProgressSyncCheckpointStore checkpoints;
  final CloudProgressSource cloud;

  Future<ProgressSyncAssessment> assess(String protectedPlayerId) async {
    final localSnapshot = await local.loadSnapshot();
    final checkpoint = await checkpoints.read();
    var cloudRead = await _readCloud(protectedPlayerId);
    if (!_isValid(cloudRead)) {
      cloudRead = const CloudProgressRead.unknown();
    }
    final remote = cloudRead.snapshot;
    final context = ProgressSyncContext(
      cloudState: cloudRead.state,
      localFingerprint: localSnapshot?.contentFingerprint,
      cloudFingerprint: remote?.contentFingerprint,
      cloudRevision: remote?.cloudRevision,
      lastSyncedFingerprint: checkpoint?.contentFingerprint,
      lastSyncedCloudRevision: checkpoint?.cloudRevision,
    );
    return ProgressSyncAssessment(
      action: ProgressSyncPlanner.plan(context),
      local: localSnapshot,
      cloud: cloudRead,
      checkpoint: checkpoint,
    );
  }

  Future<CloudProgressRead> _readCloud(String protectedPlayerId) async {
    try {
      return await cloud.read(protectedPlayerId);
    } catch (_) {
      return const CloudProgressRead.unknown();
    }
  }

  bool _isValid(CloudProgressRead read) {
    final snapshot = read.snapshot;
    if (read.state != CloudProgressState.present) return snapshot == null;
    if (snapshot == null || snapshot.cloudRevision < 0) return false;
    return SaveService.contentFingerprint(snapshot.state) ==
        snapshot.contentFingerprint;
  }
}
