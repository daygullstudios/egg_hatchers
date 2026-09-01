import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sprite_rating_claim.dart';
import 'account_storage.dart';

/// Persists one-time sprite rating reward claims in shared_preferences.
class SpriteRatingService extends ChangeNotifier {
  static const _claimsKey = 'spriteRatingClaims';

  final Map<String, Map<String, SpriteRatingClaim>> _claimsByAnimal = {};
  String? _accountId;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  bool isClaimed(String animalId, String spriteHash) {
    return _claimsByAnimal[animalId]?.containsKey(spriteHash) ?? false;
  }

  SpriteRatingClaim? getClaim(String animalId, String spriteHash) {
    return _claimsByAnimal[animalId]?[spriteHash];
  }

  Future<void> initialize({
    String? accountId,
    bool migrateLegacyData = false,
  }) async {
    _accountId = accountId;
    _claimsByAnimal.clear();
    final prefs = await SharedPreferences.getInstance();
    final claimsKey = AccountStorage.key(_claimsKey, accountId);
    var raw = prefs.getString(claimsKey);
    if (raw == null && accountId != null && migrateLegacyData) {
      raw = prefs.getString(_claimsKey);
    }
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            final animalId = entry.key;
            final hashMap = entry.value;
            if (hashMap is! Map<String, dynamic>) continue;

            final claims = <String, SpriteRatingClaim>{};
            for (final hashEntry in hashMap.entries) {
              final claimJson = hashEntry.value;
              if (claimJson is Map<String, dynamic>) {
                claims[hashEntry.key] = SpriteRatingClaim.fromJson(claimJson);
              }
            }
            if (claims.isNotEmpty) {
              _claimsByAnimal[animalId] = claims;
            }
          }
        }
      } catch (_) {
        // Ignore corrupt claim data.
      }
    }
    if (accountId != null && !prefs.containsKey(claimsKey)) {
      await _persist();
    }

    _isInitialized = true;
    notifyListeners();
  }

  bool hasPerfectRating(String animalId, {int minScore = 10}) {
    return bestClaimedScore(animalId) >= minScore;
  }

  int bestClaimedScore(String animalId) {
    final claims = _claimsByAnimal[animalId];
    if (claims == null || claims.isEmpty) return 0;

    var best = 0;
    for (final claim in claims.values) {
      if (claim.score > best) best = claim.score;
    }
    return best;
  }

  Future<bool> recordClaim({
    required String animalId,
    required String spriteHash,
    required int score,
    required int rewardCoins,
  }) async {
    if (isClaimed(animalId, spriteHash)) return false;

    final claim = SpriteRatingClaim(
      score: score,
      rewardCoins: rewardCoins,
      claimedAt: DateTime.now(),
    );

    _claimsByAnimal.putIfAbsent(animalId, () => {})[spriteHash] = claim;
    notifyListeners();
    await _persist();
    return true;
  }

  Future<void> clearAllClaims() async {
    _claimsByAnimal.clear();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AccountStorage.key(_claimsKey, _accountId));
  }

  Future<void> _persist() async {
    final encoded = <String, dynamic>{};
    for (final animalEntry in _claimsByAnimal.entries) {
      encoded[animalEntry.key] = {
        for (final claimEntry in animalEntry.value.entries)
          claimEntry.key: claimEntry.value.toJson(),
      };
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AccountStorage.key(_claimsKey, _accountId),
      jsonEncode(encoded),
    );
  }
}
