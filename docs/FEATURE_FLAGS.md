# Feature Flags with Firebase Remote Config

This document explains how to use and configure feature flags in GetSpot using Firebase Remote Config.

## Overview

GetSpot uses Firebase Remote Config for feature flags, allowing you to enable/disable features for specific users without deploying new code.

## Current Feature Flags

### `crash_test_enabled_users`

Controls visibility of the debug crash test buttons in the user profile screen.

- **Type:** String (JSON array of user IDs)
- **Default Value:** `[]` (empty array - disabled for all users)
- **Use Case:** Enable Crashlytics testing for specific developers

## Setup Instructions

### 1. Access Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (`getspot01`)
3. Navigate to **Remote Config** in the left sidebar (under "Engage")

### 2. Create the Feature Flag Parameter

1. Click **Add parameter**
2. Set the following:
   - **Parameter key:** `crash_test_enabled_users`
   - **Default value:** `["YOUR_USER_ID_HERE"]`
   - **Description:** "List of user IDs who can access crash test buttons"
   - **Value type:** String

3. Click **Save**

### 3. Find Your User ID

To get your Firebase User ID:

**Option A: From Firebase Console**
1. Go to **Authentication** → **Users**
2. Find your account and copy the **User UID**

**Option B: From the app logs**
1. Run the app with Flutter DevTools
2. Check the logs for messages like: "Showing HomeScreen for user: [USER_ID]"

**Option C: Add temporary debug code**
```dart
// In any screen where FirebaseAuth.instance.currentUser is available
print('My User ID: ${FirebaseAuth.instance.currentUser?.uid}');
```

### 4. Update the Parameter Value

1. In Firebase Console → Remote Config
2. Click on the `crash_test_enabled_users` parameter
3. Update the **Default value** to include your user ID:
   ```json
   ["your-user-id-here"]
   ```
4. To add multiple users:
   ```json
   ["user-id-1", "user-id-2", "user-id-3"]
   ```

5. Click **Publish changes** in the top right

### 5. Test the Feature Flag

1. **Force refresh** (optional, for immediate testing):
   - Remote Config has a default cache of 1 hour
   - To test immediately, restart the app completely (kill and relaunch)
   - Or wait up to 1 hour for the new config to be fetched

2. **Verify in the app:**
   - Open the app
   - Go to your profile (person icon in top right)
   - If your user ID is in the list, you should see an orange "Debug Tools" card with "Test Crash" and "Test Error" buttons

3. **Test Crashlytics:**
   - Tap "Test Error" - logs a non-fatal error to Crashlytics
   - Tap "Test Crash" - forces an app crash (use only on iOS, not recommended for production testing)

## How It Works

### Code Flow

1. **Initialization** (`main.dart:51`):
   ```dart
   await FeatureFlagService().initialize();
   ```
   - Fetches Remote Config values on app startup
   - Sets default values as fallback

2. **Feature Check** (`member_profile_screen.dart:140`):
   ```dart
   if (FeatureFlagService().canAccessCrashTest(user.uid))
   ```
   - Checks if current user ID is in the enabled list
   - Shows/hides debug tools based on result

3. **Service Implementation** (`lib/services/feature_flag_service.dart`):
   - Singleton service wrapping Firebase Remote Config
   - Caches values for 1 hour (configurable)
   - Gracefully handles errors (defaults to disabled)

### Cache Behavior

- **Fetch Interval:** 1 hour (configured in `feature_flag_service.dart:33`)
- **Fetch Timeout:** 10 seconds
- **Cache Location:** Device local storage (managed by Firebase SDK)

To change the fetch interval:
```dart
// In lib/services/feature_flag_service.dart
minimumFetchInterval: const Duration(hours: 1), // Change this
```

## Adding New Feature Flags

### 1. Add to Remote Config Defaults

In `lib/services/feature_flag_service.dart`, add to the defaults map:

```dart
await _remoteConfig.setDefaults({
  'crash_test_enabled_users': '[]',
  'your_new_flag': 'default_value', // Add here
});
```

### 2. Create Getter Method

Add a method to `FeatureFlagService`:

```dart
bool isNewFeatureEnabled(String userId) {
  try {
    final enabledUsersJson = _remoteConfig.getString('your_new_flag');
    final List<dynamic> enabledUsers = jsonDecode(enabledUsersJson);
    return enabledUsers.contains(userId);
  } catch (e) {
    return false; // Default to disabled on error
  }
}
```

### 3. Use in Your Code

```dart
if (FeatureFlagService().isNewFeatureEnabled(user.uid)) {
  // Show new feature
}
```

### 4. Configure in Firebase Console

1. Add the parameter in Remote Config
2. Set the value
3. Publish changes

## Remote Config Conditions (Advanced)

For more sophisticated targeting, use Remote Config conditions:

1. In Firebase Console → Remote Config
2. Click **Add condition**
3. Options:
   - **App version:** Target specific app versions
   - **Platform:** iOS, Android, Web
   - **User in audience:** Based on Analytics audiences
   - **User property:** Custom user properties
   - **Device language:** Target by language

Example: Enable for all iOS users in v1.1.0+
1. Create condition: "iOS v1.1.0+"
   - Platform = iOS
   - App version >= 1.1.0
2. Add conditional value to your parameter
3. Set value to `true` for this condition

## Troubleshooting

### Feature flag not updating

1. **Check publish status:** Ensure changes are published in Firebase Console
2. **Wait for cache:** Default cache is 1 hour, restart app or wait
3. **Check logs:** Look for "Remote Config initialized successfully" in logs
4. **Verify user ID:** Ensure the user ID in the array matches exactly

### Feature showing for wrong users

1. **Check JSON format:** Must be valid JSON array of strings
2. **Check quotes:** User IDs must be in quotes: `["id1", "id2"]`
3. **Check typos:** User IDs are case-sensitive

### Remote Config initialization fails

- Check Firebase project configuration
- Ensure `firebase_remote_config` dependency is installed
- Check network connectivity
- App will continue with default values (feature disabled)

## Best Practices

1. **Default to disabled:** New features should default to off for safety
2. **Test thoroughly:** Always test both enabled and disabled states
3. **Document flags:** Keep this file updated with all active flags
4. **Clean up:** Remove old feature flags once features are fully rolled out
5. **Use conditions:** For complex targeting, use Remote Config conditions instead of user ID lists
6. **Monitor usage:** Track feature flag usage with Analytics

## Security Notes

- Remote Config values are **public** - don't store secrets
- Anyone can inspect Remote Config values in the app
- Use Firestore Security Rules for actual permission enforcement
- Feature flags are UI-only controls, not security boundaries
