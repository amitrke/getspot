import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

/// Cached group data with timestamp for TTL checking
class CachedGroup {
  final String groupId;
  final String name;
  final String description;
  final String admin;
  final String groupCode;
  final num negativeBalanceLimit;
  final DateTime timestamp;

  CachedGroup({
    required this.groupId,
    required this.name,
    required this.description,
    required this.admin,
    required this.groupCode,
    required this.negativeBalanceLimit,
    required this.timestamp,
  });
}

/// Singleton service for caching group metadata
///
/// Caches group names, descriptions, codes, and admin info with a 30-minute TTL
/// to reduce redundant Firestore reads. Group metadata changes infrequently,
/// making it an ideal candidate for caching.
///
/// Usage:
/// ```dart
/// final groupCache = GroupCacheService();
/// final cachedGroup = await groupCache.getGroup(groupId);
/// if (cachedGroup != null) {
///   print(cachedGroup.name);
/// }
/// ```
class GroupCacheService {
  static final GroupCacheService _instance = GroupCacheService._internal();
  factory GroupCacheService() => _instance;
  GroupCacheService._internal();

  final Map<String, CachedGroup> _cache = {};
  final Duration _ttl = const Duration(minutes: 30);

  /// Get group data from cache or Firestore
  ///
  /// Returns cached data if available and fresh (within TTL).
  /// Otherwise, fetches from Firestore and updates the cache.
  Future<CachedGroup?> getGroup(String groupId) async {
    // Check cache first
    if (_cache.containsKey(groupId)) {
      final cached = _cache[groupId]!;
      if (DateTime.now().difference(cached.timestamp) < _ttl) {
        developer.log(
          'Cache hit for group: $groupId',
          name: 'GroupCacheService',
        );
        return cached;
      } else {
        developer.log(
          'Cache expired for group: $groupId',
          name: 'GroupCacheService',
        );
      }
    }

    // Cache miss or expired - fetch from Firestore
    developer.log(
      'Cache miss for group: $groupId, fetching from Firestore',
      name: 'GroupCacheService',
    );

    try {
      final doc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final group = CachedGroup(
          groupId: groupId,
          name: data['name'] ?? 'Unnamed Group',
          description: data['description'] ?? '',
          admin: data['admin'] ?? '',
          groupCode: data['groupCode'] ?? '',
          negativeBalanceLimit: data['negativeBalanceLimit'] ?? 0,
          timestamp: DateTime.now(),
        );
        _cache[groupId] = group;
        return group;
      } else {
        developer.log(
          'Group document not found: $groupId',
          name: 'GroupCacheService',
        );
      }
    } catch (e) {
      developer.log(
        'Error fetching group: $groupId',
        name: 'GroupCacheService',
        error: e,
      );
    }
    return null;
  }

  /// Batch fetch multiple groups
  ///
  /// Efficiently fetches multiple groups, using cache when possible
  /// and batching Firestore queries for cache misses.
  Future<Map<String, CachedGroup>> getGroups(List<String> groupIds) async {
    final result = <String, CachedGroup>{};
    final toFetch = <String>[];

    // Check cache for each group
    for (final groupId in groupIds) {
      if (_cache.containsKey(groupId)) {
        final cached = _cache[groupId]!;
        if (DateTime.now().difference(cached.timestamp) < _ttl) {
          result[groupId] = cached;
          continue;
        }
      }
      toFetch.add(groupId);
    }

    // Batch fetch uncached groups
    if (toFetch.isNotEmpty) {
      developer.log(
        'Batch fetching ${toFetch.length} groups from Firestore',
        name: 'GroupCacheService',
      );

      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('groups')
            .where(FieldPath.documentId, whereIn: toFetch)
            .get();

        for (final doc in snapshot.docs) {
          if (doc.exists) {
            final data = doc.data();
            final group = CachedGroup(
              groupId: doc.id,
              name: data['name'] ?? 'Unnamed Group',
              description: data['description'] ?? '',
              admin: data['admin'] ?? '',
              groupCode: data['groupCode'] ?? '',
              negativeBalanceLimit: data['negativeBalanceLimit'] ?? 0,
              timestamp: DateTime.now(),
            );
            _cache[doc.id] = group;
            result[doc.id] = group;
          }
        }
      } catch (e) {
        developer.log(
          'Error batch fetching groups',
          name: 'GroupCacheService',
          error: e,
        );
      }
    }

    return result;
  }

  /// Invalidate cache for a specific group
  ///
  /// Call this when a group's metadata is updated to force a fresh fetch
  /// on the next access.
  ///
  /// **When to call:**
  /// - After updating group name, description, or settings
  /// - After updating group code
  /// - After changing group admin
  /// - When implementing group edit features
  void invalidate(String groupId) {
    _cache.remove(groupId);
    developer.log(
      'Cache invalidated for group: $groupId',
      name: 'GroupCacheService',
    );
  }

  /// Clear all cached group data
  ///
  /// Useful for testing or when logging out.
  void clear() {
    _cache.clear();
    developer.log(
      'Cache cleared',
      name: 'GroupCacheService',
    );
  }

  /// Get current cache size (for debugging)
  int get cacheSize => _cache.length;
}
