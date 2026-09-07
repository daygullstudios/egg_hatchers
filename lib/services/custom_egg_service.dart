import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/custom_egg.dart';
import 'account_storage.dart';
import 'custom_content_store.dart';
import 'save_import_storage.dart';

/// Checked device-local eggs, retaining unknown fields and records.
class CustomEggService extends ChangeNotifier {
  CustomEggService({this.storage});
  final SaveImportStorage? storage;
  static const _storageKey = 'customEggs';
  List<CustomEgg> _eggs = [];
  Object _session = Object();
  Object get sessionToken => _session;
  CustomContentStore? _store;
  String _key = _storageKey;
  Future<void>? _pending;
  bool _disposed = false;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  bool get isSaving => _pending != null;
  List<CustomEgg> get allEggs =>
      List.unmodifiable(_eggs.map((egg) => CustomEgg.fromJson(egg.toJson())));

  List<CustomEgg> shopEggs(int lifetimeCoinsEarned, {int rebirthLevel = 0}) =>
      allEggs
          .where(
            (egg) => egg.isShopValid(
              lifetimeCoinsEarned,
              rebirthLevel: rebirthLevel,
            ),
          )
          .toList();

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
    final key = AccountStorage.key(_storageKey, accountId);
    final store = CustomContentStore(
      storage ?? PreferencesKeyStorage({key, _storageKey}),
    );
    final values = await store.load();
    Object? checkedRaw(Object? value) {
      if (value != null && value is! String) {
        throw const CustomContentException(
          'Custom egg storage has an unreadable type. The original record was not changed.',
        );
      }
      return value;
    }

    var raw = checkedRaw(values[key]);
    if (raw == null && accountId != null && migrateLegacyData) {
      raw = checkedRaw(values[_storageKey]);
      if (raw != null) await store.put(key, raw);
    }
    // The existing empty namespace is also the legacy-adoption boundary. A new
    // player must not adopt another player's legacy eggs on the next startup.
    if (raw == null && accountId != null) {
      raw = '[]';
      await store.put(key, raw);
    }
    if (_disposed || !identical(session, _session)) return;
    _key = key;
    _store = store;
    _eggs = raw is String ? CustomEgg.listFromJsonString(raw) : [];
    _isInitialized = true;
    notifyListeners();
  }

  CustomEgg? getById(String id) {
    for (final egg in _eggs) {
      if (egg.id == id) return CustomEgg.fromJson(egg.toJson());
    }
    return null;
  }

  Future<void> saveEgg(CustomEgg egg, {Object? expectedSession}) => _change(
    egg.id,
    jsonDecode(jsonEncode(egg.toJson())) as Map<String, dynamic>,
    expectedSession,
  );
  Future<void> deleteEgg(String id, {Object? expectedSession}) =>
      _change(id, null, expectedSession);

  Future<void> _change(
    String id,
    Map<String, dynamic>? replacement,
    Object? expected,
  ) async {
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
    final key = _key;
    // Merge against a freshly checked copy, including an uncertain prior write.
    final work = store.update(key, (raw) {
      // Never normalize a corrupt document into an empty list and erase it.
      List<dynamic> records;
      try {
        records = raw == null
            ? []
            : List<dynamic>.from(jsonDecode(raw as String) as List);
      } catch (_) {
        throw const CustomContentException(
          'Saved custom eggs could not be read safely. Your draft is kept; the existing data was not replaced.',
        );
      }
      final index = records.indexWhere((r) => r is Map && r['id'] == id);
      if (records.where((r) => r is Map && r['id'] == id).length > 1) {
        throw const CustomContentException(
          'Duplicate saved egg identifiers need recovery. Existing data was not replaced.',
        );
      }
      if (replacement == null) {
        if (index >= 0) records.removeAt(index);
      } else if (index >= 0) {
        final previous = Map<String, dynamic>.from(records[index] as Map);
        if (!replacement.containsKey('animalWeights')) {
          previous.remove('animalWeights');
        }
        records[index] = {...previous, ...replacement};
      } else {
        records.add(replacement);
      }
      return jsonEncode(records);
    });
    _pending = work.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    notifyListeners();
    try {
      final encoded = (await work) as String;
      if (_disposed || !identical(session, _session)) {
        throw const CustomContentException(
          'The original player was saved, but the active player changed.',
        );
      }
      _eggs = CustomEgg.listFromJsonString(encoded);
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
