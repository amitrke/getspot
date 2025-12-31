import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

/// Cached announcement data with timestamp for TTL checking
class CachedAnnouncement {
  final String id;
  final String content;
  final String? authorName;
  final String? authorUid;
  final DateTime? createdAt;

  CachedAnnouncement({
    required this.id,
    required this.content,
    this.authorName,
    this.authorUid,
    this.createdAt,
  });

  factory CachedAnnouncement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CachedAnnouncement(
      id: doc.id,
      content: data['content'] ?? '',
      authorName: data['authorName'],
      authorUid: data['authorUid'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Map for compatibility with existing code
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'authorName': authorName,
      'authorUid': authorUid,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : null,
    };
  }
}

/// Cached announcement list with timestamp for TTL checking
class CachedAnnouncementList {
  final List<CachedAnnouncement> announcements;
  final DateTime timestamp;

  CachedAnnouncementList({
    required this.announcements,
    required this.timestamp,
  });
}

/// Singleton service for caching announcements per group
///
/// Caches recent announcements (up to 50) with a 10-minute TTL to reduce
/// redundant Firestore reads. Announcements are read frequently but written
/// infrequently, making them ideal for caching.
///
/// Usage:
/// ```dart
/// final announcementCache = AnnouncementCacheService();
/// final cachedAnnouncements = await announcementCache.getAnnouncements(groupId);
/// if (cachedAnnouncements != null) {
///   for (var announcement in cachedAnnouncements) {
///     print(announcement.content);
///   }
/// }
/// ```
class AnnouncementCacheService {
  static final AnnouncementCacheService _instance =
      AnnouncementCacheService._internal();
  factory AnnouncementCacheService() => _instance;
  AnnouncementCacheService._internal();

  final Map<String, CachedAnnouncementList> _cache = {};
  // Using 10-minute TTL - announcements change when admin posts
  final Duration _ttl = const Duration(minutes: 10);

  /// Get announcement list from cache or Firestore
  ///
  /// Returns cached data if available and fresh (within TTL).
  /// Otherwise, fetches from Firestore and updates the cache.
  ///
  /// Fetches up to 50 most recent announcements.
  Future<List<CachedAnnouncement>?> getAnnouncements(String groupId) async {
    // Check cache first
    if (_cache.containsKey(groupId)) {
      final cached = _cache[groupId]!;
      if (DateTime.now().difference(cached.timestamp) < _ttl) {
        developer.log(
          'Cache hit for announcements in group: $groupId (${cached.announcements.length} announcements)',
          name: 'AnnouncementCacheService',
        );
        return cached.announcements;
      } else {
        developer.log(
          'Cache expired for announcements in group: $groupId',
          name: 'AnnouncementCacheService',
        );
      }
    }

    // Cache miss or expired - fetch from Firestore
    developer.log(
      'Cache miss for announcements in group: $groupId, fetching from Firestore',
      name: 'AnnouncementCacheService',
    );

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final announcements = snapshot.docs
          .map((doc) => CachedAnnouncement.fromFirestore(doc))
          .toList();

      _cache[groupId] = CachedAnnouncementList(
        announcements: announcements,
        timestamp: DateTime.now(),
      );

      developer.log(
        'Cached ${announcements.length} announcements for group: $groupId',
        name: 'AnnouncementCacheService',
      );

      return announcements;
    } catch (e) {
      developer.log(
        'Error fetching announcements for group: $groupId',
        name: 'AnnouncementCacheService',
        error: e,
      );
    }
    return null;
  }

  /// Get a Stream of announcements with cache-first loading
  ///
  /// Returns a stream that:
  /// 1. Immediately emits cached data if available and fresh
  /// 2. Then emits real-time updates from Firestore
  ///
  /// This provides fast initial load from cache while maintaining
  /// real-time updates for new announcements.
  Stream<List<CachedAnnouncement>> getAnnouncementsStream(String groupId) async* {
    // First, try to emit cached data for fast initial load
    if (_cache.containsKey(groupId)) {
      final cached = _cache[groupId]!;
      if (DateTime.now().difference(cached.timestamp) < _ttl) {
        developer.log(
          'Stream: Emitting cached announcements for group: $groupId',
          name: 'AnnouncementCacheService',
        );
        yield cached.announcements;
      }
    }

    // Then subscribe to real-time updates
    developer.log(
      'Stream: Subscribing to real-time announcements for group: $groupId',
      name: 'AnnouncementCacheService',
    );

    await for (final snapshot in FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()) {
      final announcements = snapshot.docs
          .map((doc) => CachedAnnouncement.fromFirestore(doc))
          .toList();

      // Update cache with fresh data
      _cache[groupId] = CachedAnnouncementList(
        announcements: announcements,
        timestamp: DateTime.now(),
      );

      yield announcements;
    }
  }

  /// Invalidate cache for a specific group
  ///
  /// Call this when a new announcement is posted to force a fresh fetch
  /// on the next access.
  ///
  /// **When to call:**
  /// - After posting a new announcement
  /// - After deleting an announcement (if deletion feature is added)
  void invalidate(String groupId) {
    _cache.remove(groupId);
    developer.log(
      'Cache invalidated for announcements in group: $groupId',
      name: 'AnnouncementCacheService',
    );
  }

  /// Clear all cached announcement data
  ///
  /// Useful for testing or when logging out.
  void clear() {
    _cache.clear();
    developer.log(
      'Announcement cache cleared',
      name: 'AnnouncementCacheService',
    );
  }

  /// Get current cache size (for debugging)
  int get cacheSize => _cache.length;
}
