import 'dart:convert';

import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/services/save_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const accountId = 'backup_test';
  const primaryKey = 'egg_hatchers_player_state_account_$accountId';
  const backupKey = '${primaryKey}_backup';

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('loads a legacy raw PlayerState save without changing it', () async {
    final legacyState = GameData.startingPlayerState().copyWith(coins: 777);
    SharedPreferences.setMockInitialValues({
      primaryKey: jsonEncode(legacyState.toJson()),
    });

    final loaded = await SaveService(accountId: accountId).load();

    expect(loaded, isNotNull);
    expect(loaded!.coins, 777);
    final preferences = await SharedPreferences.getInstance();
    final stored = jsonDecode(preferences.getString(primaryKey)!);
    expect(stored['coins'], 777);
    expect(stored.containsKey('format'), isFalse);
  });

  test(
    'writes a versioned progress envelope with increasing revisions',
    () async {
      final saves = SaveService(accountId: accountId);
      await saves.save(GameData.startingPlayerState().copyWith(coins: 123));

      final preferences = await SharedPreferences.getInstance();
      final first = jsonDecode(preferences.getString(primaryKey)!);
      expect(first['format'], SaveService.progressFormat);
      expect(first['schemaVersion'], SaveService.progressSchemaVersion);
      expect(first['revision'], 1);
      expect(first['savedAt'], isA<String>());
      expect(first['playerState']['coins'], 123);

      await saves.save(GameData.startingPlayerState().copyWith(coins: 456));
      final second = jsonDecode(preferences.getString(primaryKey)!);
      expect(second['revision'], 2);
      expect(second['playerState']['coins'], 456);
      expect((await saves.load())!.coins, 456);
    },
  );

  test('upgrades a legacy save on the next normal save', () async {
    final legacyState = GameData.startingPlayerState().copyWith(coins: 12);
    SharedPreferences.setMockInitialValues({
      primaryKey: jsonEncode(legacyState.toJson()),
    });

    final saves = SaveService(accountId: accountId);
    final loaded = await saves.load();
    await saves.save(loaded!.copyWith(coins: 34));

    final preferences = await SharedPreferences.getInstance();
    final upgraded = jsonDecode(preferences.getString(primaryKey)!);
    final backup = jsonDecode(preferences.getString(backupKey)!);
    expect(upgraded['format'], SaveService.progressFormat);
    expect(upgraded['revision'], 1);
    expect(upgraded['playerState']['coins'], 34);
    expect(backup['coins'], 12);
  });

  test('corrupt primary save recovers the previous valid snapshot', () async {
    final saves = SaveService(accountId: accountId);
    await saves.save(GameData.startingPlayerState().copyWith(coins: 321));
    await saves.save(GameData.startingPlayerState().copyWith(coins: 654));

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(primaryKey, '{not valid json');

    final recovered = await saves.load();

    expect(recovered, isNotNull);
    expect(recovered!.coins, 321);
    expect(preferences.getString(primaryKey), preferences.getString(backupKey));
  });

  test('deleting an account removes its primary and backup saves', () async {
    final saves = SaveService(accountId: accountId);
    await saves.save(GameData.startingPlayerState().copyWith(coins: 1));
    await saves.save(GameData.startingPlayerState().copyWith(coins: 2));

    await saves.delete();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey(primaryKey), isFalse);
    expect(preferences.containsKey(backupKey), isFalse);
  });
}
