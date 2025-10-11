# Firebase Analytics Integration

This document explains how Firebase Analytics is integrated into GetSpot and how to track custom events.

## Overview

Firebase Analytics automatically collects user behavior data and provides insights into:
- User engagement
- Retention rates
- App usage patterns
- Screen views
- Custom events

## Setup

### 1. Package Installed
```yaml
# pubspec.yaml
firebase_analytics: ^11.3.3
```

### 2. Initialization
Analytics is automatically initialized when Firebase is initialized in `main.dart`.

### 3. Navigation Tracking
Automatic screen view tracking is enabled via `FirebaseAnalyticsObserver`:

```dart
// main.dart
MaterialApp(
  navigatorObservers: [
    AnalyticsService().getAnalyticsObserver(),
  ],
  // ...
)
```

## Analytics Service

All analytics tracking is centralized in `lib/services/analytics_service.dart`.

### Usage Example:
```dart
import 'package:getspot/services/analytics_service.dart';

final analytics = AnalyticsService();

// Track sign up
await analytics.logSignUp('google');

// Track custom event
await analytics.logCreateGroup();
```

---

## Tracked Events

### 🔐 Authentication Events

| Event | Method | Description |
|-------|--------|-------------|
| `sign_up` | `logSignUp(method)` | User creates account (method: 'google', 'apple', 'email') |
| `login` | `logLogin(method)` | User signs in (method: 'google', 'apple', 'email') |
| `logout` | `logLogout()` | User signs out |

**Parameters:**
- `signUpMethod` / `loginMethod`: Authentication method used

---

### 👥 Group Events

| Event | Method | Description |
|-------|--------|-------------|
| `create_group` | `logCreateGroup()` | User creates a new group |
| `join_group_request` | `logJoinGroupRequest()` | User requests to join a group |
| `join_group` | `logJoinGroupSuccess()` | User successfully joins a group |
| `leave_group` | `logLeaveGroup()` | User leaves a group |
| `approve_join_request` | `logApproveJoinRequest()` | Admin approves join request |
| `deny_join_request` | `logDenyJoinRequest()` | Admin denies join request |
| `remove_member` | `logRemoveMember()` | Admin removes a member |

---

### 📅 Event Management Events

| Event | Method | Description |
|-------|--------|-------------|
| `create_event` | `logCreateEvent()` | User creates a new event |
| `register_for_event` | `logRegisterForEvent(status)` | User registers for event |
| `withdraw_from_event` | `logWithdrawFromEvent(afterDeadline)` | User withdraws from event |
| `cancel_event` | `logCancelEvent()` | Admin cancels an event |
| `update_event_capacity` | `logUpdateEventCapacity(old, new)` | Admin updates event capacity |

**Parameters:**
- `status`: Registration result ('confirmed', 'waitlisted', 'denied')
- `after_deadline`: Boolean indicating if withdrawal was after deadline
- `old_capacity` / `new_capacity` / `change`: Capacity update details

---

### 💰 Wallet & Transaction Events

| Event | Method | Description |
|-------|--------|-------------|
| `wallet_credit` | `logWalletCredit(amount)` | Admin credits user's wallet |
| `view_wallet` | `logViewWallet()` | User views wallet screen |
| `view_transaction_history` | `logViewTransactionHistory()` | User views transactions |

**Parameters:**
- `amount`: Credit amount

---

### 📢 Communication Events

| Event | Method | Description |
|-------|--------|-------------|
| `post_announcement` | `logPostAnnouncement()` | Admin posts announcement |
| `view_announcements` | `logViewAnnouncements()` | User views announcements |

---

### 📱 Screen View Events

| Event | Method | Description |
|-------|--------|-------------|
| `screen_view` | `logScreenView(screenName)` | User navigates to a screen |
| `pull_to_refresh` | `logPullToRefresh(screenName)` | User pulls to refresh |

**Parameters:**
- `screenName`: Name of the screen viewed/refreshed

---

### ❌ Error Tracking

| Event | Method | Description |
|-------|--------|-------------|
| `app_error` | `logError(type, message)` | Application error occurred |

**Parameters:**
- `error_type`: Type of error (e.g., 'network', 'auth', 'firestore')
- `error_message`: Error message
- `timestamp`: When the error occurred

---

## User Properties

Track long-term user attributes:

```dart
// Set user ID (automatically done on sign-in)
await analytics.setUserId(userId);

// Set custom property
await analytics.setUserProperty(
  name: 'user_type',
  value: 'organizer'
);
```

---

## Viewing Analytics Data

### Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **getspot01**
3. Navigate to **Analytics** in the left sidebar

### Available Reports:
- **Dashboard**: Overview of key metrics
- **Events**: All tracked events with counts
- **Conversions**: Track completion of key actions
- **Audiences**: Create user segments
- **Funnels**: Analyze user flow through steps
- **Retention**: See how many users return
- **DebugView**: Real-time event tracking (debug builds)

---

## Debug Mode

### Enable Debug Mode (for testing)

**iOS:**
```bash
# Add to Xcode scheme arguments
-FIRDebugEnabled
```

**Android:**
```bash
adb shell setprop debug.firebase.analytics.app com.getspot.app
```

**Web:**
```javascript
// In browser console
gtag('config', 'GA_MEASUREMENT_ID', { 'debug_mode': true });
```

View debug events in real-time:
1. Firebase Console → Analytics → DebugView
2. Run app in debug mode
3. See events appear immediately

---

## Best Practices

### ✅ DO:
- Use the centralized `AnalyticsService` for all tracking
- Log events at key user actions (sign up, create group, register for event)
- Track both successes and failures
- Use consistent naming conventions (snake_case for event names)
- Add relevant parameters to provide context

### ❌ DON'T:
- Track personally identifiable information (PII) like emails or names
- Log events too frequently (causes noise in data)
- Create duplicate events for the same action
- Use dynamic event names (makes analysis difficult)

---

## Adding New Events

When adding a new feature, follow these steps:

### 1. Add Method to AnalyticsService
```dart
// lib/services/analytics_service.dart
Future<void> logNewFeature({required String parameter}) async {
  developer.log('Analytics: New feature used', name: 'AnalyticsService');
  await _analytics.logEvent(
    name: 'new_feature_used',
    parameters: {'param': parameter},
  );
}
```

### 2. Call from Feature Code
```dart
import 'package:getspot/services/analytics_service.dart';

final analytics = AnalyticsService();
await analytics.logNewFeature(parameter: 'value');
```

### 3. Document in This File
Update the relevant section above with the new event.

---

## Privacy Considerations

### Data Collection
Firebase Analytics automatically collects:
- Device information (model, OS, screen size)
- App version and first open time
- Approximate location (country-level via IP)
- Session duration and engagement

### User Consent
- Analytics is enabled by default
- No PII is tracked (userID is anonymized in Firebase)
- Complies with GDPR/CCPA requirements

### Opt-Out (Future Implementation)
```dart
// To disable analytics for a user
await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
```

---

## Troubleshooting

### Events Not Showing Up
1. **Check DebugView** - Events can take 24 hours to appear in main reports
2. **Verify Firebase Config** - Ensure `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is correct
3. **Check App ID** - Must match Firebase project

### Common Issues
- **Duplicate events**: Ensure analytics calls aren't in widget build() methods
- **Missing parameters**: Check parameter names match exactly (case-sensitive)
- **Data delays**: Regular events take up to 24 hours to process

---

## Resources

- [Firebase Analytics Documentation](https://firebase.google.com/docs/analytics)
- [Flutter Firebase Analytics](https://firebase.flutter.dev/docs/analytics/overview)
- [Event Reference](https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event)
- [Parameter Reference](https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Param)
