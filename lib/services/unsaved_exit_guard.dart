import 'unsaved_exit_guard_stub.dart'
    if (dart.library.js_interop) 'unsaved_exit_guard_web.dart'
    as platform;

bool _rootUnsaved = false;
final Set<Object> _drafts = {};
bool get hasOpenCustomDrafts => _drafts.isNotEmpty;

void setUnsavedExitGuard(bool enabled) {
  _rootUnsaved = enabled;
  platform.setUnsavedExitGuard(_rootUnsaved || _drafts.isNotEmpty);
}

void setDraftExitGuard(Object owner, bool enabled) {
  if (enabled) {
    _drafts.add(owner);
  } else {
    _drafts.remove(owner);
  }
  platform.setUnsavedExitGuard(_rootUnsaved || _drafts.isNotEmpty);
}
