# Google Play AD_ID Permission Fix

## Issue

When uploading a release to Google Play Console, you may encounter this error:

```
Error: This release includes the com.google.android.gms.permission.AD_ID permission
but your declaration on Play Console says your app doesn't use advertising ID.
You must update your advertising ID declaration.
```

## Cause

Firebase Analytics and other Google Play Services libraries automatically include the `AD_ID` permission in their manifest. This permission allows apps to access the Android Advertising ID for personalized ads.

However, GetSpot does **not** use advertising IDs for ads, so we need to explicitly remove this permission.

## Solution

We've removed the `AD_ID` permission in `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <!-- Remove AD_ID permission since we don't use it for advertising -->
    <uses-permission android:name="com.google.android.gms.permission.AD_ID"
        tools:node="remove" />

    <application ...>
        <!-- rest of manifest -->
    </application>
</manifest>
```

## What This Does

- **Removes** the `AD_ID` permission from the final merged manifest
- Tells Google Play that your app does NOT use advertising IDs
- Prevents the Play Console error when uploading releases

## Google Play Console Declaration

When uploading to Google Play Console, you should declare:

**Data Safety Section → Advertising ID:**
- ❌ "Does your app collect or share advertising ID?"
  - **Answer: NO**

This matches the manifest configuration where we've removed the permission.

## Why We Don't Need AD_ID

GetSpot uses Firebase Analytics for app analytics, but:
- ✅ We use **instance IDs** (automatically created by Firebase)
- ✅ We track **user IDs** (set after sign-in)
- ❌ We do **NOT** use advertising IDs
- ❌ We do **NOT** show ads
- ❌ We do **NOT** use personalized advertising

## Alternative Approach

If you DO want to use advertising IDs in the future, you would:

1. **Keep the permission** (remove the `tools:node="remove"` line)
2. **Update Play Console declaration**:
   - "Does your app collect or share advertising ID?" → **YES**
   - Explain usage: "Used for analytics"
3. **Add Privacy Policy** explaining AD_ID usage

But for GetSpot, we don't need this, so we've removed it.

## Verification

After building a release APK/AAB, you can verify the permission is removed:

```bash
# Build release
flutter build appbundle --release

# Check permissions (requires Android SDK tools)
aapt dump permissions build/app/outputs/bundle/release/app-release.aab
```

You should **NOT** see `com.google.android.gms.permission.AD_ID` in the output.

## Resources

- [Android Advertising ID Documentation](https://developer.android.com/training/articles/ad-id)
- [Google Play Data Safety](https://support.google.com/googleplay/android-developer/answer/10787469)
- [Firebase Analytics and AD_ID](https://firebase.google.com/support/privacy/manage-iids)
