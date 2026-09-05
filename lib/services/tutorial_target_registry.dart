/// Runtime tap handlers for tutorial spotlight targets (proxy tap).
class TutorialTargetRegistry {
  TutorialTargetRegistry._();

  static final Map<String, void Function()> _handlers = {};

  static void register(String targetId, void Function() handler) {
    _handlers[targetId] = handler;
  }

  static void unregister(String targetId, {void Function()? onlyIfHandler}) {
    if (onlyIfHandler != null &&
        !identical(_handlers[targetId], onlyIfHandler)) {
      return;
    }
    _handlers.remove(targetId);
  }

  static void unregisterAll(Iterable<String> targetIds) {
    for (final id in targetIds) {
      _handlers.remove(id);
    }
  }

  static void Function()? handlerFor(String? targetId) {
    if (targetId == null) return null;
    return _handlers[targetId];
  }
}
