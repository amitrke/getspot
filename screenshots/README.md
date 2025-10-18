# GetSpot Screenshot Management

This directory contains screenshots for both testing and app store listings.

## Directory Structure

```
screenshots/
├── store/                           # COMMIT THESE - For App Store/Play Store
│   ├── android/
│   │   ├── phone/                  # Screenshots for Android phones
│   │   ├── tablet-7/               # Screenshots for 7" Android tablets
│   │   └── tablet-10/              # Screenshots for 10" Android tablets
│   └── ios/
│       ├── iphone-6.5/             # Screenshots for iPhone 6.5" (1242x2688)
│       └── ipad-12.9/              # Screenshots for iPad Pro 12.9" (2048x2732)
├── android-phone/                   # DO NOT COMMIT - Maestro test output
├── android-tablet-*/                # DO NOT COMMIT - Maestro test output
├── iphone-*/                        # DO NOT COMMIT - Maestro test output
├── ipad-*/                          # DO NOT COMMIT - Maestro test output
└── default/                         # DO NOT COMMIT - Maestro test output
```

## Generating Store Screenshots

### Step 1: Run Maestro Store Screenshot Test

The dedicated store screenshot test will generate high-quality screenshots for app store listings.

**Prerequisites:**
1. Login as User 1 (admin) with test group set up
2. Ensure test group has:
   - At least 1 upcoming event with participants
   - At least 1 announcement
   - Clean, presentable data (no "test" or dummy data visible)

**Run the test:**

```bash
# For Android Phone screenshots
./run-maestro-test.sh android-phone store_screenshots_test.yaml

# For Android Tablet screenshots
./run-maestro-test.sh android-tablet-10 store_screenshots_test.yaml

# For iPhone screenshots
./run-maestro-test.sh iphone-65 store_screenshots_test.yaml

# For iPad screenshots
./run-maestro-test.sh ipad-13 store_screenshots_test.yaml
```

### Step 2: Organize Screenshots for Stores

Maestro will save screenshots to `screenshots/{device-id}/`. You need to:

1. **Review the screenshots** - Make sure they look professional and show the app's best features
2. **Copy to store directories:**

```bash
# Android Phone
cp screenshots/android-phone/*.png screenshots/store/android/phone/

# Android Tablet
cp screenshots/android-tablet-10/*.png screenshots/store/android/tablet-10/

# iPhone
cp screenshots/iphone-65/*.png screenshots/store/ios/iphone-6.5/

# iPad
cp screenshots/ipad-13/*.png screenshots/store/ios/ipad-12.9/
```

3. **Rename screenshots** following store requirements:
   - Use descriptive names: `01_home_screen.png`, `02_group_events.png`, etc.
   - Keep them numbered for proper ordering in stores

### Step 3: Commit Store Screenshots to Git

```bash
git add screenshots/store/
git commit -m "Update app store screenshots"
git push
```

## Automated Upload to Stores

### Automatic Upload (Recommended)

Once you commit screenshots to the `screenshots/store/` directory, GitHub Actions will automatically upload them to:
- Google Play Store (Android screenshots)
- App Store Connect (iOS screenshots)

**The workflow triggers on:**
- Push to `main` branch with changes in `screenshots/store/**`
- Manual workflow dispatch from GitHub Actions tab

### Manual Upload with Fastlane

If you prefer to upload manually:

**Android:**
```bash
bundle exec fastlane android upload_screenshots
```

**iOS:**
```bash
bundle exec fastlane ios upload_screenshots
```

## Required Secrets for GitHub Actions

Set these secrets in your GitHub repository settings:

**For Android (Play Store):**
- `PLAYSTORE_SERVICE_ACCOUNT_JSON` - Service account JSON key (raw JSON) - **Already configured if you're using deploy-android workflow**
- `ANDROID_PACKAGE_NAME` - Your app's package name (set to `org.getspot`)

**For iOS (App Store Connect):**
- `APP_STORE_CONNECT_API_KEY_ID` - API Key ID
- `APP_STORE_CONNECT_API_ISSUER_ID` - Issuer ID
- `APP_STORE_CONNECT_API_KEY` - API Key content (.p8 file content)
- `APP_IDENTIFIER` - Your app's bundle ID (e.g., `org.getspot`)

### Getting Play Store Credentials

1. Go to [Google Play Console](https://play.google.com/console)
2. Navigate to Settings → API access
3. Create a service account or use existing one
4. Download the JSON key file
5. Copy the entire JSON content to `PLAYSTORE_SERVICE_ACCOUNT_JSON` secret (if not already set)

### Getting App Store Connect Credentials

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Navigate to Users and Access → Keys
3. Create an API key (or use existing)
4. Download the .p8 file
5. Copy the values:
   - Key ID → `APP_STORE_CONNECT_API_KEY_ID`
   - Issuer ID → `APP_STORE_CONNECT_API_ISSUER_ID`
   - .p8 file content → `APP_STORE_CONNECT_API_KEY`

## Screenshot Requirements

### Google Play Store

**Phone:**
- Min: 320px
- Max: 3840px
- JPEG or 24-bit PNG (no alpha)
- Up to 8 screenshots

**7" Tablet:**
- Min: 320px
- Max: 3840px
- Up to 8 screenshots

**10" Tablet:**
- Min: 1080px
- Max: 7680px
- Up to 8 screenshots

### App Store Connect

**iPhone 6.5" Display:**
- Resolution: 1242 x 2688 pixels (portrait)
- Format: PNG or JPEG
- Color space: sRGB or P3
- Up to 10 screenshots

**iPad Pro 12.9" Display:**
- Resolution: 2048 x 2732 pixels (portrait)
- Format: PNG or JPEG
- Up to 10 screenshots

## Tips for Great Store Screenshots

1. **Show core features** - Events, groups, wallet tracking
2. **Use real data** - Not "Test Group" or "Lorem Ipsum"
3. **Consistent styling** - All screenshots should look cohesive
4. **Add captions** - Consider adding text overlays explaining features
5. **First screenshot matters** - Make it eye-catching (80% of users only see the first one)
6. **Localization** - Create screenshots for different languages if needed

## Troubleshooting

**Screenshots not uploading to Play Store:**
- Verify `PLAYSTORE_SERVICE_ACCOUNT_JSON` secret is properly set (should be raw JSON)
- Ensure `ANDROID_PACKAGE_NAME` secret is set to `org.getspot`
- Ensure service account has "Release Manager" role
- Check screenshot dimensions meet requirements

**Screenshots not uploading to App Store:**
- Verify API key has proper permissions
- Ensure screenshots match required dimensions exactly
- Check screenshot naming doesn't conflict with existing ones

**GitHub Actions failing:**
- Check Actions logs for specific error
- Verify all secrets are set correctly
- Ensure `bundle install` succeeds (check Gemfile)

## Manual Testing

Before committing, you can test the upload locally:

```bash
# Install dependencies
bundle install

# Prepare screenshot directories
bundle exec fastlane android prepare_screenshots
bundle exec fastlane ios prepare_screenshots

# Copy your screenshots to the prepared directories

# Test upload (requires credentials)
bundle exec fastlane android upload_screenshots
bundle exec fastlane ios upload_screenshots
```

## Additional Resources

- [Fastlane Screenshots Documentation](https://docs.fastlane.tools/getting-started/ios/screenshots/)
- [Google Play Store Requirements](https://support.google.com/googleplay/android-developer/answer/9866151)
- [App Store Connect Screenshot Specifications](https://help.apple.com/app-store-connect/#/devd274dd925)
