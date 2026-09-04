/// The safe next action when local progress and protected cloud progress meet.
enum ProgressSyncAction {
  waitForCloud,
  noData,
  alreadySynchronized,
  uploadLocal,
  downloadCloud,
  requirePlayerChoice,
}

/// The result of reading the protected cloud document.
///
/// Unknown includes timeouts, offline state, permission failures, and any read
/// that did not positively prove whether a document exists.
enum CloudProgressState { unknown, missing, present }

/// Metadata needed to compare a local save with a protected cloud save.
///
/// Fingerprints represent canonical progress content, not account/profile
/// metadata. The sync implementation will persist the fingerprint and cloud
/// revision it last acknowledged so it can identify a shared ancestor.
class ProgressSyncContext {
  const ProgressSyncContext({
    this.cloudState = CloudProgressState.unknown,
    this.localFingerprint,
    this.cloudFingerprint,
    this.cloudRevision,
    this.lastSyncedFingerprint,
    this.lastSyncedCloudRevision,
  }) : assert(
         cloudState == CloudProgressState.present
             ? cloudFingerprint != null && cloudRevision != null
             : cloudFingerprint == null && cloudRevision == null,
         'Cloud metadata must be supplied only for a confirmed present read.',
       ),
       assert(
         cloudRevision == null || cloudRevision >= 0,
         'Cloud revision cannot be negative.',
       ),
       assert(
         lastSyncedCloudRevision == null || lastSyncedCloudRevision >= 0,
         'Last synced cloud revision cannot be negative.',
       );

  final CloudProgressState cloudState;
  final String? localFingerprint;
  final String? cloudFingerprint;
  final int? cloudRevision;
  final String? lastSyncedFingerprint;
  final int? lastSyncedCloudRevision;

  bool get hasLocal => localFingerprint != null;
  bool get hasCloud => cloudState == CloudProgressState.present;
}

/// Chooses only actions that cannot silently discard divergent progress.
abstract final class ProgressSyncPlanner {
  static ProgressSyncAction plan(ProgressSyncContext context) {
    if (context.cloudState == CloudProgressState.unknown) {
      return ProgressSyncAction.waitForCloud;
    }
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
