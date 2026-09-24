import 'player_account.dart';

enum PeerReportReason {
  disruptiveConduct(
    'disruptive_conduct',
    'Disruptive conduct',
    'Intentionally stalling, repeatedly quitting, or disrupting play.',
  ),
  suspectedCheating(
    'suspected_cheating',
    'Suspected cheating',
    'Gameplay or results appeared manipulated or impossible.',
  ),
  tradeConcern(
    'trade_concern',
    'Trade concern',
    'Suspicious or coercive behavior during a protected trade.',
  ),
  otherSafetyConcern(
    'other_safety_concern',
    'Other safety concern',
    'Another preset-only safety issue needs review.',
  );

  const PeerReportReason(this.wireName, this.label, this.description);

  final String wireName;
  final String label;
  final String description;
}

class BlockedPlayerEntry {
  const BlockedPlayerEntry({
    required this.token,
    required this.account,
    required this.blockedAt,
  });

  final String token;
  final PlayerAccount account;
  final DateTime blockedAt;

  factory BlockedPlayerEntry.fromJson(Map<String, dynamic> json) {
    final token = json['token'] as String?;
    final account = json['account'];
    final blockedAt = json['blockedAt'] as String?;
    if (token == null ||
        token.isEmpty ||
        account is! Map ||
        blockedAt == null) {
      throw const FormatException('Invalid blocked player entry');
    }
    return BlockedPlayerEntry(
      token: token,
      account: PlayerAccount.fromJson(Map<String, dynamic>.from(account)),
      blockedAt: DateTime.parse(blockedAt),
    );
  }
}

class PeerSafetyReceipt {
  const PeerSafetyReceipt({
    required this.eventId,
    required this.success,
    required this.message,
    required this.blocked,
    required this.reportRecorded,
  });

  final String eventId;
  final bool success;
  final String message;
  final bool blocked;
  final bool reportRecorded;

  factory PeerSafetyReceipt.fromJson(Map<String, dynamic> json) {
    return PeerSafetyReceipt(
      eventId: json['eventId'] as String,
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? 'Player safety action updated.',
      blocked: json['blocked'] as bool? ?? false,
      reportRecorded: json['reportRecorded'] as bool? ?? false,
    );
  }
}
