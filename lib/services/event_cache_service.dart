import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

/// Cached event data with timestamp for TTL checking
class CachedEvent {
  final String id;
  final String groupId;
  final String title;
  final String? description;
  final DateTime? eventTimestamp;
  final String? location;
  final int capacity;
  final num confirmedCount;
  final num waitlistCount;
  final String status;

  CachedEvent({
    required this.id,
    required this.groupId,
    required this.title,
    this.description,
    this.eventTimestamp,
    this.location,
    required this.capacity,
    required this.confirmedCount,
    required this.waitlistCount,
    required this.status,
  });

  factory CachedEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CachedEvent(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      title: data['title'] ?? 'Untitled Event',
      description: data['description'],
      eventTimestamp: (data['eventTimestamp'] as Timestamp?)?.toDate(),
      location: data['location'],
      capacity: data['capacity'] ?? 0,
      confirmedCount: data['confirmedCount'] ?? 0,
      waitlistCount: data['waitlistCount'] ?? 0,
      status: data['status'] ?? 'active',
    );
  }

  /// Convert to Map for compatibility with existing code
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'title': title,
      'description': description,
      'eventTimestamp': eventTimestamp != null
          ? Timestamp.fromDate(eventTimestamp!)
          : null,
      'location': location,
      'capacity': capacity,
      'confirmedCount': confirmedCount,
      'waitlistCount': waitlistCount,
      'status': status,
    };
  }
}

/// Cached event list with timestamp for TTL checking
class CachedEventList {
  final List<CachedEvent> events;
  final DateTime timestamp;

  CachedEventList({
    required this.events,
    required this.timestamp,
  });
}

/// Singleton service for caching event lists per group
///
/// Caches active upcoming events with a 10-minute TTL to reduce
/// redundant Firestore reads. Events change infrequently (only when
/// admin creates/cancels events), making them ideal for caching.
///
/// Usage:
/// ```dart
/// final eventCache = EventCacheService();
/// final cachedEvents = await eventCache.getEvents(groupId);
/// if (cachedEvents != null) {
///   for (var event in cachedEvents) {
///     print(event.title);
///   }
/// }
/// ```
class EventCacheService {
  static final EventCacheService _instance = EventCacheService._internal();
  factory EventCacheService() => _instance;
  EventCacheService._internal();

  final Map<String, CachedEventList> _cache = {};
  // Using 10-minute TTL - events change when admin creates/cancels
  final Duration _ttl = const Duration(minutes: 10);

  /// Get event list from cache or Firestore
  ///
  /// Returns cached data if available and fresh (within TTL).
  /// Otherwise, fetches from Firestore and updates the cache.
  ///
  /// Fetches only active events with eventTimestamp >= now.
  Future<List<CachedEvent>?> getEvents(String groupId) async {
    // Check cache first
    if (_cache.containsKey(groupId)) {
      final cached = _cache[groupId]!;
      if (DateTime.now().difference(cached.timestamp) < _ttl) {
        developer.log(
          'Cache hit for events in group: $groupId (${cached.events.length} events)',
          name: 'EventCacheService',
        );
        return cached.events;
      } else {
        developer.log(
          'Cache expired for events in group: $groupId',
          name: 'EventCacheService',
        );
      }
    }

    // Cache miss or expired - fetch from Firestore
    developer.log(
      'Cache miss for events in group: $groupId, fetching from Firestore',
      name: 'EventCacheService',
    );

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('groupId', isEqualTo: groupId)
          .where('status', isEqualTo: 'active')
          .where('eventTimestamp', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy('eventTimestamp', descending: false)
          .get();

      final events = snapshot.docs
          .map((doc) => CachedEvent.fromFirestore(doc))
          .toList();

      _cache[groupId] = CachedEventList(
        events: events,
        timestamp: DateTime.now(),
      );

      developer.log(
        'Cached ${events.length} events for group: $groupId',
        name: 'EventCacheService',
      );

      return events;
    } catch (e) {
      developer.log(
        'Error fetching events for group: $groupId',
        name: 'EventCacheService',
        error: e,
      );
    }
    return null;
  }

  /// Get a Stream of events with cache-first loading
  ///
  /// Returns a stream that:
  /// 1. Immediately emits cached data if available and fresh
  /// 2. Then emits real-time updates from Firestore
  ///
  /// This provides fast initial load from cache while maintaining
  /// real-time updates for live changes.
  Stream<List<CachedEvent>> getEventsStream(String groupId) async* {
    // First, try to emit cached data for fast initial load
    if (_cache.containsKey(groupId)) {
      final cached = _cache[groupId]!;
      if (DateTime.now().difference(cached.timestamp) < _ttl) {
        developer.log(
          'Stream: Emitting cached events for group: $groupId',
          name: 'EventCacheService',
        );
        yield cached.events;
      }
    }

    // Then subscribe to real-time updates
    developer.log(
      'Stream: Subscribing to real-time events for group: $groupId',
      name: 'EventCacheService',
    );

    await for (final snapshot in FirebaseFirestore.instance
        .collection('events')
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: 'active')
        .where('eventTimestamp', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('eventTimestamp', descending: false)
        .snapshots()) {
      final events = snapshot.docs
          .map((doc) => CachedEvent.fromFirestore(doc))
          .toList();

      // Update cache with fresh data
      _cache[groupId] = CachedEventList(
        events: events,
        timestamp: DateTime.now(),
      );

      yield events;
    }
  }

  /// Invalidate cache for a specific group
  ///
  /// Call this when events are created or cancelled to force a fresh fetch
  /// on the next access.
  ///
  /// **When to call:**
  /// - After creating a new event
  /// - After cancelling an event
  /// - After updating event details
  void invalidate(String groupId) {
    _cache.remove(groupId);
    developer.log(
      'Cache invalidated for events in group: $groupId',
      name: 'EventCacheService',
    );
  }

  /// Clear all cached event data
  ///
  /// Useful for testing or when logging out.
  void clear() {
    _cache.clear();
    developer.log(
      'Event cache cleared',
      name: 'EventCacheService',
    );
  }

  /// Get current cache size (for debugging)
  int get cacheSize => _cache.length;
}
