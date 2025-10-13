import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'dart:developer' as developer;
import 'dart:convert';

/// Singleton service for Firebase Remote Config feature flags
///
/// Provides centralized feature flag management using Firebase Remote Config.
/// Supports user-specific flags and dynamic configuration.
class FeatureFlagService {
  static final FeatureFlagService _instance = FeatureFlagService._internal();
  factory FeatureFlagService() => _instance;
  FeatureFlagService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  bool _initialized = false;

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize Remote Config with default values and fetch settings
  /// Call this once during app startup
  Future<void> initialize() async {
    if (_initialized) {
      developer.log('Remote Config already initialized', name: 'FeatureFlagService');
      return;
    }

    try {
      developer.log('Initializing Remote Config', name: 'FeatureFlagService');

      // Set config settings
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1), // Fetch at most once per hour
      ));

      // Set default values
      await _remoteConfig.setDefaults({
        'crash_test_enabled_users': '[]', // JSON array of user IDs
      });

      // Fetch and activate
      await _remoteConfig.fetchAndActivate();

      _initialized = true;
      developer.log('Remote Config initialized successfully', name: 'FeatureFlagService');
    } catch (e, stackTrace) {
      developer.log(
        'Failed to initialize Remote Config',
        name: 'FeatureFlagService',
        error: e,
        stackTrace: stackTrace,
      );
      // Set as initialized anyway to avoid blocking the app
      _initialized = true;
    }
  }

  /// Manually fetch latest config from server
  /// Use this sparingly as it counts against rate limits
  Future<void> refresh() async {
    try {
      developer.log('Refreshing Remote Config', name: 'FeatureFlagService');
      await _remoteConfig.fetchAndActivate();
      developer.log('Remote Config refreshed', name: 'FeatureFlagService');
    } catch (e, stackTrace) {
      developer.log(
        'Failed to refresh Remote Config',
        name: 'FeatureFlagService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================================
  // FEATURE FLAGS
  // ============================================================================

  /// Check if crash test button should be visible for a specific user
  bool canAccessCrashTest(String userId) {
    try {
      final enabledUsersJson = _remoteConfig.getString('crash_test_enabled_users');
      final List<dynamic> enabledUsers = jsonDecode(enabledUsersJson);
      final canAccess = enabledUsers.contains(userId);

      developer.log(
        'Crash test access check for user $userId: $canAccess',
        name: 'FeatureFlagService',
      );

      return canAccess;
    } catch (e, stackTrace) {
      developer.log(
        'Error checking crash test access',
        name: 'FeatureFlagService',
        error: e,
        stackTrace: stackTrace,
      );
      return false; // Default to disabled on error
    }
  }

  // ============================================================================
  // GENERIC HELPERS
  // ============================================================================

  /// Get string value from Remote Config
  String getString(String key) {
    return _remoteConfig.getString(key);
  }

  /// Get boolean value from Remote Config
  bool getBool(String key) {
    return _remoteConfig.getBool(key);
  }

  /// Get int value from Remote Config
  int getInt(String key) {
    return _remoteConfig.getInt(key);
  }

  /// Get double value from Remote Config
  double getDouble(String key) {
    return _remoteConfig.getDouble(key);
  }

  /// Check if Remote Config is initialized
  bool get isInitialized => _initialized;
}
