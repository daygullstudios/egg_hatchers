import 'player_state.dart';
import 'progress_sync_plan.dart';

class CloudProgressSnapshot {
  const CloudProgressSnapshot({
    required this.state,
    required this.contentFingerprint,
    required this.cloudRevision,
    required this.savedAt,
  });

  final PlayerState state;
  final String contentFingerprint;
  final int cloudRevision;
  final DateTime savedAt;
}

class CloudProgressRead {
  const CloudProgressRead._({required this.state, this.snapshot});

  const CloudProgressRead.unknown() : this._(state: CloudProgressState.unknown);

  const CloudProgressRead.missing() : this._(state: CloudProgressState.missing);

  const CloudProgressRead.present(CloudProgressSnapshot snapshot)
    : this._(state: CloudProgressState.present, snapshot: snapshot);

  final CloudProgressState state;
  final CloudProgressSnapshot? snapshot;
}
