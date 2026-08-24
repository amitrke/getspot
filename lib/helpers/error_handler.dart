import 'dart:developer' as developer;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:getspot/services/crashlytics_service.dart';

/// Centralized error handler for consistent error logging and reporting.
///
/// This utility standardizes error handling across the app by:
/// - Always capturing stack traces
/// - Logging to both developer console and Crashlytics
/// - Providing user-friendly error messages
/// - Categorizing errors by type for better debugging
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final CrashlyticsService _crashlytics = CrashlyticsService();

  /// Handle a general error with logging and optional Crashlytics reporting.
  ///
  /// Always use this pattern:
  /// ```dart
  /// try {
  ///   // your code
  /// } catch (e, st) {
  ///   ErrorHandler().handle(e, st, context: 'MyScreen._loadData');
  /// }
  /// ```
  Future<void> handle(
    dynamic error,
    StackTrace stackTrace, {
    required String context,
    bool reportToCrashlytics = true,
  }) async {
    developer.log(
      'Error in $context: $error',
      name: 'ErrorHandler',
      error: error,
      stackTrace: stackTrace,
    );

    if (reportToCrashlytics) {
      await _crashlytics.logError(
        error,
        stackTrace,
        reason: 'Error in $context',
      );
    }
  }

  /// Handle Firebase Function errors with specific categorization.
  ///
  /// Use for errors from Cloud Functions callable functions:
  /// ```dart
  /// try {
  ///   await callable.call(data);
  /// } on FirebaseFunctionsException catch (e, st) {
  ///   ErrorHandler().handleFunctionError(e, st, functionName: 'createGroup');
  /// } catch (e, st) {
  ///   ErrorHandler().handle(e, st, context: 'createGroup');
  /// }
  /// ```
  Future<void> handleFunctionError(
    FirebaseFunctionsException error,
    StackTrace stackTrace, {
    required String functionName,
  }) async {
    developer.log(
      'Function error in $functionName: ${error.code} - ${error.message}',
      name: 'ErrorHandler',
      error: error,
      stackTrace: stackTrace,
    );

    await _crashlytics.logFunctionError(functionName, error, stackTrace);
  }

  /// Handle Firebase Auth errors with specific categorization.
  ///
  /// Use for authentication-related errors:
  /// ```dart
  /// try {
  ///   await auth.signIn();
  /// } on FirebaseAuthException catch (e, st) {
  ///   ErrorHandler().handleAuthError(e, st, method: 'signInWithGoogle');
  /// }
  /// ```
  Future<void> handleAuthError(
    FirebaseAuthException error,
    StackTrace stackTrace, {
    required String method,
  }) async {
    developer.log(
      'Auth error in $method: ${error.code} - ${error.message}',
      name: 'ErrorHandler',
      error: error,
      stackTrace: stackTrace,
    );

    await _crashlytics.logAuthError(method, error, stackTrace);
  }

  /// Handle Firestore operation errors.
  ///
  /// Use for Firestore read/write errors:
  /// ```dart
  /// try {
  ///   await firestore.collection('x').doc('y').get();
  /// } catch (e, st) {
  ///   ErrorHandler().handleFirestoreError(e, st, operation: 'getUser');
  /// }
  /// ```
  Future<void> handleFirestoreError(
    dynamic error,
    StackTrace stackTrace, {
    required String operation,
  }) async {
    developer.log(
      'Firestore error in $operation: $error',
      name: 'ErrorHandler',
      error: error,
      stackTrace: stackTrace,
    );

    await _crashlytics.logFirestoreError(operation, error, stackTrace);
  }

  /// Handle event-related errors.
  Future<void> handleEventError(
    dynamic error,
    StackTrace stackTrace, {
    required String operation,
    String? eventId,
  }) async {
    developer.log(
      'Event error in $operation (eventId: $eventId): $error',
      name: 'ErrorHandler',
      error: error,
      stackTrace: stackTrace,
    );

    await _crashlytics.logEventError(operation, eventId, error, stackTrace);
  }

  /// Handle wallet/transaction errors.
  Future<void> handleWalletError(
    dynamic error,
    StackTrace stackTrace, {
    required String operation,
    String? groupId,
  }) async {
    developer.log(
      'Wallet error in $operation (groupId: $groupId): $error',
      name: 'ErrorHandler',
      error: error,
      stackTrace: stackTrace,
    );

    await _crashlytics.logWalletError(operation, groupId, error, stackTrace);
  }

  /// Get a user-friendly error message from an exception.
  ///
  /// Converts technical error messages to user-readable strings.
  String getUserMessage(dynamic error) {
    if (error is FirebaseFunctionsException) {
      return error.message ?? 'An unexpected error occurred. Please try again.';
    }

    if (error is FirebaseAuthException) {
      return _getAuthErrorMessage(error.code);
    }

    if (error is Exception) {
      final message = error.toString();
      // Remove "Exception: " prefix if present
      if (message.startsWith('Exception: ')) {
        return message.substring(11);
      }
      return message;
    }

    return 'An unexpected error occurred. Please try again.';
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
