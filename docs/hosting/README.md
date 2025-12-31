# Hosting Files for Universal Links / App Links

This directory contains configuration files needed for deep linking to work.

## Files in This Directory

### 1. `apple-app-site-association` (iOS)
**Must be hosted at:** `https://getspot.org/.well-known/apple-app-site-association`

**Before deploying:**
- Replace `TEAM_ID` with your Apple Developer Team ID
- Find at: https://developer.apple.com/account → Membership

### 2. `assetlinks.json` (Android)
**Must be hosted at:** `https://getspot.org/.well-known/assetlinks.json`

**Before deploying:**
- Replace `REPLACE_WITH_YOUR_RELEASE_SHA256_FINGERPRINT` with your release key fingerprint
- Get from: Play Console → App Signing → SHA-256 certificate fingerprint

### 3. `join/index.html` (Optional - Not Used)
**This file is NOT needed** because your Flutter web app handles the `/join/{code}` route automatically.

It's kept here as a reference in case you want a separate static landing page in the future.

## Deployment

### Automatic (Recommended)

Use the setup script:
```bash
./scripts/setup-deep-links.sh
```

This will:
1. Build the Flutter web app
2. Copy the `.well-known` files to `build/web/.well-known/`
3. Show you the next steps

### Manual

```bash
# Build web app
flutter build web

# Create directory
mkdir -p build/web/.well-known

# Copy files
cp docs/hosting/apple-app-site-association build/web/.well-known/
cp docs/hosting/assetlinks.json build/web/.well-known/

# Deploy to Firebase
firebase deploy --only hosting
```

## Verification

After deployment, verify files are accessible:

```bash
# iOS configuration
curl https://getspot.org/.well-known/apple-app-site-association

# Android configuration
curl https://getspot.org/.well-known/assetlinks.json
```

Both should return JSON (not 404 or HTML).

## Domain Support

The app supports both:
- `https://getspot.org`
- `https://www.getspot.org`

Make sure your DNS/hosting redirects www to non-www (or vice versa) for consistency.

## Important Notes

1. **HTTPS Required**: Deep links only work over HTTPS
2. **No Extension**: `apple-app-site-association` has NO file extension (not .json)
3. **MIME Type**: Must be served with `Content-Type: application/json`
4. **CORS**: Include `Access-Control-Allow-Origin: *` header
5. **No Redirects**: Files must be served directly (no 301/302 redirects)

## Firebase Hosting Configuration

The `firebase.json` file has been updated to:
- Serve `.well-known` files with correct headers
- Rewrite all other routes to `/index.html` (for Flutter web)

The configuration looks like this:

```json
{
  "hosting": {
    "headers": [
      {
        "source": "/.well-known/apple-app-site-association",
        "headers": [
          {"key": "Content-Type", "value": "application/json"},
          {"key": "Access-Control-Allow-Origin", "value": "*"}
        ]
      },
      {
        "source": "/.well-known/assetlinks.json",
        "headers": [
          {"key": "Content-Type", "value": "application/json"},
          {"key": "Access-Control-Allow-Origin", "value": "*"}
        ]
      }
    ]
  }
}
```

## Testing

See `docs/SETUP_DEEP_LINKS.md` for complete testing instructions.

Quick test:
1. Share a group from the app
2. Tap the link on the same device
3. App should open directly to join screen

## Troubleshooting

### iOS: Link Opens Safari Instead of App
- Verify file is accessible: `curl https://getspot.org/.well-known/apple-app-site-association`
- Check Team ID is correct
- Uninstall and reinstall app

### Android: Link Opens Browser Instead of App
- Verify file is accessible: `curl https://getspot.org/.well-known/assetlinks.json`
- Check SHA-256 fingerprint is correct
- Verify App Links: `adb shell pm get-app-links com.getspot.app`

### Web: 404 on .well-known Files
- Run `./scripts/setup-deep-links.sh` again
- Verify files exist in `build/web/.well-known/`
- Check `firebase.json` has headers configuration
- Redeploy: `firebase deploy --only hosting`

## More Information

- Quick Setup: `docs/SETUP_DEEP_LINKS.md`
- Full Documentation: `docs/UNIVERSAL_LINKS.md`
- Apple's Documentation: https://developer.apple.com/ios/universal-links/
- Android's Documentation: https://developer.android.com/training/app-links
