import 'dart:convert';

import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/services/save_import_storage.dart';
import 'package:egg_hatchers/services/save_transfer_service.dart';

String importFixture({Map<String, Object>? extra, int coins = 420}) =>
    jsonEncode({
      'format': SaveTransferService.formatName,
      'version': 1,
      'activeAccountId': 'imported',
      'exportedAt': '2026-09-06T12:00:00Z',
      'preferences': {
        'playerAccounts': {
          'type': 'string',
          'value': jsonEncode([
            {
              'id': 'imported',
              'displayName': 'Mock Explorer',
              'username': 'explorer',
              'avatarColorValue': 0xFF5271FF,
              'createdAt': '2026-09-01T12:00:00Z',
            },
          ]),
        },
        'egg_hatchers_player_state_account_imported': {
          'type': 'string',
          'value': jsonEncode(
            GameData.startingPlayerState().copyWith(coins: coins).toJson(),
          ),
        },
        ...?extra,
      },
    });

class ImportMemoryStorage implements SaveImportStorage {
  ImportMemoryStorage([Map<String, Object>? initial]) : values = {...?initial};
  final Map<String, Object> values;
  final operations = <String>[];
  int? failAt;
  bool persistFailure = false, wrongReadBack = false, falseAfterRemoval = false;
  int mutations = 0;
  bool _fails() {
    mutations++;
    return mutations == failAt ||
        (persistFailure && failAt != null && mutations >= failAt!);
  }

  @override
  Future<Map<String, Object>> readAll() async => {...values};
  @override
  Future<bool> write(String key, Object value) async {
    operations.add('write:$key');
    if (_fails()) return false;
    values[key] = wrongReadBack && key == SaveTransferService.recoveryKey
        ? 'bad journal'
        : value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    operations.add('remove:$key');
    if (_fails()) return false;
    values.remove(key);
    return !(falseAfterRemoval && key == SaveTransferService.recoveryKey);
  }
}
