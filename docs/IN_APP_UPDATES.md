# In-App Update Prompts

This document explains how GetSpot implements in-app update prompts to notify users when a new version is available.

## Overview

GetSpot uses the [`upgrader`](https://pub.dev/packages/upgrader) package to automatically check for app updates and display prompts to users. This works on both iOS and Android platforms.

## Implementation

### Package
- **Package**: `upgrader: ^11.2.0`
- **Location**: Added to `pubspec.yaml` dependencies

### Integration
The `UpgradeAlert` widget wraps the `HomeScreen` in `lib/main.dart`:

```dart
return UpgradeAlert(
  upgrader: Upgrader(
    durationUntilAlertAgain: const Duration(days: 1),
  ),
  child: const HomeScreen(),
);
```

### Configuration

**Current Settings:**
- **Alert Frequency**: Once per day (`durationUntilAlertAgain: Duration(days: 1)`)
- **Trigger**: Shown when user opens the app and is signed in
- **Location**: Appears on the HomeScreen after successful authentication

## How It Works

### For iOS:
1. The package checks the App Store for the latest version using the iTunes Search API
2. Compares current app version (from `pubspec.yaml`) with App Store version
3. If a newer version exists, displays a Material Design dialog
4. Dialog includes:
   - Title: "Update App?"
   - Message: "A new version is available..."
   - Buttons: "Later" and "Update"
5. Tapping "Update" opens the App Store to the app's page

### For Android:
1. The package checks Google Play Store for the latest version
2. Compares current app version with Play Store version
3. If a newer version exists, displays the same dialog style
4. Tapping "Update" opens Google Play Store to the app's page

### Version Detection
- **Current Version**: Read from `pubspec.yaml` (`version: 1.0.1+2`)
- **Store Version**: Fetched from App Store (iOS) or Google Play Store (Android)
- **Comparison**: Uses semantic versioning (major.minor.patch)

## Customization Options

You can customize the `Upgrader` behavior:

```dart
Upgrader(
  // How often to show the prompt (default: 3 days)
  durationUntilAlertAgain: const Duration(days: 1),

  // Minimum app version required (forces update)
  minAppVersion: '1.0.0',

  // Custom messages
  messages: UpgraderMessages(code: 'en'),

  // Show release notes
  showReleaseNotes: true,

  // Custom country code for App Store lookup
  countryCode: 'US',
)
```

## Testing

### Test in Development:
1. **Simulate Update Available**:
   - Lower the version in `pubspec.yaml` (e.g., `version: 0.9.0+1`)
   - Build and run the app
   - The prompt should appear since the store version is higher

2. **Test "Later" Button**:
   - Tap "Later" to dismiss
   - Close and reopen the app
   - Dialog should not appear again for 1 day (per configuration)

3. **Test "Update" Button**:
   - Tap "Update"
   - Verify it opens the App Store/Play Store
   - Verify it navigates to the correct app page

### Test in Production:
1. Deploy a new version to App Store/Play Store
2. Keep an older version on your test device
3. Open the app
4. Verify the update prompt appears
5. Tap "Update" and verify correct store page opens

## User Experience

**When Update is Available:**
```
┌────────────────────────────────────┐
│          Update App?               │
├────────────────────────────────────┤
│ A new version of GetSpot is        │
│ available!                         │
│                                    │
│ Version 1.0.2 is now available.    │
│ You have version 1.0.1.            │
│                                    │
│ Would you like to update now?      │
├────────────────────────────────────┤
│         [Later]      [Update]      │
└────────────────────────────────────┘
```

**Behavior:**
- ✅ Non-blocking: Users can dismiss and continue using the app
- ✅ Persistent: Reappears after the configured duration (1 day)
- ✅ User-friendly: Clear call-to-action with easy access to store
- ✅ Cross-platform: Works consistently on iOS and Android

## Advanced Configuration

### Force Update for Critical Versions

To require users to update (blocking usage):

```dart
Upgrader(
  minAppVersion: '1.0.5', // Users below this version MUST update
  durationUntilAlertAgain: const Duration(seconds: 1),
)
```

### Custom Dialog

For a fully custom UI:

```dart
UpgradeAlert(
  upgrader: Upgrader(),
  dialogStyle: UpgradeDialogStyle.cupertino, // iOS-style dialog
  child: const HomeScreen(),
)
```

Or use `UpgradeCard` for an inline widget instead of a dialog:

```dart
UpgradeCard(
  upgrader: Upgrader(),
)
```

## Troubleshooting

### Prompt Not Showing
1. **Check versions**: Ensure `pubspec.yaml` version is lower than store version
2. **Check frequency**: Wait for `durationUntilAlertAgain` period to pass
3. **Check store**: Verify app is published and live in stores
4. **Clear cache**: The package caches version checks; reinstall app to clear

### Wrong App Store Page
1. **iOS**: Verify bundle identifier matches App Store Connect
2. **Android**: Verify package name matches Google Play Console

### Version Format Issues
- Ensure `pubspec.yaml` uses format: `major.minor.patch+build`
- Example: `1.0.1+2` (not `1.0.1-beta` or other formats)

## Store Requirements

### iOS (App Store)
- **Bundle ID**: Must match the one in App Store Connect (e.g., `com.getspot.app`)
- **Version Format**: Follows `CFBundleShortVersionString` (e.g., `1.0.1`)
- **Lookup**: Uses iTunes Search API (no authentication needed)

### Android (Google Play)
- **Package Name**: Must match the one in Google Play Console
- **Version Format**: Follows `versionName` (e.g., `1.0.1`)
- **Lookup**: Uses Google Play Store API (no authentication needed)

## Deployment Checklist

When releasing a new version:

- [ ] Increment version in `pubspec.yaml` (e.g., `1.0.1+2` → `1.0.2+3`)
- [ ] Build and test the new version
- [ ] Deploy to App Store Connect (iOS) and/or Google Play Console (Android)
- [ ] Wait for store approval and live status
- [ ] Test with older version to verify update prompt appears
- [ ] Monitor analytics for update adoption rate

## Analytics Tracking

The upgrader package doesn't automatically track analytics, but you can add tracking:

```dart
UpgradeAlert(
  upgrader: Upgrader(),
  onUpdate: () {
    // User tapped "Update"
    AnalyticsService().logEvent(name: 'app_update_tapped');
  },
  onLater: () {
    // User tapped "Later"
    AnalyticsService().logEvent(name: 'app_update_dismissed');
  },
  child: const HomeScreen(),
)
```

## Resources

- [Upgrader Package Documentation](https://pub.dev/packages/upgrader)
- [iTunes Search API](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/index.html)
- [Android In-App Updates](https://developer.android.com/guide/playstore/in-app-updates)
- [Semantic Versioning](https://semver.org/)

## Notes

- **Web**: The upgrader package doesn't support web. For web deployments, users automatically get the latest version on page refresh.
- **Performance**: Version checks are cached and don't impact app startup performance significantly.
- **Privacy**: No user data is sent; only version comparison happens locally after fetching store data.
