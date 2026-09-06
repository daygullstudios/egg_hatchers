enum ProgressSyncStatus {
  unavailable,
  pending,
  syncing,
  synced,
  conflict,
  error,
}

class ProgressSyncState {
  const ProgressSyncState({required this.status, required this.message});

  const ProgressSyncState.unavailable()
    : this(
        status: ProgressSyncStatus.unavailable,
        message: 'Progress is currently stored only on this device.',
      );

  final ProgressSyncStatus status;
  final String message;

  bool get hasConflict => status == ProgressSyncStatus.conflict;

  String get label => switch (status) {
    ProgressSyncStatus.unavailable => 'Device progress',
    ProgressSyncStatus.pending => 'Cloud sync pending',
    ProgressSyncStatus.syncing => 'Syncing progress',
    ProgressSyncStatus.synced => 'Cloud copy current',
    ProgressSyncStatus.conflict => 'Choose progress',
    ProgressSyncStatus.error => 'Sync issue',
  };
}
