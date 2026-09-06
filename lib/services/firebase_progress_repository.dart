import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cloud_progress_read.dart';
import '../models/player_state.dart';
import 'progress_sync_service.dart';
import 'save_service.dart';

/// Firestore persistence for one authenticated Nestarium identity.
///
/// Reads require a confirmed server response. Writes are revision-checked
/// transactions so a stale device cannot silently replace newer cloud data.
final class FirebaseProgressRepository implements CloudProgressRepository {
  FirebaseProgressRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _document(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('products')
      .doc('egg_hatchers');

  @override
  Future<CloudProgressRead> read(String protectedPlayerId) async {
    try {
      final document = await _document(
        protectedPlayerId,
      ).get(const GetOptions(source: Source.server));
      if (!document.exists || document.data() == null) {
        return const CloudProgressRead.missing();
      }
      final data = document.data()!;
      if (data['ownerUid'] != protectedPlayerId) {
        return const CloudProgressRead.unknown();
      }
      final snapshot = decode(data);
      return snapshot == null
          ? const CloudProgressRead.unknown()
          : CloudProgressRead.present(snapshot);
    } on FirebaseException {
      return const CloudProgressRead.unknown();
    } catch (_) {
      return const CloudProgressRead.unknown();
    }
  }

  @override
  Future<CloudProgressSnapshot> write({
    required String protectedPlayerId,
    required ProgressSaveSnapshot local,
    required int? expectedCloudRevision,
  }) async {
    final reference = _document(protectedPlayerId);
    final revision = await _firestore.runTransaction<int>((transaction) async {
      final existing = await transaction.get(reference);
      final data = existing.data();
      final actualRevision = data == null
          ? null
          : (data['cloudRevision'] as num?)?.toInt();
      if (actualRevision != expectedCloudRevision) {
        throw const CloudProgressWriteConflict();
      }
      final nextRevision = (actualRevision ?? 0) + 1;
      transaction.set(reference, <String, dynamic>{
        'format': 'egg_hatchers_cloud_progress',
        'schemaVersion': 1,
        'ownerUid': protectedPlayerId,
        'cloudRevision': nextRevision,
        'localRevision': local.revision,
        'savedAt': FieldValue.serverTimestamp(),
        'contentFingerprint': local.contentFingerprint,
        'playerState': local.state.toJson(),
      });
      return nextRevision;
    });
    return CloudProgressSnapshot(
      state: local.state,
      contentFingerprint: local.contentFingerprint,
      cloudRevision: revision,
      savedAt: DateTime.now().toUtc(),
    );
  }

  static CloudProgressSnapshot? decode(Map<String, dynamic> json) {
    try {
      if (json['format'] != 'egg_hatchers_cloud_progress' ||
          json['schemaVersion'] != 1 ||
          json['playerState'] is! Map) {
        return null;
      }
      final state = PlayerState.fromJson(
        Map<String, dynamic>.from(json['playerState'] as Map),
      );
      final fingerprint = json['contentFingerprint'] as String? ?? '';
      final revision = (json['cloudRevision'] as num?)?.toInt() ?? -1;
      final savedAtValue = json['savedAt'];
      final savedAt = savedAtValue is Timestamp
          ? savedAtValue.toDate().toUtc()
          : DateTime.tryParse(savedAtValue as String? ?? '')?.toUtc();
      if (revision < 0 ||
          savedAt == null ||
          SaveService.contentFingerprint(state) != fingerprint) {
        return null;
      }
      return CloudProgressSnapshot(
        state: state,
        contentFingerprint: fingerprint,
        cloudRevision: revision,
        savedAt: savedAt,
      );
    } catch (_) {
      return null;
    }
  }
}
