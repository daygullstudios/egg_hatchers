bool get saveImportLockAvailable => false;

Future<Future<void> Function()> acquireProgressWriteLease(String key) async =>
    () async {};

Future<Future<void> Function()> acquireSaveImportStagingLease() async =>
    throw UnsupportedError(
      'Save import requires browser storage coordination.',
    );

Future<Future<void> Function()> acquireSaveStorageLease({
  bool exclusive = false,
}) async => () async {};
