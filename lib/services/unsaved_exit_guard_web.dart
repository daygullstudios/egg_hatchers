import 'dart:js_interop';
import 'package:web/web.dart' as web;

bool _enabled = false;
final _listener = ((web.Event event) {
  event.preventDefault();
  (event as web.BeforeUnloadEvent).returnValue = '';
}).toJS;

/// Best-effort browser warning, not a guarantee against force-close or eviction.
void setUnsavedExitGuard(bool enabled) {
  if (_enabled == enabled) return;
  _enabled = enabled;
  if (enabled) {
    web.window.addEventListener('beforeunload', _listener);
  } else {
    web.window.removeEventListener('beforeunload', _listener);
  }
}
