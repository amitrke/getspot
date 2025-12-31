import 'package:firebase_analytics/firebase_analytics.dart';
import 'dart:developer' as developer;

/// Singleton service for Firebase Analytics tracking
///
/// Provides a centralized place to track user events and behaviors.
/// All analytics events are logged here for easy maintenance and debugging.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Get the Firebase Analytics observer for navigation tracking
  FirebaseAnalyticsObserver getAnalyticsObserver() =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ============================================================================
  // USER AUTHENTICATION EVENTS
  // ============================================================================

  Future<void> logSignUp(String method) async {
    developer.log('Analytics: User signed up via $method', name: 'AnalyticsService');
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logLogin(String method) async {
    developer.log('Analytics: User logged in via $method', name: 'AnalyticsService');
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logLogout() async {
    developer.log('Analytics: User logged out', name: 'AnalyticsService');
    await _analytics.logEvent(name: 'logout');
  }

  // ============================================================================
  // GROUP EVENTS
  // ============================================================================

  Future<void> logCreateGroup() async {
    developer.log('Analytics: Group created', name: 'AnalyticsService');
    await _analytics.logEvent(
      name: 'create_group',
      parameters: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  Future<void> logJoinGroupRequest() async {
    developer.log('Analytics: Join group request sent', name: 'AnalyticsService');
    await _analytics.logEvent(name: 'join_group_request');
  }

  Future<void> logJoinGroupSuccess() async {
    developer.log('Analytics: Join group successful', name: 'AnalyticsService');
    await _analytics.logJoinGroup(groupId: 'user_joined');
  }

  Future<void> logLeaveGroup() async {
    developer.log('Analytics: User left group', name: 'AnalyticsService');
    await _analytics.logEvent(name: 'leave_group');
  }

  // ============================================================================
  // EVENT MANAGEMENT EVENTS
  // ============================================================================

  Future<void> logCreateEvent() async {
    developer.log('Analytics: Event created', name: 'AnalyticsService');
    await _analytics.logEvent(
      name: 'create_event',
      parameters: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  Future<void> logRegisterForEvent({required String status}) async {
    developer.log('Analytics: Event registration - status: $status', name: 'AnalyticsService');
    await _analytics.logEvent(
      name: 'register_for_event',
      parameters: {'status': status},
    );
  }

  Future<void> logWithdrawFromEvent({required bool afterDeadline}) async {
    developer.log('Analytics: Event withdrawal - after deadline: $afterDeadline', name: 'AnalyticsService');
    await _analytics.logEvent(
      name: 'withdraw_from_event',
      parameters: {'after_deadline': afterDeadline},
    );
  }

  Future<void> logCancelEvent() async {
    developer.log('Analytics: Event cancelled', name: 'AnalyticsService');
    await _analytics.logEvent(name: 'cancel_event');
  }

  Future<void> logUpdateEventCapacity({required int oldCapacity, required int newCapacity}) async {
    developer.log('Analytics: Event capacity updated $oldCapacity → $newCapacity', name: 'AnalyticsService');
    await _analytics.logEvent(
      name: 'update_event_capacity',
      parameters: {
        'old_capacity': oldCapacity,
        'new_capacity': newCapacity,
        'change': newCapacity - oldCapacity,
      },
    );
  }

  // ============================================================================
  // WALLET & TRANSACTION EVENTS
  // ============================================================================

  Future<void> logWalletCredit({required double amount}) async {
    developer.log('Analytics: Wallet credited - amount: $amount', name: 'AnalyticsService');
    await _analytics.logEvent(
      name: 'wallet_credit',
      parameters: {'amount': amount},
    );
  }

  Future<void> logViewWallet() async {
    developer.log('Analytics: Wallet viewed', name: 'AnalyticsService');
    await _analytics.logEvent(name: 'view_wallet');
  }

  Future<void> logViewTransactionHistory() async {
    developer.log('Analytics: Transaction history viewed', name: 'AnalyticsService');
    await _analytics.logEvent(name: 'view_transaction_history');
  }

  // ============================================================================
  // COMMUNICATION EVENTS
  // ============================================================================

  Future<void> logPostAnnouncement() async {
    developer.log('Analytics: Announcement posted', name: 'AnalyticsService');
    await _analytics.logEvent(name: 'post_announcement');
  }

  Future<void> logViewAnnouncements() async {
    developer.log('Analytics: Announcements viewed', name: 'AnalyticsService');
    await _analytics.logEvent(name: 'view_announcements');
  }

  // ============================================================================
  // SCREEN VIEW EVENTS
  // ============================================================================

  Future<void> logScreenView(String screenName) async {
    developer.log('Analytics: Screen view - $screenName', name: 'AnalyticsService');
    await _analytics.logScreenView(screenName: screenName);
  }

  // ============================================================================
  // MEMBER MANAGEMENT EVENTS
  // ============================================================================

  Future<void> logApproveJoinRequest() async {
    developer.log('Analytics: Join request approved', name: 'AnalyticsService');
    await _analytics.logEvent(name: 'approve_join_request');
  }

  Future<void> logDenyJoinRequest() async {
    developer.log('Analytics: Join request denied', name: 'AnalyticsService');
    await _analytics.logEvent(name: 'deny_join_request');
  }

  Future<void> logRemoveMember() async {
    developer.log('Analytics: Member removed from group', name: 'AnalyticsService');
    await _analytics.logEvent(name: 'remove_member');
  }

  // ============================================================================
  // ERROR TRACKING
  // ============================================================================

  Future<void> logError(String errorType, String errorMessage) async {
    developer.log('Analytics: Error - $errorType: $errorMessage', name: 'AnalyticsService');
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ============================================================================
  // USER PROPERTIES
  // ============================================================================

  Future<void> setUserProperty({required String name, required String value}) async {
    developer.log('Analytics: Set user property - $name: $value', name: 'AnalyticsService');
    await _analytics.setUserProperty(name: name, value: value);
  }

  Future<void> setUserId(String userId) async {
    developer.log('Analytics: Set user ID - $userId', name: 'AnalyticsService');
    await _analytics.setUserId(id: userId);
  }

  // ============================================================================
  // PULL-TO-REFRESH EVENTS
  // ============================================================================

  Future<void> logPullToRefresh(String screenName) async {
    developer.log('Analytics: Pull-to-refresh on $screenName', name: 'AnalyticsService');
    await _analytics.logEvent(
      name: 'pull_to_refresh',
      parameters: {'screen': screenName},
    );
  }
}
