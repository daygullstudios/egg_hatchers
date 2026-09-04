import 'package:egg_hatchers/models/progress_sync_checkpoint.dart';
import 'package:egg_hatchers/services/account_storage.dart';
import 'package:egg_hatchers/services/progress_sync_checkpoint_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const fingerprintA =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const fingerprintB =
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('checkpoints round-trip independently for each local account', () async {
    final first = ProgressSyncCheckpointStore(accountId: 'player_a');
    final second = ProgressSyncCheckpointStore(accountId: 'player_b');
    await first.write(
      ProgressSyncCheckpoint(
        contentFingerprint: fingerprintA,
        cloudRevision: 7,
        recordedAt: DateTime.utc(2026, 9, 4),
      ),
    );
    await second.write(
      ProgressSyncCheckpoint(
        contentFingerprint: fingerprintB,
        cloudRevision: 2,
        recordedAt: DateTime.utc(2026, 9, 5),
      ),
    );

    final restoredFirst = await first.read();
    final restoredSecond = await second.read();
    expect(restoredFirst!.contentFingerprint, fingerprintA);
    expect(restoredFirst.cloudRevision, 7);
    expect(restoredFirst.recordedAt, DateTime.utc(2026, 9, 4));
    expect(restoredSecond!.contentFingerprint, fingerprintB);
    expect(restoredSecond.cloudRevision, 2);
  });

  test('malformed or unsupported checkpoints are ignored', () async {
    SharedPreferences.setMockInitialValues({
      'egg_hatchers.sync_checkpoint.v1.account.player_a':
          '{"schemaVersion":99,"cloudRevision":4}',
      'egg_hatchers.sync_checkpoint.v1.account.player_b': '{not-json',
    });

    expect(
      await ProgressSyncCheckpointStore(accountId: 'player_a').read(),
      isNull,
    );
    expect(
      await ProgressSyncCheckpointStore(accountId: 'player_b').read(),
      isNull,
    );
  });

  test('invalid checkpoint cannot replace a valid acknowledgement', () async {
    final store = ProgressSyncCheckpointStore(accountId: 'player_a');
    final valid = ProgressSyncCheckpoint(
      contentFingerprint: fingerprintA,
      cloudRevision: 1,
      recordedAt: DateTime.utc(2026),
    );
    await store.write(valid);

    await expectLater(
      store.write(
        ProgressSyncCheckpoint(
          contentFingerprint: 'not-a-sha-256',
          cloudRevision: 2,
          recordedAt: DateTime.utc(2026),
        ),
      ),
      throwsArgumentError,
    );
    expect((await store.read())!.cloudRevision, 1);
  });

  test('account deletion clears its sync ancestry metadata', () async {
    final store = ProgressSyncCheckpointStore(accountId: 'delete_me');
    await store.write(
      ProgressSyncCheckpoint(
        contentFingerprint: fingerprintA,
        cloudRevision: 3,
        recordedAt: DateTime.utc(2026),
      ),
    );

    await AccountStorage.deleteAccountData('delete_me');

    expect(await store.read(), isNull);
  });
}
