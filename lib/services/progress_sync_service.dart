import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/cloud_progress_read.dart';
import '../models/player_state.dart';
import '../models/progress_sync_checkpoint.dart';
import '../models/progress_sync_plan.dart';
import '../models/progress_sync_state.dart';
import 'progress_sync_assessment_service.dart';
import 'progress_sync_checkpoint_store.dart';
import 'save_service.dart';

abstract interface class CloudProgressRepository
    implements CloudProgressSource {
  Future<CloudProgressSnapshot> write({
    required String protectedPlayerId,
    required ProgressSaveSnapshot local,
    required int? expectedCloudRevision,
  });
}

final class CloudProgressWriteConflict implements Exception {
  const CloudProgressWriteConflict();
}

typedef ApplyCloudProgress = Future<bool> Function(PlayerState state);

/// Coordinates local-first progress with one revisioned cloud document.
///
/// Unknown reads never authorize a write. Automatic upload/download happens
/// only when the planner can prove a shared ancestor; divergent saves wait for
/// an explicit player choice.
class ProgressSyncService extends ChangeNotifier {
  ProgressSyncService({this.debounce = const Duration(seconds: 2)});

  final Duration debounce;
  ProgressSyncState _state = const ProgressSyncState.unavailable();
  Timer? _timer;
  String? _accountId;
  String? _protectedPlayerId;
  SaveService? _local;
  ProgressSyncCheckpointStore? _checkpoints;
  CloudProgressRepository? _cloud;
  ApplyCloudProgress? _applyCloud;
  ProgressSyncAssessment? _conflict;
  var _selectionRevision = 0;
  var _syncing = false;
  var _rerunRequested = false;

  ProgressSyncState get state => _state;

  Future<void> selectAccount({
    required String? accountId,
    required String? protectedPlayerId,
    CloudProgressRepository? cloud,
    ApplyCloudProgress? applyCloud,
  }) async {
    _selectionRevision += 1;
    _timer?.cancel();
    _accountId = accountId;
    _protectedPlayerId = protectedPlayerId;
    _local = accountId == null ? null : SaveService(accountId: accountId);
    _checkpoints = accountId == null
        ? null
        : ProgressSyncCheckpointStore(accountId: accountId);
    _cloud = cloud;
    _applyCloud = applyCloud;
    _conflict = null;
    if (!_isConfigured) {
      _setState(const ProgressSyncState.unavailable());
      return;
    }
    _setState(
      const ProgressSyncState(
        status: ProgressSyncStatus.pending,
        message: 'Checking this device against its cloud copy…',
      ),
    );
    await synchronize();
  }

  bool get _isConfigured =>
      _accountId != null &&
      _protectedPlayerId != null &&
      _local != null &&
      _checkpoints != null &&
      _cloud != null &&
      _applyCloud != null;

  void localProgressSaved(String? accountId) {
    if (!_isConfigured || accountId != _accountId) return;
    _setState(
      const ProgressSyncState(
        status: ProgressSyncStatus.pending,
        message: 'Saved on this device. Cloud sync is pending…',
      ),
    );
    if (_syncing) {
      _rerunRequested = true;
      return;
    }
    if (!(_timer?.isActive ?? false)) {
      _timer = Timer(debounce, synchronize);
    }
  }

  Future<void> synchronize() async {
    if (!_isConfigured) return;
    if (_syncing) {
      _rerunRequested = true;
      return;
    }
    _timer?.cancel();
    final revision = _selectionRevision;
    _syncing = true;
    _setState(
      const ProgressSyncState(
        status: ProgressSyncStatus.syncing,
        message: 'Comparing device and cloud progress…',
      ),
    );
    try {
      final assessment = await _assess();
      if (revision != _selectionRevision) return;
      await _applyAssessment(assessment, revision);
    } catch (error, stackTrace) {
      debugPrint('Progress sync failed: $error\n$stackTrace');
      if (revision == _selectionRevision) {
        _setState(
          const ProgressSyncState(
            status: ProgressSyncStatus.error,
            message: 'Progress is safe on this device. Cloud sync will retry.',
          ),
        );
        _scheduleRetry();
      }
    } finally {
      _syncing = false;
      if (_rerunRequested && _isConfigured) {
        _rerunRequested = false;
        _timer = Timer(debounce, synchronize);
      }
    }
  }

  Future<void> keepThisDevice() async {
    final assessment = _conflict;
    if (assessment?.local == null || !_isConfigured || _syncing) return;
    _timer?.cancel();
    final revision = _selectionRevision;
    _syncing = true;
    _setSyncing('Saving this device’s progress to the cloud…');
    try {
      final fresh = await _assess();
      if (revision != _selectionRevision) return;
      if (fresh.local == null ||
          fresh.cloud.state == CloudProgressState.unknown) {
        throw StateError('Cloud state is unavailable.');
      }
      final written = await _cloud!.write(
        protectedPlayerId: _protectedPlayerId!,
        local: fresh.local!,
        expectedCloudRevision: fresh.cloud.snapshot?.cloudRevision,
      );
      await _record(written.contentFingerprint, written.cloudRevision);
      _conflict = null;
      _setSynced();
    } on CloudProgressWriteConflict {
      _setConflict(
        'Cloud progress changed again. Review your choice once more.',
      );
    } catch (error, stackTrace) {
      debugPrint('Keep-device resolution failed: $error\n$stackTrace');
      _setError();
    } finally {
      _finishManualResolution(revision);
    }
  }

  Future<void> useCloud() async {
    if (_conflict == null || !_isConfigured || _syncing) return;
    _timer?.cancel();
    final revision = _selectionRevision;
    _syncing = true;
    _setSyncing('Restoring the latest cloud progress…');
    try {
      final read = await _cloud!.read(_protectedPlayerId!);
      if (revision != _selectionRevision) return;
      final remote = read.snapshot;
      if (read.state != CloudProgressState.present || remote == null) {
        throw StateError('Cloud progress is unavailable.');
      }
      if (!await _applyCloud!(remote.state)) return;
      final applied = await _local!.loadSnapshot();
      if (applied == null) throw StateError('Cloud restore was not saved.');
      await _record(remote.contentFingerprint, remote.cloudRevision);
      _conflict = null;
      if (applied.contentFingerprint == remote.contentFingerprint) {
        _setSynced();
      } else {
        localProgressSaved(_accountId);
      }
    } catch (error, stackTrace) {
      debugPrint('Cloud restore failed: $error\n$stackTrace');
      _setError();
    } finally {
      _finishManualResolution(revision);
    }
  }

  void _finishManualResolution(int revision) {
    _syncing = false;
    if (_rerunRequested && revision == _selectionRevision && _isConfigured) {
      _rerunRequested = false;
      _timer = Timer(debounce, synchronize);
    }
  }

  Future<ProgressSyncAssessment> _assess() => ProgressSyncAssessmentService(
    local: _local!,
    checkpoints: _checkpoints!,
    cloud: _cloud!,
  ).assess(_protectedPlayerId!);

  Future<void> _applyAssessment(
    ProgressSyncAssessment assessment,
    int revision,
  ) async {
    switch (assessment.action) {
      case ProgressSyncAction.waitForCloud:
        _setState(
          const ProgressSyncState(
            status: ProgressSyncStatus.pending,
            message:
                'Offline or cloud unavailable. Progress is safe on this device.',
          ),
        );
        _scheduleRetry();
        return;
      case ProgressSyncAction.noData:
        _setSynced('Cloud is ready for your first saved progress.');
        return;
      case ProgressSyncAction.alreadySynchronized:
        final remote = assessment.cloud.snapshot!;
        await _record(remote.contentFingerprint, remote.cloudRevision);
        _setSynced();
        return;
      case ProgressSyncAction.uploadLocal:
        final before = assessment.local!;
        final latest = await _local!.loadSnapshot();
        if (latest == null ||
            latest.revision != before.revision ||
            latest.contentFingerprint != before.contentFingerprint) {
          _rerunRequested = true;
          return;
        }
        try {
          final written = await _cloud!.write(
            protectedPlayerId: _protectedPlayerId!,
            local: latest,
            expectedCloudRevision: assessment.cloud.snapshot?.cloudRevision,
          );
          if (revision != _selectionRevision) return;
          await _record(written.contentFingerprint, written.cloudRevision);
          _setSynced();
        } on CloudProgressWriteConflict {
          _rerunRequested = true;
        }
        return;
      case ProgressSyncAction.downloadCloud:
        final expected = assessment.cloud.snapshot!;
        final fresh = await _cloud!.read(_protectedPlayerId!);
        final remote = fresh.snapshot;
        if (fresh.state != CloudProgressState.present ||
            remote == null ||
            remote.cloudRevision != expected.cloudRevision ||
            remote.contentFingerprint != expected.contentFingerprint) {
          _rerunRequested = true;
          return;
        }
        if (!await _applyCloud!(remote.state) ||
            revision != _selectionRevision) {
          return;
        }
        final applied = await _local!.loadSnapshot();
        if (applied == null) throw StateError('Cloud restore was not saved.');
        await _record(remote.contentFingerprint, remote.cloudRevision);
        if (applied.contentFingerprint == remote.contentFingerprint) {
          _setSynced();
        } else {
          _rerunRequested = true;
        }
        return;
      case ProgressSyncAction.requirePlayerChoice:
        _conflict = assessment;
        _setConflict(
          'This device and the cloud both contain different progress. Choose which one to keep.',
        );
        return;
    }
  }

  Future<void> _record(String fingerprint, int cloudRevision) {
    return _checkpoints!.write(
      ProgressSyncCheckpoint(
        contentFingerprint: fingerprint,
        cloudRevision: cloudRevision,
        recordedAt: DateTime.now().toUtc(),
      ),
    );
  }

  void _scheduleRetry() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 15), synchronize);
  }

  void _setSyncing(String message) => _setState(
    ProgressSyncState(status: ProgressSyncStatus.syncing, message: message),
  );

  void _setSynced([
    String message =
        'Progress is synced for this guest identity on this device.',
  ]) => _setState(
    ProgressSyncState(status: ProgressSyncStatus.synced, message: message),
  );

  void _setConflict(String message) => _setState(
    ProgressSyncState(status: ProgressSyncStatus.conflict, message: message),
  );

  void _setError() {
    _setState(
      const ProgressSyncState(
        status: ProgressSyncStatus.error,
        message: 'Progress is safe on this device. Cloud sync will retry.',
      ),
    );
    _scheduleRetry();
  }

  void _setState(ProgressSyncState value) {
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
