import 'package:flutter/material.dart';

import '../models/peer_safety.dart';

Future<void> showPeerSafetySheet({
  required BuildContext context,
  required String opponentName,
  required void Function(PeerReportReason reason, {required bool block})
  onReport,
  required VoidCallback onBlock,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => _PeerSafetySheet(
      opponentName: opponentName,
      onReport: onReport,
      onBlock: onBlock,
    ),
  );
}

class _PeerSafetySheet extends StatefulWidget {
  const _PeerSafetySheet({
    required this.opponentName,
    required this.onReport,
    required this.onBlock,
  });

  final String opponentName;
  final void Function(PeerReportReason reason, {required bool block}) onReport;
  final VoidCallback onBlock;

  @override
  State<_PeerSafetySheet> createState() => _PeerSafetySheetState();
}

class _PeerSafetySheetState extends State<_PeerSafetySheet> {
  PeerReportReason? _reason;
  var _blockWithReport = true;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 460,
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          12,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 34,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.shield_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Player safety',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              'Report or block ${widget.opponentName}. Reports use preset reasons only; no message or personal information is requested.',
            ),
            const SizedBox(height: 16),
            const Text(
              'REPORT REASON',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
            const SizedBox(height: 6),
            RadioGroup<PeerReportReason>(
              groupValue: _reason,
              onChanged: (value) => setState(() => _reason = value),
              child: Column(
                children: [
                  for (final reason in PeerReportReason.values)
                    RadioListTile<PeerReportReason>(
                      key: ValueKey('peer-report-${reason.wireName}'),
                      value: reason,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        reason.label,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(reason.description),
                    ),
                ],
              ),
            ),
            CheckboxListTile(
              key: const ValueKey('peer-report-also-block'),
              value: _blockWithReport,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Also block this player',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'You will not be matched together again. Blocking does not change the current battle result.',
              ),
              onChanged: (value) =>
                  setState(() => _blockWithReport = value ?? true),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const ValueKey('submit-peer-report'),
              onPressed: _reason == null
                  ? null
                  : () {
                      widget.onReport(_reason!, block: _blockWithReport);
                      Navigator.pop(context);
                    },
              icon: const Icon(Icons.flag_outlined),
              label: const Text('SUBMIT REPORT'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const ValueKey('block-peer-without-report'),
              onPressed: () {
                widget.onBlock();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.block),
              label: const Text('BLOCK WITHOUT REPORTING'),
            ),
          ],
        ),
      ),
    );
  }
}
