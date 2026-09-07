import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/account_session_store.dart';
import '../services/save_storage_lease.dart';
import '../services/save_transfer_file.dart';
import '../services/save_transfer_service.dart';
import '../services/saved_player_directory.dart';
import '../widgets/save_import_review_dialog.dart';

/// Recovery tools do not require a loaded player or touch gameplay/identity.
class SavedPlayerRecoveryScreen extends StatefulWidget {
  const SavedPlayerRecoveryScreen({
    super.key,
    required this.failure,
    required this.onRetry,
    required this.stageImport,
    this.transfer,
    this.pickFile,
    this.download,
    this.copy,
    this.restart,
    this.web = kIsWeb,
    this.canImport,
  });

  final AccountStartupFailure failure;
  final Future<void> Function() onRetry;
  final Future<void> Function(SaveImportPreview) stageImport;
  final SaveTransferService? transfer;
  final Future<String?> Function()? pickFile;
  final Future<void> Function(String, String)? download;
  final Future<void> Function(String)? copy;
  final VoidCallback? restart;
  final bool web;
  final bool? canImport;

  @override
  State<SavedPlayerRecoveryScreen> createState() =>
      _SavedPlayerRecoveryScreenState();
}

class _SavedPlayerRecoveryScreenState extends State<SavedPlayerRecoveryScreen> {
  late final _transfer = widget.transfer ?? SaveTransferService();
  bool _busy = false;
  bool _reviewing = false;
  String? _status;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await action();
    } catch (_) {
      // Storage/file/platform errors can include private player content.
      _status =
          'This action could not finish. Keep your app/browser data and try again. No replacement was requested.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _backup({required bool copy}) => _run(() async {
    // Preserve unreadable directory strings as-is. This is not a repair, and
    // deliberately does not pass through the import validator or game.save().
    final contents = await _transfer.exportSave(
      activeAccountId: readActiveAccountId(),
    );
    if (!mounted) return;
    if (copy) {
      await (widget.copy ??
          (text) => Clipboard.setData(ClipboardData(text: text)))(contents);
      _status =
          'Backup copied. Paste it into a private file and keep it safe. It may still need repair.';
    } else {
      final date = DateTime.now().toIso8601String().split('T').first;
      await (widget.download ?? downloadSaveFile)(
        contents,
        'nestarium-recovery-$date.json',
      );
      _status =
          'Backup download requested. Check that the file was saved; it may still need repair.';
    }
  });

  Future<void> _reviewFile() => _run(() async {
    if (!(widget.canImport ?? saveImportLockAvailable)) {
      _status =
          'This browser cannot coordinate a safe import. Keep a backup and use an updated browser before restoring.';
      return;
    }
    final source = await (widget.pickFile ?? pickSaveFile)();
    if (source == null || !mounted) return;
    SaveImportPreview preview;
    try {
      preview = _transfer.inspectSave(source);
    } on SaveTransferException catch (error) {
      _status = error.message;
      return;
    }
    setState(() => _reviewing = true);
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => SaveImportReviewDialog(
          preview: preview,
          stageImport: widget.stageImport,
          restart: widget.restart ?? reloadAfterSaveImport,
          backupActionLabel: 'Download backup or Copy backup',
        ),
      );
    } finally {
      _reviewing = false;
    }
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.shield_outlined, size: 44),
              const SizedBox(height: 16),
              Text(
                'Saved players need attention',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                widget.failure == AccountStartupFailure.unreadableProfiles
                    ? 'Nestarium could not read your saved player list. It has not created a replacement player or started cloud sync.'
                    : 'Nestarium could not finish checking local player storage. This is not proof that your saves are missing. Cloud sync has not started.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Do not clear app/browser data or reinstall. Retry first. If this continues, keep a backup before reviewing an older working save file.',
              ),
              const SizedBox(height: 12),
              const Text(
                'A backup copies the data that can be read, including the unreadable player list. It does not repair it or include sign-in credentials. Keep it private.',
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: _busy ? null : () => _run(widget.onRetry),
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
              if (widget.web)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: _busy ? null : () => _backup(copy: false),
                  icon: const Icon(Icons.download),
                  label: const Text('Download backup'),
                ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
                onPressed: _busy ? null : () => _backup(copy: true),
                icon: const Icon(Icons.copy),
                label: const Text('Copy backup'),
              ),
              if (widget.web)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: _busy ? null : _reviewFile,
                  icon: const Icon(Icons.preview_outlined),
                  label: const Text('Review saved file'),
                ),
              if (!widget.web)
                const Text(
                  'File restore is currently available in the web game. Keep the copied backup before seeking help; do not reset this device.',
                ),
              if (_busy && !_reviewing) const LinearProgressIndicator(),
              if (_status != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Semantics(liveRegion: true, child: Text(_status!)),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
