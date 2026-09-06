import 'package:flutter/widgets.dart';
import '../services/save_transfer_service.dart';

class SaveImportScope extends InheritedWidget {
  const SaveImportScope({
    super.key,
    required this.stageImport,
    required super.child,
  });
  final Future<void> Function(SaveImportPreview) stageImport;
  static SaveImportScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SaveImportScope>();
  @override
  bool updateShouldNotify(SaveImportScope oldWidget) =>
      stageImport != oldWidget.stageImport;
}
