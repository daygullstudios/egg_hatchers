import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<void> downloadSaveFile(String contents, String fileName) async {
  final blob = web.Blob(
    <web.BlobPart>[contents.toJS].toJS,
    web.BlobPropertyBag(type: 'application/json'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

Future<String?> pickSaveFile() {
  final completer = Completer<String?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.json,application/json'
    ..style.display = 'none';
  web.document.body?.appendChild(input);

  late final StreamSubscription<web.Event> subscription;
  late final JSFunction cancelled;
  var reading = false;
  void cleanUp() {
    unawaited(subscription.cancel());
    input.removeEventListener('cancel', cancelled);
    input.remove();
  }

  void cancel(web.Event _) {
    if (completer.isCompleted || reading) return;
    completer.complete(null);
    cleanUp();
  }

  // The browser emits cancel when its chooser is dismissed without a file.
  cancelled = cancel.toJS;
  input.addEventListener('cancel', cancelled);
  subscription = input.onChange.listen((_) async {
    if (completer.isCompleted || reading) return;
    reading = true;
    final file = input.files?.item(0);
    try {
      if (file == null) {
        completer.complete(null);
      } else {
        final text = (await file.text().toDart).toDart;
        completer.complete(text);
      }
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    } finally {
      cleanUp();
    }
  });

  try {
    input.click();
  } catch (error, stackTrace) {
    completer.completeError(error, stackTrace);
    cleanUp();
  }
  return completer.future;
}

Future<void> copySaveText(String contents) async {
  await web.window.navigator.clipboard.writeText(contents).toDart;
}

void reloadAfterSaveImport() => web.window.location.reload();
