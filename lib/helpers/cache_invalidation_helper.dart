import 'package:getspot/services/group_cache_service.dart';
import 'package:getspot/services/event_cache_service.dart';
import 'package:getspot/services/announcement_cache_service.dart';
import 'package:getspot/services/transaction_cache_service.dart';
import 'package:getspot/services/user_cache_service.dart';
import 'dart:developer' as developer;

/// Helper class to consolidate cache invalidation operations.
///
/// Reduces boilerplate by providing methods to invalidate related caches
/// together. This ensures consistency when data changes and prevents
/// forgetting to invalidate dependent caches.
class CacheInvalidationHelper {
  static final CacheInvalidationHelper _instance =
      CacheInvalidationHelper._internal();
  factory CacheInvalidationHelper() => _instance;
  CacheInvalidationHelper._internal();

  /// Invalidate all caches related to a group.
  ///
  /// Call this after:
  /// - Updating group metadata
  /// - Creating/cancelling events
  /// - Posting announcements
  ///
  /// This invalidates:
  /// - Group metadata cache
  /// - Events cache for the group
  /// - Announcements cache for the group
  void invalidateGroup(String groupId) {
    GroupCacheService().invalidate(groupId);
    EventCacheService().invalidate(groupId);
    AnnouncementCacheService().invalidate(groupId);
    developer.log(
      'Invalidated all caches for group: $groupId',
      name: 'CacheInvalidationHelper',
    );
  }

  /// Invalidate caches after an event is created or cancelled.
  ///
  /// Call this after:
  /// - Creating a new event
  /// - Cancelling an event
  ///
  /// This invalidates:
  /// - Events cache for the group
  /// - Transaction cache for the group (refunds may be created)
  void invalidateEventChange(String groupId) {
    EventCacheService().invalidate(groupId);
    TransactionCacheService().invalidateGroup(groupId);
    developer.log(
      'Invalidated event and transaction caches for group: $groupId',
      name: 'CacheInvalidationHelper',
    );
  }

  /// Invalidate caches after a transaction is created for a user.
  ///
  /// Call this after:
  /// - Admin adjusts wallet balance
  /// - Event registration (fee deducted)
  /// - Withdrawal refund
  void invalidateUserTransactions(String groupId, String userId) {
    TransactionCacheService().invalidate(groupId, userId);
    developer.log(
      'Invalidated transaction cache for user: $userId in group: $groupId',
      name: 'CacheInvalidationHelper',
    );
  }

  /// Invalidate user profile cache.
  ///
  /// Call this after:
  /// - User updates their display name
  /// - User updates their profile photo
  void invalidateUser(String userId) {
    UserCacheService().invalidate(userId);
    developer.log(
      'Invalidated user cache for user: $userId',
      name: 'CacheInvalidationHelper',
    );
  }

  /// Clear all caches.
  ///
  /// Call this when:
  /// - User logs out
  /// - App needs a full refresh
  void clearAll() {
    GroupCacheService().clear();
    EventCacheService().clear();
    AnnouncementCacheService().clear();
    TransactionCacheService().clear();
    UserCacheService().clear();
    developer.log(
      'Cleared all caches',
      name: 'CacheInvalidationHelper',
    );
  }
}
