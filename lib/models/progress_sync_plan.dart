/// The safe next action when local progress and protected cloud progress meet.
enum ProgressSyncAction {
  noData,
  alreadySynchronized,
  uploadLocal,
  downloadCloud,
  requirePlayerChoice,
}

/// Metadata needed to compare a local save with a protected cloud save.
///
/// Fingerprints represent canonical progress content, not account/profile
/// metadata. The sync implementation will persist the fingerprint and cloud
/// revision it last acknowledged so it can identify a shared ancestor.
class ProgressSyncContext {
  const ProgressSyncContext({
    this.localFingerprint,
    this.cloudFingerprint,
    this.cloudRevision,
    this.lastSyncedFingerprint,
    this.lastSyncedCloudRevision,
  }) : assert(
         (cloudFingerprint == null) == (cloudRevision == null),
         'Cloud fingerprint and revision must be supplied together.',
       ),
       assert(
         cloudRevision == null || cloudRevision >= 0,
         'Cloud revision cannot be negative.',
       ),
       assert(
         lastSyncedCloudRevision == null || lastSyncedCloudRevision >= 0,
         'Last synced cloud revision cannot be negative.',
       );

  final String? localFingerprint;
  final String? cloudFingerprint;
  final int? cloudRevision;
  final String? lastSyncedFingerprint;
  final int? lastSyncedCloudRevision;

  bool get hasLocal => localFingerprint != null;
  bool get hasCloud => cloudFingerprint != null && cloudRevision != null;
}

/// Chooses only actions that cannot silently discard divergent progress.
abstract final class ProgressSyncPlanner {
  static ProgressSyncAction plan(ProgressSyncContext context) {
    if (!context.hasLocal && !context.hasCloud) {
      return ProgressSyncAction.noData;
    }
    if (context.hasLocal && !context.hasCloud) {
      return ProgressSyncAction.uploadLocal;
    }
    if (!context.hasLocal && context.hasCloud) {
      return ProgressSyncAction.downloadCloud;
    }
    if (context.localFingerprint == context.cloudFingerprint) {
      return ProgressSyncAction.alreadySynchronized;
    }

    // Without a recorded common ancestor, two different saves must be shown to
    // the player. This is the normal first-link case when both sides have data.
    if (context.lastSyncedFingerprint == null ||
        context.lastSyncedCloudRevision == null) {
      return ProgressSyncAction.requirePlayerChoice;
    }

    final localChanged =
        context.localFingerprint != context.lastSyncedFingerprint;
    final cloudChanged =
        context.cloudRevision != context.lastSyncedCloudRevision;
    if (localChanged && !cloudChanged) {
      return ProgressSyncAction.uploadLocal;
    }
    if (!localChanged && cloudChanged) {
      return ProgressSyncAction.downloadCloud;
    }

    return ProgressSyncAction.requirePlayerChoice;
  }
}
