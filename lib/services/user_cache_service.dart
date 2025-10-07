import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

/// Cached user data with timestamp for TTL checking
class CachedUser {
  final String uid;
  final String displayName;
  final String? photoURL;
  final DateTime timestamp;

  CachedUser({
    required this.uid,
    required this.displayName,
    this.photoURL,
    required this.timestamp,
  });
}

/// Singleton service for caching user profile data
///
/// Caches user display names and photos with a 15-minute TTL to reduce
/// redundant Firestore reads. User profile data rarely changes, making
/// it an ideal candidate for caching.
///
/// Usage:
/// ```dart
/// final userCache = UserCacheService();
/// final cachedUser = await userCache.getUser(userId);
/// if (cachedUser != null) {
///   print(cachedUser.displayName);
/// }
/// ```
class UserCacheService {
  static final UserCacheService _instance = UserCacheService._internal();
  factory UserCacheService() => _instance;
  UserCacheService._internal();

  final Map<String, CachedUser> _cache = {};
  final Duration _ttl = const Duration(minutes: 15);

  /// Get user data from cache or Firestore
  ///
  /// Returns cached data if available and fresh (within TTL).
  /// Otherwise, fetches from Firestore and updates the cache.
  Future<CachedUser?> getUser(String uid) async {
    // Check cache first
    if (_cache.containsKey(uid)) {
      final cached = _cache[uid]!;
      if (DateTime.now().difference(cached.timestamp) < _ttl) {
        developer.log(
          'Cache hit for user: $uid',
          name: 'UserCacheService',
        );
        return cached;
      } else {
        developer.log(
          'Cache expired for user: $uid',
          name: 'UserCacheService',
        );
      }
    }

    // Cache miss or expired - fetch from Firestore
    developer.log(
      'Cache miss for user: $uid, fetching from Firestore',
      name: 'UserCacheService',
    );

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final user = CachedUser(
          uid: uid,
          displayName: data?['displayName'] ?? 'No Name',
          photoURL: data?['photoURL'],
          timestamp: DateTime.now(),
        );
        _cache[uid] = user;
        return user;
      } else {
        developer.log(
          'User document not found: $uid',
          name: 'UserCacheService',
        );
      }
    } catch (e) {
      developer.log(
        'Error fetching user: $uid',
        name: 'UserCacheService',
        error: e,
      );
    }
    return null;
  }

  /// Invalidate cache for a specific user
  ///
  /// Call this when a user's profile is updated to force a fresh fetch
  /// on the next access.
  void invalidate(String uid) {
    _cache.remove(uid);
    developer.log(
      'Cache invalidated for user: $uid',
      name: 'UserCacheService',
    );
  }

  /// Clear all cached user data
  ///
  /// Useful for testing or when logging out.
  void clear() {
    _cache.clear();
    developer.log(
      'Cache cleared',
      name: 'UserCacheService',
    );
  }

  /// Get current cache size (for debugging)
  int get cacheSize => _cache.length;
}
