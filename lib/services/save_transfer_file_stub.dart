Future<void> downloadSaveFile(String contents, String fileName) {
  throw UnsupportedError(
    'Save file downloads are only available in the web game.',
  );
}

Future<String?> pickSaveFile() {
  throw UnsupportedError(
    'Save file imports are only available in the web game.',
  );
}

Future<void> copySaveText(String contents) {
  throw UnsupportedError(
    'Copying save data is only available in the web game.',
  );
}

void reloadAfterSaveImport() {}
