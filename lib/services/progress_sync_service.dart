import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/cloud_progress_read.dart';
import '../models/player_state.dart';
import '../models/progress_conflict_review.dart';
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
  ProgressSyncService({
    this.debounce = const Duration(seconds: 2),
    ProgressSyncCheckpointStore Function(String)? checkpointFactory,
  }) : _checkpointFactory =
           checkpointFactory ??
           ((id) => ProgressSyncCheckpointStore(accountId: id));

  final Duration debounce;
  final ProgressSyncCheckpointStore Function(String) _checkpointFactory;
  ProgressSyncState _state = const ProgressSyncState.unavailable();
  Timer? _timer;
  String? _accountId;
  String? _protectedPlayerId;
  SaveService? _local;
  ProgressSyncCheckpointStore? _checkpoints;
  CloudProgressRepository? _cloud;
  ApplyCloudProgress? _applyCloud;
  ProgressSyncAssessment? _conflict;
  ProgressConflictReview? _activeReview;
  var _selectionRevision = 0;
  var _syncing = false;
  var _rerunRequested = false;
  var _pausedForImport = false;
  var _localPersistencePaused = false;
  var _disposed = false;
  var _checkpointIssue = false;
  var _checkpointChanged = false;
  ProgressSyncCheckpoint? _pendingRecord;
  Timer? _checkpointTimer;

  /// Preserve a pending choice, but invalidate cloud work while local writes
  /// are unverified. This is not permission to upload an in-memory-only save.
  void setLocalPersistencePaused(bool paused) {
    if (_localPersistencePaused == paused) return;
    _localPersistencePaused = paused;
    _selectionRevision++;
    _timer?.cancel();
    _activeReview = null;
    _rerunRequested = false;
    if (paused) {
      _setState(
        const ProgressSyncState(
          status: ProgressSyncStatus.error,
          message: 'Local saving needs attention. Cloud changes are paused.',
        ),
      );
    } else if (_checkpointIssue || _pendingRecord != null) {
      _checkpointIssue = true;
      _showCheckpointIssue();
    } else if (_conflict != null) {
      _setConflict(
        'This device and the cloud contain different progress. Compare saves before choosing.',
      );
    } else {
      localProgressSaved(_accountId);
    }
  }

  Completer<void>? _importDrain;

  /// Permanently quiesce this runtime; only a fresh app may resume syncing.
  Future<void> pauseForSaveImport() async {
    _pausedForImport = true;
    _selectionRevision++;
    _timer?.cancel();
    _activeReview = null;
    _rerunRequested = false;
    if (_syncing) {
      _importDrain ??= Completer<void>();
      await _importDrain!.future;
    }
  }

  ProgressSyncState get state => _state;

  Future<void> selectAccount({
    required String? accountId,
    required String? protectedPlayerId,
    CloudProgressRepository? cloud,
    ApplyCloudProgress? applyCloud,
  }) async {
    if (_disposed) return;
    _selectionRevision += 1;
    _timer?.cancel();
    _checkpointTimer?.cancel();
    _pendingRecord = null;
    _checkpointIssue = false;
    _checkpointChanged = false;
    _accountId = accountId;
    _protectedPlayerId = protectedPlayerId;
    _local = accountId == null ? null : SaveService(accountId: accountId);
    _checkpoints = accountId == null ? null : _checkpointFactory(accountId);
    _cloud = cloud;
    _applyCloud = applyCloud;
    _conflict = null;
    _activeReview = null;
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
      !_disposed &&
      !_pausedForImport &&
      !_localPersistencePaused &&
      _accountId != null &&
      _protectedPlayerId != null &&
      _local != null &&
      _checkpoints != null &&
      _cloud != null &&
      _applyCloud != null;

  void localProgressSaved(String? accountId) {
    if (!_isConfigured || accountId != _accountId) return;
    if (_checkpointIssue || _pendingRecord != null) return;
    if (_syncing) {
      _rerunRequested = true;
      return;
    }
    // Income keeps saving locally while a player considers divergent saves.
    // Never hide that decision or restart automatic cloud work behind it.
    if (_conflict != null) return;
    _setState(
      const ProgressSyncState(
        status: ProgressSyncStatus.pending,
        message: 'Saved on this device. Cloud sync is pending…',
      ),
    );
    if (!(_timer?.isActive ?? false)) {
      _timer = Timer(debounce, synchronize);
    }
  }

  Future<void> synchronize() async {
    if (!_isConfigured || _checkpointIssue) return;
    if (_syncing) {
      _rerunRequested = true;
      return;
    }
    if (_conflict != null) return;
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
    } on CheckpointStorageException {
      if (revision == _selectionRevision) {
        _checkpointIssue = true;
        _showCheckpointIssue();
      }
    } catch (_) {
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
      _finishSynchronization();
    }
  }

  /// Reads fresh copies for a decision; never uploads, restores or merges them.
  Future<ProgressConflictReview?> prepareConflictReview() async {
    if (_conflict == null || !_isConfigured || _syncing || _checkpointIssue) {
      return null;
    }
    _activeReview = null;
    final revision = _selectionRevision;
    _syncing = true;
    _setSyncing('Reading both saves for comparison…');
    try {
      final fresh = await _assess();
      if (revision != _selectionRevision) return null;
      final remote = fresh.cloud.snapshot;
      if (fresh.local == null ||
          remote == null ||
          fresh.cloud.state != CloudProgressState.present) {
        throw StateError('Both saves could not be read.');
      }
      _conflict = fresh;
      _activeReview = ProgressConflictReview(
        local: fresh.local!,
        cloud: remote,
      );
      _setConflict(
        'Cloud sync is paused while you compare. This device keeps saving.',
      );
      return _activeReview;
    } on CheckpointStorageException {
      if (revision == _selectionRevision) {
        _checkpointIssue = true;
        _showCheckpointIssue();
      }
      return null;
    } catch (_) {
      if (revision == _selectionRevision) {
        _setConflict(
          'Could not read both saves. Check your connection and compare again.',
        );
      }
      return null;
    } finally {
      _finishSynchronization();
    }
  }

  bool _canResolve(ProgressConflictReview review) =>
      identical(review, _activeReview) &&
      _conflict != null &&
      _isConfigured &&
      !_checkpointIssue &&
      !_syncing;

  bool _matchesReviewedCloud(
    ProgressConflictReview review,
    CloudProgressRead read,
  ) =>
      read.state == CloudProgressState.present &&
      read.snapshot?.cloudRevision == review.cloud.cloudRevision &&
      read.snapshot?.contentFingerprint == review.cloud.contentFingerprint;

  Future<bool> keepThisDevice(ProgressConflictReview review) async {
    final assessment = _conflict;
    if (assessment?.local == null || !_canResolve(review)) return false;
    _activeReview = null;
    _timer?.cancel();
    final revision = _selectionRevision;
    _syncing = true;
    _setSyncing('Saving this device’s progress to the cloud…');
    try {
      final fresh = await _assess();
      if (revision != _selectionRevision) return false;
      if (fresh.local == null ||
          fresh.cloud.state == CloudProgressState.unknown) {
        throw StateError('Cloud state is unavailable.');
      }
      if (!_matchesReviewedCloud(review, fresh.cloud)) {
        _conflict = fresh;
        _setConflict('The cloud save changed. Compare again before choosing.');
        return false;
      }
      final written = await _cloud!.write(
        protectedPlayerId: _protectedPlayerId!,
        local: fresh.local!,
        expectedCloudRevision: fresh.cloud.snapshot?.cloudRevision,
      );
      if (revision != _selectionRevision) return false;
      await _record(
        written.contentFingerprint,
        written.cloudRevision,
        revision,
      );
      if (revision != _selectionRevision) return false;
      _conflict = null;
      await _confirmCurrent(written.contentFingerprint, revision);
      return revision == _selectionRevision && _isConfigured;
    } on CloudProgressWriteConflict {
      if (revision != _selectionRevision) return false;
      _setConflict(
        'Cloud progress changed again. Review your choice once more.',
      );
      return false;
    } on CheckpointStorageException {
      if (revision == _selectionRevision) {
        _checkpointIssue = true;
        _showCheckpointIssue();
      }
      return false;
    } catch (_) {
      if (revision != _selectionRevision) return false;
      _setConflict(
        'Could not finish your choice. Progress is safe on this device. '
        'Check your connection, then choose again.',
      );
      return false;
    } finally {
      _finishSynchronization();
    }
  }

  Future<bool> useCloud(ProgressConflictReview review) async {
    if (!_canResolve(review)) return false;
    _activeReview = null;
    _timer?.cancel();
    final revision = _selectionRevision;
    _syncing = true;
    _setSyncing('Restoring the latest cloud progress…');
    try {
      final fresh = await _assess();
      final read = fresh.cloud;
      if (revision != _selectionRevision) return false;
      final remote = read.snapshot;
      if (read.state != CloudProgressState.present || remote == null) {
        throw StateError('Cloud progress is unavailable.');
      }
      if (!_matchesReviewedCloud(review, read)) {
        _conflict = fresh;
        _setConflict('The cloud save changed. Compare again before choosing.');
        return false;
      }
      final restored = await _applyCloud!(remote.state);
      if (revision != _selectionRevision) return false;
      if (!restored) throw StateError('Cloud restore was not applied.');
      final applied = await _local!.loadSnapshot();
      if (revision != _selectionRevision) return false;
      if (applied == null) throw StateError('Cloud restore was not saved.');
      await _record(remote.contentFingerprint, remote.cloudRevision, revision);
      if (revision != _selectionRevision) return false;
      _conflict = null;
      await _confirmCurrent(remote.contentFingerprint, revision);
      return revision == _selectionRevision && _isConfigured;
    } on CheckpointStorageException {
      if (revision == _selectionRevision) {
        _checkpointIssue = true;
        _showCheckpointIssue();
      }
      return false;
    } catch (_) {
      if (revision != _selectionRevision) return false;
      _setConflict(
        'Could not finish your choice. Progress is safe on this device. '
        'Check your connection, then choose again.',
      );
      return false;
    } finally {
      _finishSynchronization();
    }
  }

  void _finishSynchronization() {
    _syncing = false;
    _importDrain?.complete();
    _importDrain = null;
    final rerun = _rerunRequested;
    _rerunRequested = false;
    // A newly selected account may need the queued pass; an unresolved choice
    // must instead wait for explicit resolution, including after a failed try.
    if (_checkpointIssue && _isConfigured) {
      _showCheckpointIssue();
    } else if (rerun && _isConfigured && _conflict == null) {
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
        if (assessment.checkpoint?.contentFingerprint !=
                remote.contentFingerprint ||
            assessment.checkpoint?.cloudRevision != remote.cloudRevision) {
          await _record(
            remote.contentFingerprint,
            remote.cloudRevision,
            revision,
          );
        }
        await _confirmCurrent(remote.contentFingerprint, revision);
        return;
      case ProgressSyncAction.uploadLocal:
        final before = assessment.local!;
        final latest = await _local!.loadSnapshot();
        if (revision != _selectionRevision) return;
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
          await _record(
            written.contentFingerprint,
            written.cloudRevision,
            revision,
          );
          await _confirmCurrent(written.contentFingerprint, revision);
        } on CloudProgressWriteConflict {
          _rerunRequested = true;
        }
        return;
      case ProgressSyncAction.downloadCloud:
        final expected = assessment.cloud.snapshot!;
        final fresh = await _cloud!.read(_protectedPlayerId!);
        if (revision != _selectionRevision) return;
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
        if (revision != _selectionRevision) return;
        if (applied == null) throw StateError('Cloud restore was not saved.');
        await _record(
          remote.contentFingerprint,
          remote.cloudRevision,
          revision,
        );
        await _confirmCurrent(remote.contentFingerprint, revision);
        return;
      case ProgressSyncAction.requirePlayerChoice:
        _conflict = assessment;
        _setConflict(
          'This device and the cloud both contain different progress. Choose which one to keep.',
        );
        return;
    }
  }

  Future<void> _record(
    String fingerprint,
    int cloudRevision,
    int revision,
  ) async {
    if (revision != _selectionRevision || !_isConfigured) return;
    final record =
        _pendingRecord ??
        ProgressSyncCheckpoint(
          contentFingerprint: fingerprint,
          cloudRevision: cloudRevision,
          recordedAt: DateTime.now().toUtc(),
        );
    final store = _checkpoints!;
    _pendingRecord = record;
    final watchdog = Timer(const Duration(seconds: 8), () {
      if (revision != _selectionRevision || !_isConfigured) return;
      _checkpointIssue = true;
      _showCheckpointIssue();
    });
    _checkpointTimer = watchdog;
    try {
      await store.write(record);
      if (revision != _selectionRevision) return;
      _pendingRecord = null;
      _checkpointIssue = false;
      _checkpointChanged = false;
    } on CheckpointStorageException catch (error) {
      if (revision == _selectionRevision) {
        _checkpointChanged = error.failure == CheckpointStorageFailure.changed;
      }
      rethrow;
    } finally {
      watchdog.cancel();
    }
  }

  /// Finish only the already-confirmed checkpoint before reassessing fresh
  /// device/cloud data. Never repeat a restore/upload merely to retry metadata.
  Future<void> retrySyncConfirmation() async {
    if (!_isConfigured || !_checkpointIssue || _syncing) return;
    _timer?.cancel();
    final revision = _selectionRevision;
    // A changed stored record is not ours to overwrite. Discard only the held
    // acknowledgement and reassess fresh ancestry; never replay the old choice.
    final record = _checkpointChanged ? null : _pendingRecord;
    if (_checkpointChanged) {
      _pendingRecord = null;
      _checkpointChanged = false;
    }
    _syncing = true;
    _showCheckpointIssue();
    try {
      if (record != null) {
        await _record(
          record.contentFingerprint,
          record.cloudRevision,
          revision,
        );
        if (revision != _selectionRevision) return;
        // Any former explicit choice already applied; a fresh assessment below
        // will expose new divergence rather than repeat that old decision.
        _conflict = null;
        _activeReview = null;
      }
      final assessment = await _assess();
      if (revision != _selectionRevision) return;
      _conflict = null;
      _checkpointIssue = false;
      await _applyAssessment(assessment, revision);
    } on CheckpointStorageException {
      if (revision == _selectionRevision) {
        _checkpointIssue = true;
        _showCheckpointIssue();
      }
    } catch (_) {
      if (revision == _selectionRevision) {
        _checkpointIssue = true;
        _showCheckpointIssue();
      }
    } finally {
      _finishSynchronization();
    }
  }

  void _showCheckpointIssue() {
    _timer?.cancel();
    _rerunRequested = false;
    _activeReview = null;
    _setState(
      ProgressSyncState(
        status: ProgressSyncStatus.error,
        checkpointNeedsAttention: true,
        operationPending: _syncing,
        message: _syncing
            ? 'Checking the sync record on this device. Keep the game open; another confirmation will not start while this one is pending.'
            : 'Could not verify the sync record on this device. Your local gameplay save is separate; a cloud update may already have completed. Automatic cloud changes are paused. Retry confirmation before making another save choice. Do not clear app/browser data.',
      ),
    );
  }

  Future<void> _confirmCurrent(String fingerprint, int revision) async {
    if (revision != _selectionRevision || !_isConfigured) return;
    final local = await _local!.loadSnapshot();
    if (revision != _selectionRevision) return;
    if (local?.contentFingerprint == fingerprint) {
      _setSynced();
    } else {
      _rerunRequested = true;
      _setState(
        const ProgressSyncState(
          status: ProgressSyncStatus.pending,
          message:
              'Newer progress is saved on this device. Cloud sync is pending…',
        ),
      );
    }
  }

  void _scheduleRetry() {
    _timer?.cancel();
    if (_pausedForImport ||
        _localPersistencePaused ||
        _checkpointIssue ||
        _disposed) {
      return;
    }
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

  void _setConflict(String message) {
    _timer?.cancel();
    _rerunRequested = false;
    _setState(
      ProgressSyncState(status: ProgressSyncStatus.conflict, message: message),
    );
  }

  void _setState(ProgressSyncState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _selectionRevision++;
    _timer?.cancel();
    _checkpointTimer?.cancel();
    super.dispose();
  }
}
