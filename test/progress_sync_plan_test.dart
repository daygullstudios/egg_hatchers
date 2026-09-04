import 'package:egg_hatchers/models/progress_sync_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects incomplete cloud metadata', () {
    expect(
      () => ProgressSyncContext(
        cloudState: CloudProgressState.present,
        cloudFingerprint: 'cloud-without-revision',
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  test('unknown cloud state never authorizes a local upload', () {
    expect(
      ProgressSyncPlanner.plan(
        const ProgressSyncContext(localFingerprint: 'valuable-local-save'),
      ),
      ProgressSyncAction.waitForCloud,
    );
  });

  test('starts empty when neither side has progress', () {
    expect(
      ProgressSyncPlanner.plan(
        const ProgressSyncContext(cloudState: CloudProgressState.missing),
      ),
      ProgressSyncAction.noData,
    );
  });

  test('uploads an existing guest save when cloud progress is empty', () {
    expect(
      ProgressSyncPlanner.plan(
        const ProgressSyncContext(
          cloudState: CloudProgressState.missing,
          localFingerprint: 'local-a',
        ),
      ),
      ProgressSyncAction.uploadLocal,
    );
  });

  test('downloads protected progress onto a device with no local save', () {
    expect(
      ProgressSyncPlanner.plan(
        const ProgressSyncContext(
          cloudState: CloudProgressState.present,
          cloudFingerprint: 'cloud-a',
          cloudRevision: 4,
        ),
      ),
      ProgressSyncAction.downloadCloud,
    );
  });

  test('matching content is already synchronized', () {
    expect(
      ProgressSyncPlanner.plan(
        const ProgressSyncContext(
          cloudState: CloudProgressState.present,
          localFingerprint: 'same',
          cloudFingerprint: 'same',
          cloudRevision: 8,
        ),
      ),
      ProgressSyncAction.alreadySynchronized,
    );
  });

  test('first link never chooses between two different saves silently', () {
    expect(
      ProgressSyncPlanner.plan(
        const ProgressSyncContext(
          cloudState: CloudProgressState.present,
          localFingerprint: 'guest-progress',
          cloudFingerprint: 'existing-protected-progress',
          cloudRevision: 3,
        ),
      ),
      ProgressSyncAction.requirePlayerChoice,
    );
  });

  test('uploads when only local progress changed from the common ancestor', () {
    expect(
      ProgressSyncPlanner.plan(
        const ProgressSyncContext(
          cloudState: CloudProgressState.present,
          localFingerprint: 'local-new',
          cloudFingerprint: 'shared-old',
          cloudRevision: 6,
          lastSyncedFingerprint: 'shared-old',
          lastSyncedCloudRevision: 6,
        ),
      ),
      ProgressSyncAction.uploadLocal,
    );
  });

  test(
    'downloads when only cloud progress changed from the common ancestor',
    () {
      expect(
        ProgressSyncPlanner.plan(
          const ProgressSyncContext(
            cloudState: CloudProgressState.present,
            localFingerprint: 'shared-old',
            cloudFingerprint: 'cloud-new',
            cloudRevision: 7,
            lastSyncedFingerprint: 'shared-old',
            lastSyncedCloudRevision: 6,
          ),
        ),
        ProgressSyncAction.downloadCloud,
      );
    },
  );

  test('requires a choice when local and cloud both changed', () {
    expect(
      ProgressSyncPlanner.plan(
        const ProgressSyncContext(
          cloudState: CloudProgressState.present,
          localFingerprint: 'local-new',
          cloudFingerprint: 'cloud-new',
          cloudRevision: 7,
          lastSyncedFingerprint: 'shared-old',
          lastSyncedCloudRevision: 6,
        ),
      ),
      ProgressSyncAction.requirePlayerChoice,
    );
  });
}
