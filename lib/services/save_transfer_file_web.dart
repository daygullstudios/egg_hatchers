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
  subscription = input.onChange.listen((_) async {
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
      await subscription.cancel();
      input.remove();
    }
  });

  input.click();
  return completer.future;
}

Future<void> copySaveText(String contents) async {
  await web.window.navigator.clipboard.writeText(contents).toDart;
}

void reloadAfterSaveImport() => web.window.location.reload();
