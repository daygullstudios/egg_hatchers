import 'package:flutter/foundation.dart';
import '../data/game_data.dart';
import '../models/custom_sprite_data.dart';
import 'account_storage.dart';
import 'custom_content_store.dart';
import 'device_settings_store.dart';
import 'save_import_storage.dart';

class CustomSpriteService extends ChangeNotifier {
  CustomSpriteService({DeviceSettingsStore? settingsStore, this.storage})
    : _settingsStore = settingsStore ?? DeviceSettingsStore();
  final DeviceSettingsStore _settingsStore;
  final SaveImportStorage? storage;
  final Map<String, CustomSpriteData> _sprites = {};
  Object _session = Object();
  Object get sessionToken => _session;
  String? _accountId;
  CustomContentStore? _store;
  Future<void>? _pending;
  bool _disposed = false;
  bool _showCustomSprites = true;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  bool get isSaving => _pending != null;
  bool get showCustomSprites => _showCustomSprites;
  bool getShowCustomSprites() => _showCustomSprites;
  String _key(String id, String? account) =>
      AccountStorage.itemKey('customSprite', id, account);

  Future<void> initialize({
    String? accountId,
    bool migrateLegacyData = false,
  }) async {
    final session = _session = Object();
    _isInitialized = false;
    try {
      await _pending;
    } catch (_) {
      /* The editor owns its failure. */
    }
    final migrationKey = AccountStorage.key(
      'customSpriteMigrationComplete',
      accountId,
    );
    final store = CustomContentStore(
      storage ??
          PreferencesKeyStorage({
            migrationKey,
            for (final animal in GameData.animals) ...{
              _key(animal.id, accountId),
              _key(animal.id, null),
            },
          }),
    );
    final values = await store.load();
    if (values[migrationKey] != null && values[migrationKey] is! bool) {
      throw const CustomContentException(
        'Custom animal migration status could not be read. The original record was not changed.',
      );
    }
    final settings = await _settingsStore.read(includePending: true);
    final migrate =
        accountId != null && migrateLegacyData && values[migrationKey] != true;
    final sprites = <String, CustomSpriteData>{};
    for (final animal in GameData.animals) {
      final key = _key(animal.id, accountId);
      var raw = values[key];
      final copyLegacy = raw == null && migrate;
      if (copyLegacy) {
        raw = values[_key(animal.id, null)];
      }
      if (raw != null && raw is! String) {
        throw const CustomContentException(
          'Custom animal storage has an unreadable type. The original record was not changed.',
        );
      }
      if (copyLegacy) {
        // Preserve unreadable raw legacy records; never mark a failed copy complete.
        if (raw != null) await store.put(key, raw);
      }
      if (raw is! String) continue;
      try {
        final sprite = CustomSpriteData.fromJsonString(raw);
        if (sprite.hasVisiblePixels) sprites[animal.id] = sprite;
      } catch (_) {
        /* Keep raw storage untouched. */
      }
    }
    if (accountId != null && values[migrationKey] != true) {
      await store.put(migrationKey, true);
    }
    if (_disposed || !identical(session, _session)) return;
    _accountId = accountId;
    _store = store;
    _sprites
      ..clear()
      ..addAll(sprites);
    _showCustomSprites = settings.showCustomSprites;
    _isInitialized = true;
    notifyListeners();
  }

  CustomSpriteData? getSprite(String id) => _sprites[id]?.copyWith();
  CustomSpriteData? getDisplaySprite(String id) =>
      _showCustomSprites ? getSprite(id) : null;
  bool hasCustomSprite(String id) => _sprites.containsKey(id);
  Future<bool> setShowCustomSprites(bool value) async {
    _showCustomSprites = value;
    notifyListeners();
    return _settingsStore.writeShowCustomSprites(value);
  }

  Future<void> saveSprite(
    String id,
    CustomSpriteData data, {
    Object? expectedSession,
  }) => _change({
    id: data.hasVisiblePixels ? data.toJsonString() : null,
  }, expectedSession);
  Future<void> resetSprite(String id, {Object? expectedSession}) =>
      _change({id: null}, expectedSession);
  Future<void> resetAllCustomSprites({Object? expectedSession}) => _change(
    {for (final animal in GameData.animals) animal.id: null},
    expectedSession,
    bulk: true,
  );

  Future<void> _change(
    Map<String, String?> changes,
    Object? expected, {
    bool bulk = false,
  }) async {
    if (!_isInitialized ||
        _disposed ||
        isSaving ||
        (expected != null && !identical(expected, _session))) {
      throw const CustomContentException(
        'The player changed or another custom save is pending. Keep your draft open.',
      );
    }
    final session = _session;
    final store = _store!;
    final account = _accountId;
    Future<void> apply() async {
      var removed = 0;
      for (final entry in changes.entries) {
        if (_disposed || !identical(session, _session)) {
          throw const CustomContentException(
            'The active player changed. No further custom changes were made.',
          );
        }
        try {
          await store.put(_key(entry.key, account), entry.value);
        } on CustomContentException catch (error) {
          if (!bulk) rethrow;
          throw CustomContentException(
            'Reset stopped: $removed custom drawings confirmed removed in this attempt. '
            'Other entries remain, or removal is unconfirmed. Retry Reset All to check the remaining entries. ${error.message}',
          );
        }
        if (_disposed || !identical(session, _session)) {
          throw const CustomContentException(
            'The original player was saved, but the active player changed.',
          );
        }
        if (entry.value == null) {
          if (_sprites.remove(entry.key) != null) removed++;
        } else {
          _sprites[entry.key] = CustomSpriteData.fromJsonString(entry.value!);
        }
        notifyListeners();
      }
    }

    final work = apply();
    _pending = work;
    notifyListeners();
    try {
      await work;
    } finally {
      _pending = null;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _session = Object();
    super.dispose();
  }
}
