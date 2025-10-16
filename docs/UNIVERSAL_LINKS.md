# Universal Links / App Links Implementation

This document describes the Universal Links (iOS) and App Links (Android) implementation for GetSpot, allowing users to share group invitations via native deep links.

## Overview

GetSpot uses native Universal Links and App Links to enable seamless group sharing:
- **No third-party dependencies** (no Firebase Dynamic Links)
- **Group code in URL path** - no backend URL shortening needed
- **Works immediately** when app is installed
- **Fallback to web page** when app is not installed

## Deep Link Format

```
https://getspot.app/join/{GROUP_CODE}
```

**Example:** `https://getspot.app/join/ABC-DEF-GHI`

## User Flow

### If App is Installed
1. User taps link → App opens directly to join screen
2. Group code is pre-filled
3. User sees group details and can request to join

### If App is NOT Installed
1. User taps link → Opens web page at `https://getspot.app/join/{CODE}`
2. Web page shows:
   - Group code for manual entry
   - Links to App Store / Play Store
   - Attempts to open app automatically

## Implementation

### Flutter Code

**Packages Used:**
- `share_plus: ^10.1.2` - Native sharing
- `app_links: ^6.3.2` - Deep link handling

**Files Modified:**
- `lib/screens/group_details_screen.dart` - Share button and functionality
- `lib/screens/join_group_screen.dart` - New screen for deep link handling
- `lib/main.dart` - Deep link listener and navigation

### Platform Configuration

#### iOS (Universal Links)

**File:** `ios/Runner/Runner.entitlements`
```xml
<key>com.apple.developer.associated-domains</key>
<array>
  <string>applinks:getspot.app</string>
</array>
```

**Required:** Host `apple-app-site-association` file at:
```
https://getspot.app/.well-known/apple-app-site-association
```

#### Android (App Links)

**File:** `android/app/src/main/AndroidManifest.xml`
```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="https" android:host="getspot.app" android:pathPrefix="/join"/>
</intent-filter>
```

**Required:** Host `assetlinks.json` file at:
```
https://getspot.app/.well-known/assetlinks.json
```

## Important: Flutter Web Deployment

**Your Flutter app IS the website!** Since you're deploying the Flutter web build to `getspot.app`, the app will automatically handle `/join/{code}` routes via `onGenerateRoute` in `main.dart`.

**What this means:**
- ✅ When users visit `https://getspot.app/join/ABC-DEF-GHI` in a browser, they see your Flutter web app with the JoinGroupScreen
- ✅ On mobile devices with the app installed, the link opens the native app directly
- ✅ You DON'T need to upload the `join/index.html` file - the Flutter web app handles it!

**Domain Configuration:**
- The app supports both `getspot.app` and `www.getspot.app`
- Make sure your DNS/hosting redirects www to non-www (or vice versa) for consistency

## Hosting Requirements

### Required Files on getspot.app

You only need to upload 2 files (not 3!) since Flutter web handles the landing page:

#### 1. Apple App Site Association

**Location:** `https://getspot.app/.well-known/apple-app-site-association`

**File:** `docs/hosting/apple-app-site-association` (no extension)

**Content Type:** `application/json`

**To Do:**
- Replace `TEAM_ID` with your Apple Developer Team ID
- Find Team ID at: https://developer.apple.com/account (Membership section)

**Example:**
```json
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "ABC123XYZ.com.getspot.app",
      "paths": ["/join/*", "/join"]
    }]
  }
}
```

#### 2. Android Asset Links

**Location:** `https://getspot.app/.well-known/assetlinks.json`

**File:** `docs/hosting/assetlinks.json`

**Content Type:** `application/json`

**To Do:**
- Replace `REPLACE_WITH_YOUR_RELEASE_SHA256_FINGERPRINT` with your release key fingerprint

**Get SHA256 fingerprint:**
```bash
# From your release keystore
keytool -list -v -keystore /path/to/release.keystore -alias your-key-alias

# Or from Play Console
# Go to: Play Console → Your App → Setup → App Signing
# Copy SHA-256 certificate fingerprint
```

**Example:**
```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.getspot.app",
    "sha256_cert_fingerprints": [
      "14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5"
    ]
  }
}]
```

#### 3. Landing Page - NOT NEEDED!

~~**Location:** `https://getspot.app/join/index.html`~~

**You don't need this!** Your Flutter web app automatically handles `/join/{code}` routes and shows the JoinGroupScreen.

The `docs/hosting/join/index.html` file is provided as reference only, in case you want a separate static landing page in the future.

### Firebase Hosting Configuration

Since you're using Firebase Hosting for your Flutter web app, you need to:

1. **Upload the `.well-known` files** to your hosting directory (probably `/public/.well-known/`)
2. **Configure `firebase.json`** to serve them correctly

**Add to your `firebase.json`:**

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "/.well-known/apple-app-site-association",
        "headers": [
          {
            "key": "Content-Type",
            "value": "application/json"
          },
          {
            "key": "Access-Control-Allow-Origin",
            "value": "*"
          }
        ]
      },
      {
        "source": "/.well-known/assetlinks.json",
        "headers": [
          {
            "key": "Content-Type",
            "value": "application/json"
          },
          {
            "key": "Access-Control-Allow-Origin",
            "value": "*"
          }
        ]
      }
    ]
  }
}
```

**File locations:**
- Copy `docs/hosting/apple-app-site-association` → `build/web/.well-known/apple-app-site-association`
- Copy `docs/hosting/assetlinks.json` → `build/web/.well-known/assetlinks.json`

Then run: `firebase deploy --only hosting`

### Alternative Server Configuration (if not using Firebase)

**Important:** These files must be served with correct MIME types:

```nginx
# Nginx example
location ~ /.well-known/apple-app-site-association {
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
}

location ~ /.well-known/assetlinks.json {
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
}
```

```apache
# Apache example (.htaccess)
<Files "apple-app-site-association">
    ForceType application/json
    Header set Access-Control-Allow-Origin "*"
</Files>

<Files "assetlinks.json">
    ForceType application/json
    Header set Access-Control-Allow-Origin "*"
</Files>
```

## Usage

### Sharing a Group

1. Navigate to any group details screen
2. Tap the share icon in the app bar
3. Select sharing method (Messages, Email, WhatsApp, etc.)
4. URL with group code is automatically included

**Code Location:** `lib/screens/group_details_screen.dart:93-141`

### Handling Deep Links

**Flow:**
1. User taps link: `https://getspot.app/join/ABC-DEF-GHI`
2. `AppLinks` package detects the link
3. `_handleDeepLink()` in `main.dart` processes it
4. Extracts group code from path
5. Navigates to `JoinGroupScreen` with pre-filled code
6. User sees group details and can request to join

**Code Location:** `lib/main.dart:109-169`

## Testing

### Prerequisites
- Physical iOS or Android device (recommended)
- Device must have the app installed
- User must be signed in

### Local Testing (Before Hosting Files)

#### iOS Simulator/Device:
```bash
# Test deep link handling
xcrun simctl openurl booted "https://getspot.app/join/ABC-DEF-GHI"
```

#### Android Emulator/Device:
```bash
# Test deep link handling
adb shell am start -W -a android.intent.action.VIEW \
  -d "https://getspot.app/join/ABC-DEF-GHI" com.getspot.app
```

### Production Testing (After Hosting Files)

1. **Verify Files Are Accessible:**
   ```bash
   curl https://getspot.app/.well-known/apple-app-site-association
   curl https://getspot.app/.well-known/assetlinks.json
   ```

2. **Test iOS Universal Links:**
   - Host files on your server
   - Uninstall and reinstall app (to refresh entitlements)
   - Send yourself a link via Messages or Notes
   - Tap the link - app should open

3. **Test Android App Links:**
   - Host files on your server
   - Uninstall and reinstall app
   - Enable App Links:
     ```bash
     adb shell pm verify-app-links --re-verify com.getspot.app
     ```
   - Check verification status:
     ```bash
     adb shell pm get-app-links com.getspot.app
     ```
   - Send link via Messages or Email
   - Tap link - app should open

4. **Test Share Functionality:**
   - Open app and navigate to a group
   - Tap share icon
   - Share via Messages to yourself
   - Tap the shared link
   - App should open to join screen

### Debug Logging

All deep link operations are logged:
- `GroupDetailsScreen` - Share button taps
- `AuthWrapper` - Deep link reception and handling
- `JoinGroupScreen` - Group lookup and join requests

View logs:
```bash
flutter logs
```

## Troubleshooting

### iOS: Link Opens Safari Instead of App

**Cause:** Universal Links not verified or entitlements not configured

**Solutions:**
1. Verify `apple-app-site-association` is accessible and valid
2. Check that Team ID is correct in the JSON file
3. Uninstall and reinstall the app
4. Test with a fresh device or after device restart
5. Make sure URL is tapped (not pasted into Safari)

**Verify file:**
```bash
curl -I https://getspot.app/.well-known/apple-app-site-association
# Should return: Content-Type: application/json
```

### Android: Link Opens Browser Instead of App

**Cause:** App Links not verified

**Solutions:**
1. Verify `assetlinks.json` is accessible
2. Check SHA-256 fingerprint matches your release key
3. Force re-verification:
   ```bash
   adb shell pm verify-app-links --re-verify com.getspot.app
   ```
4. Check verification status:
   ```bash
   adb shell pm get-app-links com.getspot.app
   # Should show: verified for domain getspot.app
   ```
5. Uninstall and reinstall app

### App Opens But Nothing Happens

**Cause:** Navigation or authentication issue

**Solutions:**
1. Check logs for `_handleDeepLink` output
2. Verify user is signed in
3. Check group code is valid
4. Ensure `JoinGroupScreen` is imported in main.dart

### "Group Not Found" Error

**Cause:** Invalid group code or group deleted

**Solutions:**
1. Verify group code is correct
2. Check that group still exists in Firestore
3. Ensure `groupCodeSearch` field exists on group document
4. Test with a known valid group code

## Advantages Over Firebase Dynamic Links

✅ **No third-party dependency** - completely native
✅ **No deprecation risk** - based on Apple/Google standards
✅ **Simpler implementation** - just static file hosting
✅ **Better performance** - no redirect through Firebase
✅ **Full control** - customize landing page as needed
✅ **No API limits** - unlimited links
✅ **Free** - no costs for link generation

## Future Enhancements

### Deferred Deep Linking
Store group code for users who install app from landing page:
- Use URL parameter or local storage
- Check on first app launch
- Auto-navigate to join screen

### Analytics
Track link performance:
- Log share events (already done)
- Track link clicks (via landing page JavaScript)
- Monitor successful joins

### Custom Short URLs
If you want shorter URLs:
- Set up URL shortener on your domain
- Example: `https://getspot.app/j/ABC` → redirects to `/join/ABC-DEF-GHI`
- Can be implemented with simple server-side redirect

### QR Codes
Generate QR codes for offline sharing:
- Package: `qr_flutter`
- Encode the deep link URL
- Users scan to open join link

## References

- [Apple Universal Links Documentation](https://developer.apple.com/ios/universal-links/)
- [Android App Links Documentation](https://developer.android.com/training/app-links)
- [app_links Package](https://pub.dev/packages/app_links)
- [share_plus Package](https://pub.dev/packages/share_plus)
