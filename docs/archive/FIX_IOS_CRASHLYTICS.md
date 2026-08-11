# Fix iOS Crashlytics Not Reporting

**Problem:** iOS crashes appear in TestFlight but not in Firebase Crashlytics console.

**Root Cause:** Missing Crashlytics symbol upload script in Xcode build phases.

---

## Quick Fix (3 Options)

### Option 1: Automated Script (Recommended)

**Prerequisites:**
- Ruby with xcodeproj gem installed
- Run from a Mac (won't work on Windows)

```bash
# Install xcodeproj gem if needed
gem install xcodeproj

# Run the script
ruby ios/add_crashlytics_script.rb

# Commit changes
git add ios/Runner.xcodeproj/project.pbxproj
git commit -m "Add Crashlytics symbol upload script for iOS"
git push
```

The script automatically adds the upload phase to your Xcode project. Next Xcode Cloud build will include it.

---

### Option 2: Manual via Xcode (If you have Mac + Xcode)

1. **Open workspace:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Select Runner target:**
   - Click "Runner" project in sidebar
   - Select "Runner" under TARGETS
   - Go to "Build Phases" tab

3. **Add Run Script Phase:**
   - Click `+` → "New Run Script Phase"
   - Drag it after "Run Script" (Flutter build) but before last script
   - Rename to: "Upload Crashlytics Symbols"

4. **Configure the script:**
   - **Shell:** `/bin/sh`
   - **Script:**
     ```bash
     "${PODS_ROOT}/FirebaseCrashlytics/run"
     ```

5. **Add Input Files:**
   - Expand "Input Files" section
   - Add these two paths (click `+` twice):
     ```
     ${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}
     $(SRCROOT)/$(BUILT_PRODUCTS_DIR)/$(INFOPLIST_PATH)
     ```

6. **Save and commit:**
   ```bash
   git add ios/Runner.xcodeproj/project.pbxproj
   git commit -m "Add Crashlytics symbol upload script for iOS"
   git push
   ```

---

### Option 3: Verify CocoaPods Auto-Setup

Sometimes the Firebase Crashlytics pod should add this automatically. Check if it's missing:

```bash
cd ios

# Clean and reinstall pods
rm -rf Pods Podfile.lock
pod install --repo-update

# Check if FirebaseCrashlytics/run exists
ls Pods/FirebaseCrashlytics/run

# If it exists, the manual script should work
```

If `Pods/FirebaseCrashlytics/run` doesn't exist, you have an older version. Update:

```yaml
# In pubspec.yaml, update to latest
firebase_crashlytics: ^5.0.0  # Or latest version
```

Then:
```bash
flutter pub get
cd ios
pod install --repo-update
```

---

## Verification

After adding the script and deploying a new build:

### 1. Check Build Logs (Xcode Cloud)

Look for these log messages during build:
```
▸ Running script 'Upload Crashlytics Symbols'
```

If you see this, the script is running!

### 2. Test Crash Reporting

1. Download new build from TestFlight
2. Open app → Profile → Debug Tools
3. Tap "Test Error" (non-fatal, easier to verify)
4. Keep app open for 30 seconds
5. Close and reopen app
6. Wait 5-10 minutes
7. Check Firebase Console → Crashlytics → iOS

### 3. Test Fatal Crash

1. Tap "Test Crash"
2. App crashes
3. Reopen app (crash report uploads now)
4. Wait 5-10 minutes
5. Check Firebase Console → Crashlytics → iOS

---

## Why This Happens

**Firebase Crashlytics for iOS requires two things:**

1. ✅ **SDK Integration** (you have this - via `firebase_crashlytics` plugin)
   - Catches crashes
   - Stores them locally

2. ❌ **Upload Script** (you're missing this)
   - Uploads crash reports to Firebase
   - Uploads debug symbols (dSYMs) for symbolication
   - Without it: crashes stay on device, TestFlight gets them, Firebase doesn't

**Android doesn't need this** because the Gradle plugin handles it automatically.

---

## Troubleshooting

### "Command not found: xcodeproj"

Install the gem:
```bash
gem install xcodeproj
```

### Script runs but still no crashes in Firebase

1. **Check Firebase Console → Crashlytics:**
   - Is iOS app listed?
   - Is there a "Finish setup" prompt?

2. **Check Info.plist has Crashlytics enabled:**
   ```bash
   # Should NOT have this (it disables auto-init):
   grep -i "FirebaseCrashlyticsCollectionEnabled" ios/Runner/Info.plist
   ```

3. **Force enable in code** (temporary test):
   ```dart
   // In main.dart, after Firebase.initializeApp:
   await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
   ```

4. **Check build configuration:**
   - Script only runs for Release/Profile builds
   - Debug builds might not upload symbols

### Crashes still only in TestFlight

If crashes appear in TestFlight but never in Firebase Crashlytics even after adding script:

1. **Check Network Connectivity:**
   - Firebase requires internet to upload
   - TestFlight works offline (uploads on wifi later)

2. **Check Firebase Project:**
   - Verify iOS bundle ID matches in Firebase Console
   - Verify GoogleService-Info.plist is correct

3. **Check Xcode Cloud Environment Variables:**
   - Ensure `GOOGLE_SERVICE_INFO_PLIST_BASE64` is set correctly
   - The plist might be malformed

---

## Expected Timeline

After fixing:
- **Build:** Next Xcode Cloud build (~10-20 min)
- **TestFlight:** Deploy to TestFlight (~10-30 min processing)
- **Download:** Download new build to device (~5 min)
- **Test:** Crash and reopen app (~1 min)
- **Upload:** Crash uploads to Firebase (~1-5 min)
- **Process:** Firebase processes crash (~5-10 min)
- **Visible:** See crash in Firebase Console

**Total:** ~30-60 minutes from fix to seeing crashes in Firebase

---

## Prevention

To avoid this in future Firebase features:

1. **Always check official setup docs** - Some Firebase features need native setup
2. **Test on both platforms** - Android and iOS often have different requirements
3. **Check Build Phases** - iOS features often need Run Script phases
4. **Monitor both consoles** - TestFlight crashes ≠ Firebase crashes

---

## Additional Resources

- [FlutterFire Crashlytics Docs](https://firebase.flutter.dev/docs/crashlytics/overview)
- [Firebase iOS Setup](https://firebase.google.com/docs/crashlytics/get-started?platform=ios)
- [Xcode Build Phases](https://developer.apple.com/documentation/xcode/customizing-the-build-phases-of-a-target)

---

## Quick Checklist

- [ ] Run `ruby ios/add_crashlytics_script.rb` (Option 1)
  - OR manually add via Xcode (Option 2)
- [ ] Commit changes to `ios/Runner.xcodeproj/project.pbxproj`
- [ ] Push to trigger Xcode Cloud build
- [ ] Wait for TestFlight build
- [ ] Download new build
- [ ] Test "Test Error" button
- [ ] Wait 10 minutes
- [ ] Check Firebase Console → Crashlytics → iOS
- [ ] 🎉 See your first iOS crash report!

---

**Status:** After adding upload script, iOS crashes should appear in Firebase Crashlytics alongside Android crashes.
