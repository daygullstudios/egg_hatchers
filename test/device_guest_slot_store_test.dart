import 'package:egg_hatchers/models/player_account.dart';
import 'package:egg_hatchers/services/device_guest_slot_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  PlayerAccount account(String id, {required bool isGuest}) => PlayerAccount(
    id: id,
    displayName: isGuest ? 'Guest Hatcher' : 'Named Player',
    username: isGuest ? 'guest_test' : 'named_player',
    avatarColorValue: 0xFF5271FF,
    createdAt: DateTime.utc(2026, 9, 5),
    isGuest: isGuest,
  );

  test('exactly one guest becomes the durable device guest', () async {
    final store = DeviceGuestSlotStore();
    final slot = await store.ensureForAccounts([
      account('guest_one', isGuest: true),
      account('player_one', isGuest: false),
    ]);

    expect(slot?.accountId, 'guest_one');
    expect(slot?.generation, 1);
    expect((await store.read())?.accountId, 'guest_one');
  });

  test('a named local profile is never inferred as device guest', () async {
    final slot = await DeviceGuestSlotStore().ensureForAccounts([
      account('player_one', isGuest: false),
    ]);

    expect(slot, isNull);
  });

  test(
    'multiple legacy guests fail closed instead of sharing identity',
    () async {
      final store = DeviceGuestSlotStore();
      final slot = await store.ensureForAccounts([
        account('guest_one', isGuest: true),
        account('guest_two', isGuest: true),
      ]);

      expect(slot, isNull);
      expect(await store.read(), isNull);
    },
  );

  test('replacing a guest rotates generation and clears its UID', () async {
    final store = DeviceGuestSlotStore();
    await store.activate('guest_one');
    await store.bindFirebaseUid(
      accountId: 'guest_one',
      firebaseUid: 'firebase-user-one',
    );

    final replacement = await store.activate('guest_two');

    expect(replacement.accountId, 'guest_two');
    expect(replacement.generation, 2);
    expect(replacement.firebaseUid, isNull);
  });

  test('only the designated guest may bind a Firebase UID', () async {
    final store = DeviceGuestSlotStore();
    await store.activate('guest_one');

    await expectLater(
      store.bindFirebaseUid(
        accountId: 'guest_two',
        firebaseUid: 'firebase-user-two',
      ),
      throwsStateError,
    );
    final bound = await store.bindFirebaseUid(
      accountId: 'guest_one',
      firebaseUid: 'firebase-user-one',
    );
    expect(bound.firebaseUid, 'firebase-user-one');
  });
}
