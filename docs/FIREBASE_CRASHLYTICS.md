# Firebase Crashlytics Integration

This document explains how Firebase Crashlytics is integrated into GetSpot for crash reporting and error tracking.

## Overview

Firebase Crashlytics provides real-time crash reporting that helps you track, prioritize, and fix stability issues that erode app quality. Crashlytics saves you troubleshooting time by intelligently grouping crashes and highlighting the circumstances that lead to them.

## Benefits for GetSpot

### 1. **Automatic Crash Detection**
- Catches all uncaught Flutter errors
- Captures native platform crashes (iOS/Android)
- Records async errors that fall outside Flutter's error zone

### 2. **Detailed Crash Reports**
- Full stack traces for every crash
- Device information (model, OS version, orientation)
- Custom keys and logs for context
- User IDs to identify affected users

### 3. **Prioritization**
- Crashes sorted by impact (number of users affected)
- Crash-free user percentage tracking
- Trends over time (increasing vs decreasing)

### 4. **Zero User Friction**
- Automatic submission (no user action required)
- Minimal performance impact
- Works offline (queues reports for later)

### 5. **GetSpot-Specific Value**
- Track errors in **critical flows**: event registration, wallet operations, payments
- Identify **platform-specific issues**: iOS vs Android bugs
- Monitor **Cloud Function errors**: function call failures, network issues
- Catch **silent failures**: errors users don't report

## Implementation

### Package
```yaml
# pubspec.yaml
firebase_crashlytics: ^4.2.2
```

### Initialization (`lib/main.dart`)

Crashlytics is initialized in the `main()` function before the app starts:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  // Pass all uncaught asynchronous errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const MyApp());
}
```

### Service Class (`lib/services/crashlytics_service.dart`)

A singleton service provides centralized crash reporting:

```dart
final crashlytics = CrashlyticsService();

// Set user ID (called after sign-in)
await crashlytics.setUserId(userId);

// Log custom errors
await crashlytics.logError(error, stackTrace, reason: 'Operation failed');

// Log messages for context
await crashlytics.log('User started event registration');

// Clear user ID (called after sign-out)
await crashlytics.clearUserId();
```

### User Context

User IDs are automatically set when users sign in:

```dart
// In _AuthWrapperState (main.dart)
if (user != null) {
  _crashlytics.setUserId(user.uid);
}
```

This helps identify:
- Which users are affected by crashes
- If crashes correlate with specific accounts
- User patterns leading to crashes

## Usage Examples

### 1. **Logging Auth Errors**

```dart
// In auth_service.dart
try {
  await signInWithGoogle();
} catch (e, stackTrace) {
  await _crashlytics.logAuthError('google', e, stackTrace);
  rethrow;
}
```

### 2. **Logging Cloud Function Errors**

```dart
try {
  final result = await callable.call({'eventId': eventId});
} catch (e, stackTrace) {
  await CrashlyticsService().logFunctionError('registerForEvent', e, stackTrace);
  // Show error to user
}
```

### 3. **Logging Wallet Operations**

```dart
try {
  await deductWalletBalance(userId, groupId, amount);
} catch (e, stackTrace) {
  await CrashlyticsService().logWalletError(
    'deduct_balance',
    groupId,
    e,
    stackTrace,
  );
  rethrow;
}
```

### 4. **Adding Contextual Information**

```dart
// Before a risky operation
await crashlytics.log('Starting event registration for event: $eventId');
await crashlytics.setCustomKey('event_id', eventId);
await crashlytics.setCustomKey('event_capacity', capacity);

// If crash occurs, these details will be included
```

### 5. **Tracking Non-Fatal Errors**

```dart
// Catch errors you want to track but don't want to crash the app
try {
  await syncData();
} catch (e, stackTrace) {
  await crashlytics.logError(e, stackTrace, fatal: false);
  // Continue execution
}
```

## Viewing Crash Reports

### Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **getspot01**
3. Navigate to **Crashlytics** in the left sidebar

### Dashboard Sections

**Issues Tab:**
- All crashes grouped by similarity
- Number of users affected
- Crash-free users percentage
- Events (crash count)

**Event Detail:**
- Full stack trace
- Device information
- Operating system
- Custom keys and logs
- User identifier
- Time of crash

**Velocity Alerts:**
- Get notified when crash rates spike
- Set custom thresholds
- Email/Slack integration

## Custom Keys

Add context to crashes with custom key-value pairs:

```dart
// Before potentially problematic code
await crashlytics.setCustomKey('group_id', groupId);
await crashlytics.setCustomKey('user_role', 'admin');
await crashlytics.setCustomKey('wallet_balance', balance);
```

These appear in crash reports to help debug.

## Breadcrumb Logs

Log events leading up to a crash:

```dart
await crashlytics.log('User opened event details');
await crashlytics.log('User tapped register button');
await crashlytics.log('Checking wallet balance...');
// If crash happens here, all logs are included in report
```

## Testing Crashlytics

### Test Crash (Development Only)

**⚠️ WARNING: DO NOT USE IN PRODUCTION**

```dart
// Force a crash to test Crashlytics integration
CrashlyticsService().testCrash();
```

### Test Non-Fatal Error

```dart
// Log a test error (non-fatal)
await CrashlyticsService().testError();
```

### Verify Integration

1. **Trigger Test Crash**:
   ```dart
   // Add a button in dev mode
   ElevatedButton(
     onPressed: () => CrashlyticsService().testCrash(),
     child: Text('Test Crash'),
   );
   ```

2. **Run the App**:
   ```bash
   flutter run
   ```

3. **Tap the Button**: App will crash

4. **Restart the App**: Crash report is sent on next launch

5. **Check Firebase Console**: Report appears in 1-2 minutes

## Crash-Free Users Metric

Firebase tracks the **percentage of users who didn't experience crashes**:

```
Crash-Free Users = (Users without crashes / Total users) × 100
```

**Industry Standards:**
- ✅ **99.0%+**: Excellent stability
- ⚠️ **97-99%**: Good, but room for improvement
- ❌ **<97%**: Needs immediate attention

**GetSpot Goal:** Maintain **>99% crash-free users**

## Best Practices

### ✅ DO:
- Set user ID after sign-in
- Clear user ID after sign-out
- Add custom keys for important context (event IDs, group IDs)
- Log breadcrumbs before critical operations
- Use specific error methods (`logWalletError`, `logEventError`)
- Track both fatal and non-fatal errors

### ❌ DON'T:
- Log personally identifiable information (PII) like email, names
- Use test crashes in production
- Ignore non-fatal errors (they often predict crashes)
- Over-log (creates noise)
- Store sensitive data in custom keys

## Error Types Tracked

### Automatic (No Code Required)
- Flutter framework errors
- Uncaught exceptions
- Async errors
- Native platform crashes (iOS/Android)

### Manual (Via Code)
- Authentication errors
- Cloud Function errors
- Firestore operation errors
- Wallet/payment errors
- Event registration errors
- Custom business logic errors

## Privacy & Data

### Data Collected
- Stack traces
- Device model and OS version
- App version
- Timestamp
- User ID (if set)
- Custom keys
- Breadcrumb logs

### NOT Collected
- User names
- Email addresses
- Personal data
- Screen contents
- User input
- Credentials

### GDPR/CCPA Compliance
- No PII is tracked by default
- User IDs are anonymized identifiers
- Can disable Crashlytics collection per user:

```dart
// If user opts out
await CrashlyticsService().setCrashlyticsCollectionEnabled(false);
```

## Integration Checklist

- [x] Package added to `pubspec.yaml`
- [x] Crashlytics initialized in `main()`
- [x] Global error handlers configured
- [x] CrashlyticsService created
- [x] User ID set on sign-in
- [x] User ID cleared on sign-out
- [x] Auth errors logged
- [ ] Cloud Function errors logged (TODO: Add to screens)
- [ ] Firestore errors logged (TODO: Add to services)
- [ ] Wallet errors logged (TODO: Add to wallet operations)
- [ ] Event errors logged (TODO: Add to event screens)
- [x] Test crash verified in Firebase Console

## Platform-Specific Setup

### iOS
Firebase Crashlytics works automatically on iOS. No additional configuration required.

The `firebase_crashlytics` plugin handles all native setup.

### Android
Firebase Crashlytics works automatically on Android. No additional configuration required.

The `firebase_crashlytics` plugin handles all native setup.

### Web
Crashlytics does **not** support web. For web errors, use:
- Firebase Analytics (`AnalyticsService.logError()`)
- Browser console logs
- Third-party tools like Sentry

## Debugging Tips

### Crashes Not Appearing
1. Wait 1-2 minutes after crash (processing delay)
2. Ensure app restarted after crash (reports sent on launch)
3. Check Firebase console project ID matches app
4. Verify `google-services.json` (Android) / `GoogleService-Info.plist` (iOS)

### Symbolication Issues
- Flutter crashes are automatically symbolicated
- Native crashes require symbol upload (handled automatically by Firebase)

### Testing in Debug Mode
Debug builds send crashes immediately. Release builds batch them.

## Alerts & Notifications

Set up velocity alerts in Firebase Console:

1. **Crashlytics → Velocity Alerts**
2. **Create Alert**
3. **Set Threshold**: e.g., "Alert if crashes > 1% of users"
4. **Choose Channel**: Email, Slack, etc.

## Resources

- [Firebase Crashlytics Documentation](https://firebase.google.com/docs/crashlytics)
- [Flutter Crashlytics Plugin](https://firebase.flutter.dev/docs/crashlytics/overview)
- [Best Practices Guide](https://firebase.google.com/docs/crashlytics/get-started)
- [Crash Reporting Guide](https://firebase.google.com/docs/crashlytics/customize-crash-reports)

## Next Steps

To complete Crashlytics integration:

1. **Add Error Logging to Screens**:
   - Event registration errors
   - Wallet operation errors
   - Group creation errors

2. **Add Error Logging to Services**:
   - Firestore query errors
   - Cloud Function call errors
   - Network errors

3. **Set Up Alerts**:
   - Configure velocity alerts for crash spikes
   - Set up email notifications

4. **Monitor Dashboard**:
   - Check weekly crash-free user percentage
   - Address high-impact crashes first
   - Track trends over time

5. **Test Thoroughly**:
   - Verify crashes appear in console
   - Confirm user IDs are logged
   - Check custom keys appear
