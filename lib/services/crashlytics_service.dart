import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:developer' as developer;

/// Singleton service for Firebase Crashlytics error tracking
///
/// Provides centralized crash reporting and logging functionality.
/// Use this service to manually log errors, add custom keys, and track user context.
class CrashlyticsService {
  static final CrashlyticsService _instance = CrashlyticsService._internal();
  factory CrashlyticsService() => _instance;
  CrashlyticsService._internal();

  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  // ============================================================================
  // USER CONTEXT
  // ============================================================================

  /// Set the user ID for crash reports (call after user signs in)
  Future<void> setUserId(String userId) async {
    developer.log('Crashlytics: Setting user ID - $userId', name: 'CrashlyticsService');
    await _crashlytics.setUserIdentifier(userId);
  }

  /// Clear user ID (call after user signs out)
  Future<void> clearUserId() async {
    developer.log('Crashlytics: Clearing user ID', name: 'CrashlyticsService');
    await _crashlytics.setUserIdentifier('');
  }

  /// Set custom key-value pair for crash context
  /// Useful for debugging specific scenarios
  Future<void> setCustomKey(String key, dynamic value) async {
    await _crashlytics.setCustomKey(key, value);
  }

  // ============================================================================
  // ERROR LOGGING
  // ============================================================================

  /// Log a non-fatal error with optional stack trace
  /// Use this for caught exceptions you want to track
  Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    developer.log(
      'Crashlytics: Logging error - $error',
      name: 'CrashlyticsService',
      error: error,
      stackTrace: stackTrace,
    );

    await _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }

  /// Log a custom message (shows up in Crashlytics logs)
  /// Useful for tracking app flow before crashes
  Future<void> log(String message) async {
    developer.log('Crashlytics: $message', name: 'CrashlyticsService');
    await _crashlytics.log(message);
  }

  // ============================================================================
  // SPECIFIC ERROR SCENARIOS
  // ============================================================================

  /// Log Firebase Function errors
  Future<void> logFunctionError(
    String functionName,
    dynamic error,
    StackTrace? stackTrace,
  ) async {
    await setCustomKey('function_name', functionName);
    await logError(
      error,
      stackTrace,
      reason: 'Cloud Function Error: $functionName',
    );
  }

  /// Log Firestore operation errors
  Future<void> logFirestoreError(
    String operation,
    dynamic error,
    StackTrace? stackTrace,
  ) async {
    await setCustomKey('firestore_operation', operation);
    await logError(
      error,
      stackTrace,
      reason: 'Firestore Error: $operation',
    );
  }

  /// Log authentication errors
  Future<void> logAuthError(
    String authMethod,
    dynamic error,
    StackTrace? stackTrace,
  ) async {
    await setCustomKey('auth_method', authMethod);
    await logError(
      error,
      stackTrace,
      reason: 'Authentication Error: $authMethod',
    );
  }

  /// Log payment/wallet operation errors
  Future<void> logWalletError(
    String operation,
    String? groupId,
    dynamic error,
    StackTrace? stackTrace,
  ) async {
    await setCustomKey('wallet_operation', operation);
    if (groupId != null) {
      await setCustomKey('group_id', groupId);
    }
    await logError(
      error,
      stackTrace,
      reason: 'Wallet Error: $operation',
    );
  }

  /// Log event registration errors
  Future<void> logEventError(
    String operation,
    String? eventId,
    dynamic error,
    StackTrace? stackTrace,
  ) async {
    await setCustomKey('event_operation', operation);
    if (eventId != null) {
      await setCustomKey('event_id', eventId);
    }
    await logError(
      error,
      stackTrace,
      reason: 'Event Error: $operation',
    );
  }

  // ============================================================================
  // TESTING
  // ============================================================================

  /// Force a crash (for testing Crashlytics integration)
  /// DO NOT USE IN PRODUCTION CODE
  void testCrash() {
    developer.log('Crashlytics: Forcing test crash', name: 'CrashlyticsService');
    _crashlytics.crash();
  }

  /// Log a test error (non-fatal, for testing)
  Future<void> testError() async {
    developer.log('Crashlytics: Logging test error', name: 'CrashlyticsService');
    await logError(
      Exception('This is a test error for Crashlytics'),
      StackTrace.current,
      reason: 'Test Error',
    );
  }

  // ============================================================================
  // CONFIGURATION
  // ============================================================================

  /// Enable/disable Crashlytics collection
  /// Useful for development or user privacy settings
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    developer.log(
      'Crashlytics: ${enabled ? "Enabling" : "Disabling"} crash collection',
      name: 'CrashlyticsService',
    );
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }

  /// Check if Crashlytics is currently collecting crashes
  bool isCrashlyticsCollectionEnabled() {
    return _crashlytics.isCrashlyticsCollectionEnabled;
  }
}
