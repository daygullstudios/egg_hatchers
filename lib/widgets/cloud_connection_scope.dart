import 'package:flutter/material.dart';
import '../services/cloud_connection_service.dart';

class CloudConnectionScope extends InheritedNotifier<CloudConnectionService> {
  const CloudConnectionScope({
    super.key,
    required super.notifier,
    required super.child,
  });
  static CloudConnectionService? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<CloudConnectionScope>()
      ?.notifier;
}

class CloudConnectionNotice extends StatelessWidget {
  const CloudConnectionNotice({
    super.key,
    required this.connection,
    this.foregroundColor,
  });
  final CloudConnectionService connection;
  final Color? foregroundColor;
  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
    style: TextStyle(color: foregroundColor),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          connection.isBusy ? 'Connecting to cloud' : 'Cloud unavailable',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          connection.status == CloudConnectionStatus.slow
              ? 'The connection is taking longer than expected. You can keep playing locally while it finishes.'
              : 'You can play using this device’s local save. Cloud saving and sign-in are not connected yet.',
        ),
        const SizedBox(height: 6),
        const Text(
          'Keep your app/browser data. Export a backup before changing devices.',
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: connection.isBusy ? null : connection.connect,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: foregroundColor,
          ),
          icon: const Icon(Icons.cloud_sync_outlined),
          label: Text(
            connection.isBusy
                ? 'Connection in progress'
                : 'Retry cloud connection',
          ),
        ),
      ],
    ),
  );
}
