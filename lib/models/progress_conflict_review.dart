import '../services/save_service.dart';
import 'cloud_progress_read.dart';

/// An in-memory review, never persisted or transferred as authentication data.
class ProgressConflictReview {
  const ProgressConflictReview({required this.local, required this.cloud});

  final ProgressSaveSnapshot local;
  final CloudProgressSnapshot cloud;
}
