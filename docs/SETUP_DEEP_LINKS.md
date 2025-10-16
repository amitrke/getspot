# Quick Setup Guide: Universal Links / App Links

This guide will get your deep linking working in 5 minutes!

## What This Does

Enables sharing group invitations with links like:
- `https://getspot.app/join/ABC-DEF-GHI`
- `https://www.getspot.app/join/ABC-DEF-GHI`

**Result:**
- 📱 Opens app directly on mobile (if installed)
- 🌐 Shows Flutter web app in browser (if app not installed)
- ✅ Works on both iOS and Android

## Quick Setup (5 Steps)

### 1. Get Your Apple Team ID

1. Go to https://developer.apple.com/account
2. Click "Membership" in the sidebar
3. Copy your **Team ID** (looks like `ABC123XYZ`)

### 2. Get Your Android SHA-256 Fingerprint

**Option A: From Play Console (easiest)**
1. Go to Play Console → Your App → Setup → App Signing
2. Copy the **SHA-256 certificate fingerprint**

**Option B: From your keystore**
```bash
keytool -list -v -keystore /path/to/your/release.keystore -alias your-key-alias
```

### 3. Update Configuration Files

**Edit:** `docs/hosting/apple-app-site-association`
```json
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "YOUR_TEAM_ID.com.getspot.app",  // ← Replace YOUR_TEAM_ID
      "paths": ["/join/*", "/join"]
    }]
  }
}
```

**Edit:** `docs/hosting/assetlinks.json`
```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.getspot.app",
    "sha256_cert_fingerprints": [
      "YOUR_SHA256_FINGERPRINT_HERE"  // ← Replace this
    ]
  }
}]
```

### 4. Build and Deploy

**Using GitHub Actions (Recommended):**

Simply push to main branch - GitHub Actions will automatically:
1. Build the Flutter web app
2. Copy `.well-known` files
3. Deploy to Firebase Hosting

```bash
git add .
git commit -m "Setup deep links for group sharing"
git push origin main
```

**Or manually (for local testing):**

Run the setup script:
```bash
./scripts/setup-deep-links.sh
```

Or do it manually:
```bash
# Build web app
flutter build web

# Copy configuration files
mkdir -p build/web/.well-known
cp docs/hosting/apple-app-site-association build/web/.well-known/
cp docs/hosting/assetlinks.json build/web/.well-known/

# Deploy
firebase deploy --only hosting
```

### 5. Verify Setup

Check that files are accessible:
```bash
# Should return JSON (not 404)
curl https://getspot.app/.well-known/apple-app-site-association
curl https://getspot.app/.well-known/assetlinks.json
```

## Testing

### Test Sharing (App Side)
1. Open app and navigate to any group
2. Tap the share icon (top right)
3. Share via Messages to yourself
4. You'll see:
   ```
   Join our group on GetSpot!

   Group: [Group Name]
   [Description]

   Tap to join: https://getspot.app/join/ABC-DEF-GHI

   Or use code: ABC-DEF-GHI in the GetSpot app
   ```

### Test Deep Link (iOS)
1. Uninstall and reinstall app (to refresh entitlements)
2. Send yourself the link via Messages
3. Tap the link
4. App should open directly to join screen

**If it opens Safari instead:**
- Make sure files are deployed and accessible
- Verify Team ID is correct
- Try on a different device or after restart

### Test Deep Link (Android)
1. Uninstall and reinstall app
2. Verify App Links (optional):
   ```bash
   adb shell pm verify-app-links --re-verify com.getspot.app
   adb shell pm get-app-links com.getspot.app
   ```
3. Send yourself the link
4. Tap link → App should open

**If it opens browser instead:**
- Check SHA-256 fingerprint is correct
- Verify files are accessible
- Wait a few minutes for verification

### Test Web Fallback
1. Open link in desktop browser: `https://getspot.app/join/ABC-DEF-GHI`
2. Should show Flutter web app with join screen
3. Group details should be visible

## What Was Changed

✅ **iOS Configuration:**
- `ios/Runner/Runner.entitlements` - Added both `getspot.app` and `www.getspot.app`

✅ **Android Configuration:**
- `android/app/src/main/AndroidManifest.xml` - Added intent filters for both domains

✅ **Flutter Code:**
- `lib/screens/group_details_screen.dart` - Added share button and functionality
- `lib/screens/join_group_screen.dart` - New screen for handling deep links
- `lib/main.dart` - Added `onGenerateRoute` for web routing and `app_links` listener

✅ **Firebase Hosting:**
- `firebase.json` - Added headers for `.well-known` files

## Troubleshooting

### Link Opens Browser Instead of App

**iOS:**
```bash
# Verify file is accessible and valid JSON
curl -I https://getspot.app/.well-known/apple-app-site-association

# Should show: Content-Type: application/json
```

**Android:**
```bash
# Check App Links verification
adb shell pm get-app-links com.getspot.app

# Should show: verified for getspot.app
```

### "Group Not Found" Error

- Check that the group code is valid
- Ensure group still exists in Firestore
- Verify `groupCodeSearch` field exists on group document

### Web App Not Showing Join Screen

- Check browser console for errors
- Verify route is being handled: Look for log "Handling web route: /join/..."
- Try clearing browser cache

## Advanced: Custom Domain Setup

If you want to use a different domain (e.g., `go.getspot.app`):

1. Update entitlements and manifest with new domain
2. Deploy `.well-known` files to new domain
3. Update share functionality to use new domain
4. Redeploy app and web

## Need Help?

See full documentation: `docs/UNIVERSAL_LINKS.md`

Common issues:
- **www vs non-www**: Make sure DNS redirects one to the other
- **HTTPS required**: Deep links only work with HTTPS
- **Case sensitive**: Group codes are case-insensitive, but URLs are not
- **Caching**: Browsers and OS may cache verification - try incognito/private mode
