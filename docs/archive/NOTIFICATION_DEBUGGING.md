# Push Notification Debugging Guide

This guide helps debug push notification issues in the GetSpot app.

## Recent Fixes Applied

### 1. iOS Configuration
- ✅ Added `UIBackgroundModes` with `remote-notification` to Info.plist
- ✅ Enhanced debug logging in notification service

### 2. Android Configuration
- ✅ Added `POST_NOTIFICATIONS` permission (required for Android 13+)
- ✅ Added `INTERNET` and `WAKE_LOCK` permissions

### 3. Debug Logging
- ✅ Added comprehensive logging to track token registration flow
- ✅ Added user authentication verification logs
- ✅ Added token save confirmation with verification

## Quick Diagnostic Checklist

### Step 1: Check Logs When User Logs In

Run the app with verbose logging:
```bash
flutter run --verbose
```

Look for these log messages in order:

1. **Authentication Check:**
   ```
   [NotificationService] Initializing notifications for user: <uid>
   ```
   ❌ If you see "WARNING: User not authenticated" - user is not logged in when notifications init

2. **Permission Status:**
   ```
   [NotificationService] Notification permission status: AuthorizationStatus.authorized
   ```
   ❌ If status is `.denied` or `.notDetermined` - user hasn't granted permission

3. **Token Obtained:**
   ```
   [NotificationService] FCM Token obtained: <first-20-chars>...
   ```
   ❌ If you see "ERROR: FCM Token is null" - FCM is not working

4. **Token Saved:**
   ```
   [NotificationService] ✓ Successfully saved FCM token to Firestore for user <uid>
   [NotificationService] Verified: User now has X FCM token(s)
   ```
   ❌ If you see "ERROR: Failed to save FCM token" - Firestore write failed

### Step 2: Verify iOS-Specific Setup (Required!)

#### A. Check Xcode Capabilities
1. Open the project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Select the Runner target → Signing & Capabilities tab

3. **Add Push Notifications Capability:**
   - Click "+ Capability"
   - Add "Push Notifications"

4. **Add Background Modes:**
   - Click "+ Capability"
   - Add "Background Modes"
   - Check "Remote notifications"

#### B. Verify APNs Configuration in Firebase Console
1. Go to Firebase Console → Project Settings
2. Click on your iOS app
3. Scroll to "Cloud Messaging" section
4. Ensure either:
   - **APNs Authentication Key** is uploaded (recommended), OR
   - **APNs Certificate** is uploaded

**Without APNs configuration, iOS push notifications will NOT work!**

### Step 3: Verify Android-Specific Setup

#### A. Check Runtime Permission (Android 13+)
For Android 13 and above, the app must request permission at runtime:

```dart
// This is already handled by firebase_messaging's requestPermission()
// but the user must see a system dialog and approve it
```

If the user denied permission:
- Go to App Settings → Notifications → Enable

#### B. Verify google-services.json
```bash
ls -la android/app/google-services.json
```
Ensure this file exists and is up to date from Firebase Console.

### Step 4: Check Firestore Token Storage

Use Firebase Console to verify tokens are being saved:

1. Go to Firestore Database
2. Navigate to: `users/{userId}`
3. Check for `fcmTokens` field (should be an array)
4. Verify it contains at least one token string

If `fcmTokens` is missing or empty:
- Check logs for save errors
- Verify Firestore security rules allow writes to users collection

### Step 5: Test Cloud Functions

#### A. Check Function Deployment
```bash
cd functions
firebase deploy --only functions:notifyOnNewEvent,functions:sendEventReminders
```

#### B. Test Notification Sending Manually
1. Go to Firebase Console → Cloud Messaging
2. Click "Send test message"
3. Paste an FCM token from the logs
4. Send a test notification

If test notification works → Backend is fine, issue is with app integration
If test notification fails → Check APNs/FCM configuration

#### C. Check Function Logs
```bash
cd functions
npm run logs
```

Look for:
- "No FCM tokens found for any users" → Tokens not saved properly
- "User X has notifications disabled" → Check `notificationsEnabled` field
- Error messages from FCM → Check token validity

### Step 6: Test Full Flow

1. **Create a new event in a group:**
   - This should trigger `notifyOnNewEvent` function
   - All group members should receive a notification

2. **Check the logs:**
   ```bash
   # In one terminal, run the app
   flutter run --verbose

   # In another terminal, watch function logs
   cd functions && npm run logs
   ```

3. **Expected behavior:**
   - Function logs show: "Sent notification to X tokens. Success: Y"
   - App shows notification in system tray (if in background)
   - App shows local notification (if in foreground)

## Common Issues and Solutions

### Issue 1: "FCM Token is null"
**Causes:**
- GoogleService-Info.plist missing or invalid (iOS)
- google-services.json missing or invalid (Android)
- Firebase project not configured correctly
- Network connectivity issue

**Solutions:**
- Re-download config files from Firebase Console
- Run `flutter clean && flutter pub get`
- Rebuild the app completely

### Issue 2: "User not authenticated during notification init"
**Cause:** `initNotifications()` called before user is logged in

**Solution:** Already handled in main.dart (line 253), but verify timing:
```dart
// Should only init notifications AFTER user is confirmed logged in
if (user != null) {
  _notificationService.initNotifications();
}
```

### Issue 3: Notifications work on Android but not iOS
**Causes:**
- APNs not configured in Firebase Console (most common!)
- Push Notifications capability not enabled in Xcode
- App not code-signed with proper provisioning profile
- Testing on iOS Simulator (push notifications don't work on simulator!)

**Solutions:**
1. Configure APNs in Firebase Console (see Step 2B above)
2. Enable capabilities in Xcode (see Step 2A above)
3. Test on a real device, not simulator
4. Ensure provisioning profile includes Push Notifications entitlement

### Issue 4: Notifications work in foreground but not background
**Causes:**
- Background modes not enabled (iOS)
- App not handling background notifications

**Solutions:**
- Verify UIBackgroundModes in Info.plist (already fixed)
- Ensure `_firebaseMessagingBackgroundHandler` is registered in main.dart (already done)

### Issue 5: No notifications received at all
**Debug steps:**
1. Check if token is saved: Firestore Console → users/{uid} → fcmTokens
2. Test with Firebase Console test message
3. If Firebase test works → Issue is with Cloud Functions
4. If Firebase test fails → Issue is with device/app configuration

### Issue 6: Notifications work initially, then stop
**Cause:** FCM tokens can become invalid when:
- App is uninstalled/reinstalled
- User clears app data
- Token expires (rare, but can happen)

**Solution:**
- Already handled! The `cleanupInvalidTokens` function removes stale tokens
- App listens to token refresh: `onTokenRefresh.listen(_updateTokenInFirestore)`

## Testing Checklist

Use this checklist to verify everything is working:

- [ ] App requests notification permission on first launch
- [ ] User grants notification permission
- [ ] Log shows: "Initializing notifications for user: <uid>"
- [ ] Log shows: "FCM Token obtained: ..."
- [ ] Log shows: "✓ Successfully saved FCM token to Firestore"
- [ ] Firestore shows fcmTokens array in user document
- [ ] APNs configured in Firebase Console (iOS)
- [ ] Push Notifications capability enabled in Xcode (iOS)
- [ ] Test notification from Firebase Console works
- [ ] Creating a new event triggers notification to group members
- [ ] Tapping notification navigates to correct screen
- [ ] Foreground notifications display as local notifications
- [ ] Background notifications wake the app
- [ ] Notification icon/sound work correctly

## Advanced Debugging

### View Real-Time Function Logs
```bash
# Stream function logs in real-time
firebase functions:log --only notifyOnNewEvent
```

### Test Individual Functions
```bash
# Deploy and test a single function
firebase deploy --only functions:notifyOnNewEvent
```

### Check FCM Token Validity
Use Firebase Console → Cloud Messaging → Send test message with the token from logs.

### Verify Firestore Security Rules
Check that rules allow:
- Users can write to their own `/users/{uid}` document
- Functions can read user documents and fcmTokens

### Enable Verbose FCM Logging (iOS)
Add to Xcode scheme arguments:
```
-FIRDebugEnabled
```

This will show detailed FCM logs in Xcode console.

### Enable Verbose FCM Logging (Android)
```bash
adb shell setprop log.tag.FCM VERBOSE
adb logcat -s FCM
```

## Next Steps After Fixes

1. **Rebuild the app completely:**
   ```bash
   flutter clean
   flutter pub get
   cd ios && pod install && cd ..
   flutter run
   ```

2. **Test on real devices** (iOS simulator doesn't support push notifications)

3. **Grant notification permissions** when prompted

4. **Check logs** for the diagnostic messages added

5. **Create a test event** and verify notifications are sent

6. **Monitor function logs** to see if tokens are found and notifications sent

## Support Resources

- Firebase Cloud Messaging Docs: https://firebase.google.com/docs/cloud-messaging
- Flutter Firebase Messaging Plugin: https://pub.dev/packages/firebase_messaging
- APNs Configuration Guide: https://firebase.google.com/docs/cloud-messaging/ios/certs

## Architecture Notes

GetSpot uses the following notification patterns:

1. **Token Storage:** FCM tokens stored in `/users/{uid}.fcmTokens` array
2. **Token Refresh:** Automatically updates on token refresh via `onTokenRefresh` listener
3. **Invalid Token Cleanup:** `cleanupInvalidTokens` removes stale tokens after send failures
4. **Notification Triggers:**
   - `notifyOnNewEvent`: Firestore trigger when event is created
   - `sendEventReminders`: Scheduled function (hourly) for event reminders 24hrs before
5. **User Preferences:** `notificationsEnabled` flag (defaults to true if not set)

All notification logic is in:
- Client: `lib/services/notification_service.dart`
- Backend: `functions/src/notifyOnNewEvent.ts`, `functions/src/sendEventReminders.ts`
- Shared utilities: `functions/src/cleanupInvalidTokens.ts`
