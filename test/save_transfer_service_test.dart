import 'dart:convert';

import 'package:egg_hatchers/services/save_transfer_service.dart';
import 'package:egg_hatchers/services/device_guest_slot_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const accountId = 'player_test';
  final accounts = jsonEncode([
    {
      'id': accountId,
      'displayName': 'Test Player',
      'username': 'test_player',
      'avatarColorValue': 0xFF5271FF,
      'createdAt': '2026-09-04T12:00:00.000Z',
    },
  ]);

  test('exports and restores every supported preference type', () async {
    SharedPreferences.setMockInitialValues({
      'playerAccounts': accounts,
      'egg_hatchers_player_state_account_$accountId': '{"coins":42}',
      'audioMusicEnabled': true,
      'audioMusicVolume': 0.75,
      'testCounter': 7,
      'testList': <String>['one', 'two'],
      '${DeviceGuestSlotStore.keyPrefix}firebase_uid': 'do-not-transfer',
    });
    final service = SaveTransferService();
    final save = await service.exportSave(activeAccountId: accountId);
    final exportedPreferences =
        (jsonDecode(save) as Map<String, dynamic>)['preferences']
            as Map<String, dynamic>;
    expect(
      exportedPreferences.keys.where(DeviceGuestSlotStore.ownsKey),
      isEmpty,
    );

    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await preferences.setString('staleValue', 'remove me');

    final accountCount = await service.importSave(save);
    expect(accountCount, 1);
    expect(preferences.getString('playerAccounts'), accounts);
    expect(preferences.getBool('audioMusicEnabled'), isTrue);
    expect(preferences.getDouble('audioMusicVolume'), 0.75);
    expect(preferences.getInt('testCounter'), 7);
    expect(preferences.getStringList('testList'), ['one', 'two']);
    expect(preferences.containsKey('staleValue'), isFalse);
    expect(
      preferences.getString('${DeviceGuestSlotStore.keyPrefix}firebase_uid'),
      isNull,
    );
    expect(await DeviceGuestSlotStore().read(), isNull);
    expect(await DeviceGuestSlotStore().currentGeneration(), 1);
  });

  test('rejects a malformed save before changing local data', () async {
    SharedPreferences.setMockInitialValues({'keepMe': 'still here'});
    final service = SaveTransferService();

    expect(
      () => service.importSave('{"format":"something_else"}'),
      throwsA(isA<SaveTransferException>()),
    );

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('keepMe'), 'still here');
  });
}
