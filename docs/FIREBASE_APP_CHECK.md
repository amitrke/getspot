# Firebase App Check Setup

This document explains Firebase App Check implementation in GetSpot and how to configure it for development and production.

**Last Updated:** 2025-01-18

---

## What is Firebase App Check?

Firebase App Check protects your backend resources (Cloud Functions, Firestore, Storage) from abuse by:
- ✅ Verifying requests come from your legitimate app
- ✅ Preventing bots and unauthorized clients from accessing your backend
- ✅ Rate limiting and blocking malicious traffic
- ✅ Essential security layer before scaling

**Status:** ✅ **IMPLEMENTED** (Client-side only, backend enforcement optional)

---

## Implementation Overview

### Client-Side (Flutter App)

**File:** `lib/main.dart:56-74`

**Providers:**
- **iOS Production:** DeviceCheck (built-in, no configuration needed)
- **iOS Debug:** Debug provider (for development/testing)
- **Android Production:** Play Integrity API (requires Play Console setup)
- **Android Debug:** Debug provider (for development/testing)
- **Web:** ReCAPTCHA v3 (site key: `6LcNYKYqAAAAADQGaWv-f3W8kVxaFT84HMO9JfSX`)

**How it works:**
```dart
await FirebaseAppCheck.instance.activate(
  androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
  appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
  webProvider: ReCaptchaV3Provider('YOUR_RECAPTCHA_SITE_KEY'),
);
```

- In **debug mode**: Uses debug provider (requires debug token registration)
- In **release mode**: Uses production attestation providers

---

## Firebase Console Setup

### 1. Enable App Check

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **getspot01**
3. Navigate to **App Check** (under Build section)
4. Click **Get Started**

### 2. Register Apps

#### iOS App
1. Click on your iOS app bundle ID: `org.getspot`
2. Provider: **DeviceCheck**
3. Click **Save**

#### Android App
1. Click on your Android package: `org.getspot`
2. Provider: **Play Integrity**
3. Click **Save**

#### Web App
1. Click on your web app
2. Provider: **reCAPTCHA v3**
3. Get reCAPTCHA site key from [Google reCAPTCHA Admin](https://www.google.com/recaptcha/admin)
4. Enter site key in Flutter code (already done: `6LcNYKYqAAAAADQGaWv-f3W8kVxaFT84HMO9JfSX`)
5. Click **Save**

---

## Development Setup (Debug Tokens)

### Why Debug Tokens?

In debug mode, the debug provider is used. You must register debug tokens in Firebase Console to allow your development builds to pass App Check.

### iOS Debug Token

**Get the token:**
1. Run your debug build on iOS simulator or device
2. Check the logs for a message like:
   ```
   [Firebase/AppCheck][I-FAC001001] Firebase App Check Debug Token:
   XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
   ```
3. Copy the token

**Register in Firebase Console:**
1. Go to Firebase Console → App Check
2. Click **Apps** tab
3. Find your iOS app → Click **Manage debug tokens**
4. Click **Add debug token**
5. Paste the token
6. Give it a name (e.g., "Amit's MacBook Simulator")
7. Click **Save**

**Alternative (Manual):**
Set a custom debug token before activation:
```dart
// In main.dart (for testing only!)
if (kDebugMode) {
  await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(false);
  // Use a custom token you've registered in Firebase Console
}
```

### Android Debug Token

**Get the token:**
1. Run your debug build on Android emulator or device
2. Check Logcat for:
   ```
   D/FirebaseAppCheck: Firebase App Check debug token:
   XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
   ```
3. Copy the token

**Register in Firebase Console:**
1. Go to Firebase Console → App Check
2. Click **Apps** tab
3. Find your Android app → Click **Manage debug tokens**
4. Click **Add debug token**
5. Paste the token
6. Give it a name (e.g., "Amit's Pixel Emulator")
7. Click **Save**

### Web Debug Token

Web uses ReCAPTCHA v3 in all environments, no debug token needed.

---

## Testing App Check

### Verify Client-Side Integration

**Run the app in debug mode:**
```bash
flutter run
```

**Check logs for:**
```
[AppCheck] App Check activated - Provider: Debug
```

**Test API call:**
Make any Firestore query or Cloud Function call. It should work normally.

### Test Without Valid Token

1. Remove all registered debug tokens from Firebase Console
2. Run debug build
3. API calls should still work (App Check not enforced yet)

### Enable Enforcement (Optional)

**Cloud Functions Enforcement:**
See section below on updating functions.

**Firestore Enforcement:**
1. Go to Firebase Console → Firestore → Rules
2. Enable App Check requirement (optional - may break existing clients)

---

## Production Deployment

### iOS (DeviceCheck)

**No additional setup required!**
- DeviceCheck is built into iOS
- Automatically works in production builds
- No API keys or configuration needed

### Android (Play Integrity API)

**Setup (One-time):**
1. Ensure app is uploaded to Google Play Console
2. Go to Play Console → Your App → Release → Setup → App Integrity
3. Play Integrity API is automatically enabled for apps on Play Store
4. Link your Firebase project (should already be linked)

**Verify:**
- Build release APK: `flutter build apk --release`
- Install on device
- App Check should work automatically

### Web (ReCAPTCHA v3)

**Already configured** with site key: `6LcNYKYqAAAAADQGaWv-f3W8kVxaFT84HMO9JfSX`

**To update reCAPTCHA key:**
1. Go to [Google reCAPTCHA Admin](https://www.google.com/recaptcha/admin)
2. Register `getspot.org` and `www.getspot.org`
3. Copy the site key
4. Update in `lib/main.dart:68`

---

## Cloud Functions Enforcement (Optional)

### Why Enforce?

Without enforcement, App Check runs in "metrics only" mode:
- ✅ Tracks which requests have valid tokens
- ❌ Does NOT block requests without tokens

**With enforcement:**
- ✅ Blocks all requests without valid App Check tokens
- ✅ Critical for production security

### How to Enforce

**Option 1: Enforce All Functions (Recommended)**

Edit `functions/src/index.ts`:

```typescript
import * as functions from 'firebase-functions/v2';

// Configure App Check enforcement globally
const appCheckOptions = {
  consumeAppCheckToken: true, // Require App Check token
};

// Example: Enforce on callable function
export const createGroup = functions.https.onCall(
  { ...appCheckOptions }, // Add enforcement
  async (request) => {
    // Your function code
  }
);

// Example: Enforce on Firestore trigger
export const processEventRegistration = functions.firestore
  .onDocumentCreated(
    { ...appCheckOptions }, // Add enforcement
    async (event) => {
      // Your function code
    }
  );
```

**Option 2: Enforce Specific Functions**

Only add enforcement to security-critical functions:
- `createGroup`
- `manageJoinRequest`
- `cancelEvent`
- Payment-related functions (when implemented)

**Deployment:**
```bash
cd functions
npm run build
npm run deploy
```

---

## Monitoring App Check

### Firebase Console Metrics

**View App Check metrics:**
1. Go to Firebase Console → App Check
2. Click **Metrics** tab
3. See:
   - Requests with valid tokens
   - Requests with invalid tokens
   - Enforcement violations

### Common Metrics

- **Valid Token Rate:** Should be 95%+ in production
- **Invalid Token Rate:** Low is good (<5%)
- **Debug Token Usage:** Should only be in development

### Alerts

Set up alerts for:
- Spike in invalid tokens (possible attack)
- Drop in valid tokens (configuration issue)

---

## Troubleshooting

### "App Check token is invalid" Error

**Debug Mode:**
1. Check that debug token is registered in Firebase Console
2. Verify the token matches what's in logs
3. Token may expire - re-register if needed

**Production:**
1. iOS: Ensure DeviceCheck is enabled (should be automatic)
2. Android: Verify Play Integrity is configured
3. Web: Check ReCAPTCHA site key is correct

### "Failed to get App Check token"

**Cause:** Provider not configured correctly

**Solutions:**
- iOS: Check app is registered in Firebase Console with DeviceCheck
- Android: Verify package name matches and Play Integrity is enabled
- Web: Verify reCAPTCHA site key is valid

### Functions Blocked After Enforcement

**Cause:** Client not sending valid App Check tokens

**Solutions:**
1. Verify App Check is initialized in client (`main.dart`)
2. Check Firebase Console that apps are registered
3. For debug: Ensure debug tokens are registered
4. For prod: Verify production providers are working

### High Invalid Token Rate

**Possible causes:**
- Older app versions without App Check
- Users on modified/rooted devices
- Legitimate users hitting rate limits

**Solutions:**
1. Don't enforce immediately - monitor metrics first
2. Gradual rollout of enforcement
3. Consider allowing some percentage of unverified requests

---

## Migration Strategy

### Phase 1: Metrics Only (CURRENT)
✅ App Check enabled on client
❌ NOT enforced on backend
- Monitor metrics
- Identify issues
- No user impact

### Phase 2: Soft Enforcement (Recommended Next)
✅ Enforce on NEW functions only
❌ NOT enforced on critical existing functions
- Test enforcement on low-risk functions
- Monitor for issues
- Minimal user impact

### Phase 3: Full Enforcement (Future)
✅ Enforce on ALL functions
✅ Block requests without valid tokens
- After metrics show >95% valid token rate
- After testing in production for 2+ weeks
- Communicate with users about app updates

---

## Security Best Practices

### Do's ✅
- ✅ Always register debug tokens for development
- ✅ Monitor metrics before enforcing
- ✅ Use production providers in release builds
- ✅ Rotate debug tokens periodically
- ✅ Enforce on security-critical functions first

### Don'ts ❌
- ❌ Don't commit debug tokens to source control
- ❌ Don't enforce immediately in production
- ❌ Don't use debug provider in release builds
- ❌ Don't ignore spikes in invalid tokens
- ❌ Don't share debug tokens publicly

---

## Cost & Limits

**Free Tier:**
- 10,000 verifications per month per app
- Generous for small to medium apps

**Paid (Blaze Plan):**
- $0.01 per 1,000 verifications after free tier
- Very affordable even at scale

**GetSpot Estimate:**
- ~1,000 MAU = ~30,000 verifications/month
- Cost: **$0.20/month** (after free tier)

---

## Next Steps

### Immediate (Already Done)
- [x] Add firebase_app_check dependency
- [x] Initialize App Check in Flutter app
- [x] Configure platform-specific providers
- [x] Document setup process

### Short-Term (This Week)
- [ ] Register your development debug tokens
- [ ] Test App Check in debug mode
- [ ] Monitor metrics in Firebase Console
- [ ] Verify all platforms work correctly

### Medium-Term (Next Sprint)
- [ ] Add App Check enforcement to Cloud Functions
- [ ] Test enforcement on staging environment
- [ ] Monitor invalid token rate
- [ ] Document any platform-specific issues

### Long-Term (Production)
- [ ] Enforce on all production functions
- [ ] Set up monitoring alerts
- [ ] Periodic security audits
- [ ] Update documentation with learnings

---

## Resources

- [Firebase App Check Documentation](https://firebase.google.com/docs/app-check)
- [FlutterFire App Check](https://firebase.flutter.dev/docs/app-check/overview)
- [Play Integrity API](https://developer.android.com/google/play/integrity)
- [Apple DeviceCheck](https://developer.apple.com/documentation/devicecheck)
- [reCAPTCHA v3](https://developers.google.com/recaptcha/docs/v3)

---

## Support

**Issues?** Check:
1. This documentation
2. Firebase Console → App Check → Metrics
3. App logs (search for "AppCheck")
4. [FlutterFire GitHub Issues](https://github.com/firebase/flutterfire/issues)

**Questions?** See `CLAUDE.md` for overall architecture context.
