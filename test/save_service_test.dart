import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/services/save_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const accountId = 'backup_test';
  const primaryKey = 'egg_hatchers_player_state_account_$accountId';
  const backupKey = '${primaryKey}_backup';

  setUp(() => SharedPreferences.setMockInitialValues({}));

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
