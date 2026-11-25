import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CachedResponse {
  const CachedResponse(this.data, this.savedAt);

  final Object? data;
  final DateTime savedAt;
}

/// The last good answer to each cached request, for viewing offline.
///
/// Holds one account's data at a time: [claimFor] clears it when a different
/// account signs in, and signing out clears it. It lives in the app's private
/// storage; tokens, which are secret, are kept separately in the keystore.
class OfflineCache {
  OfflineCache(this._prefs);

  static const _prefix = 'cache:';
  static const _ownerKey = 'cache-owner';

  final SharedPreferences _prefs;

  Future<void> put(String key, Object? data) => _prefs.setString(
    '$_prefix$key',
    jsonEncode({'savedAt': DateTime.now().toIso8601String(), 'data': data}),
  );

  CachedResponse? get(String key) {
    final raw = _prefs.getString('$_prefix$key');
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return CachedResponse(
      json['data'],
      DateTime.parse(json['savedAt'] as String),
    );
  }

  /// Makes the cache [userId]'s, dropping anything another account left.
  Future<void> claimFor(String userId) async {
    if (_prefs.getString(_ownerKey) == userId) return;
    await clear();
    await _prefs.setString(_ownerKey, userId);
  }

  Future<void> clear() async {
    final keys = _prefs.getKeys().where(
      (k) => k.startsWith(_prefix) || k == _ownerKey,
    );
    for (final key in keys.toList()) {
      await _prefs.remove(key);
    }
  }
}
