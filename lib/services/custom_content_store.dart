import 'save_import_storage.dart';
import 'save_storage_lease.dart';

class CustomContentException implements Exception {
  const CustomContentException(this.message);
  final String message;
}

/// One loaded player namespace. Never retarget an in-flight write on account switch.
class CustomContentStore {
  CustomContentStore(this.storage);
  final SaveImportStorage storage;
  final Map<String, Object?> _baseline = {};
  final Map<String, Object?> _attempted = {};
  static final Map<String, Future<void>> _queues = {};

  Future<Map<String, Object>> load() async {
    final values = await storage.readAll();
    _baseline.addAll(values);
    return values;
  }

  Future<void> put(String key, Object? value) async {
    await update(key, (_) => value);
  }

  Future<Object?> update(String key, Object? Function(Object?) change) async {
    final previous = _queues[key] ?? Future<void>.value();
    final work = previous.then((_) => _put(key, change));
    final tail = work.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _queues[key] = tail;
    try {
      return await work;
    } finally {
      if (identical(_queues[key], tail)) _queues.remove(key);
    }
  }

  Future<Object?> _put(String key, Object? Function(Object?) change) async {
    Future<void> Function()? release;
    try {
      release = await acquireProgressWriteLease(key);
      final before = (await storage.readAll())[key];
      final value = change(before);
      // An uncertain prior write may already be present: verify, don't replay.
      if (before == value) {
        _baseline[key] = value;
        _attempted.remove(key);
        return value;
      }
      if (before != _baseline[key] &&
          !(_attempted.containsKey(key) && before == _attempted[key])) {
        throw const CustomContentException(
          'Saved custom data changed elsewhere. Your draft is still here. '
          'Keep it open; do not overwrite the other copy.',
        );
      }
      _attempted[key] = value;
      final accepted = value == null
          ? await storage.remove(key)
          : await storage.write(key, value);
      if (!accepted || (await storage.readAll())[key] != value) {
        throw const CustomContentException(
          'Saving could not be confirmed. The device may have applied the change. '
          'Your draft is still here; retry to check before writing again.',
        );
      }
      _baseline[key] = value;
      _attempted.remove(key);
      return value;
    } on CustomContentException {
      rethrow;
    } catch (_) {
      throw const CustomContentException(
        'Custom storage is unavailable. The change may already have applied. '
        'Keep this screen open and retry; refreshing can lose your draft.',
      );
    } finally {
      await release?.call();
    }
  }
}
