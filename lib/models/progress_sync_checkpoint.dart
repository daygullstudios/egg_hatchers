class ProgressSyncCheckpoint {
  const ProgressSyncCheckpoint({
    required this.contentFingerprint,
    required this.cloudRevision,
    required this.recordedAt,
  });

  static final RegExp _fingerprintPattern = RegExp(r'^[a-f0-9]{64}$');

  final String contentFingerprint;
  final int cloudRevision;
  final DateTime recordedAt;

  bool get isValid =>
      _fingerprintPattern.hasMatch(contentFingerprint) && cloudRevision >= 0;

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'contentFingerprint': contentFingerprint,
    'cloudRevision': cloudRevision,
    'recordedAt': recordedAt.toUtc().toIso8601String(),
  };

  static ProgressSyncCheckpoint? tryFromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1) return null;
    final recordedAt = DateTime.tryParse(json['recordedAt'] as String? ?? '');
    final checkpoint = ProgressSyncCheckpoint(
      contentFingerprint: json['contentFingerprint'] as String? ?? '',
      cloudRevision: (json['cloudRevision'] as num?)?.toInt() ?? -1,
      recordedAt: recordedAt?.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
    return checkpoint.isValid && recordedAt != null ? checkpoint : null;
  }
}
