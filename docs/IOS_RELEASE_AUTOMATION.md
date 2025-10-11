# iOS Release Automation Guide

This guide explains how to automate promoting TestFlight builds to App Store production using Fastlane.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Using the Automation](#using-the-automation)
4. [Manual Commands](#manual-commands)
5. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- Xcode Cloud is building and uploading to TestFlight successfully
- Access to App Store Connect with App Manager or Admin role
- Ruby 3.0+ installed (comes with macOS)
- Bundler installed: `gem install bundler`

---

## Initial Setup

### 1. Install Dependencies

```bash
# From the project root directory
bundle install
```

### 2. You Already Have the API Key! ✅

Good news! You already have the App Store Connect API key set up in your GitHub Secrets from your existing iOS deployment workflow:

- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_PRIVATE_KEY`
- `APP_APPLE_ID`

**No additional setup needed for GitHub Actions!**

### 3. (Optional) Local Development Setup

If you want to run Fastlane commands locally, create a `.env` file:

```bash
cp fastlane/.env.default fastlane/.env
```

Then fill in the same values you have in GitHub Secrets:

```env
APP_IDENTIFIER="com.getspot.app"
APP_STORE_CONNECT_API_KEY_ID="YOUR_KEY_ID"
APP_STORE_CONNECT_API_ISSUER_ID="YOUR_ISSUER_ID"
APP_STORE_CONNECT_API_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY\n-----END PRIVATE KEY-----"
APP_APPLE_ID="your-email@example.com"
```

**IMPORTANT:** `.env` is already in `.gitignore` - never commit this file!

---

## Using the Automation

### Option 1: GitHub Actions (Recommended)

1. Go to **Actions** tab in your GitHub repository
2. Select **"Promote to App Store"** workflow
3. Click **"Run workflow"**
4. (Optional) Enter a specific build number, or leave empty for latest
5. Click **"Run workflow"** button

The workflow will:
- ✅ Get the latest (or specified) TestFlight build
- ✅ Submit it for App Store Review
- ✅ Set it to manual release (you control when it goes live)

### Option 2: Local Command Line

#### Promote Latest TestFlight Build

```bash
bundle exec fastlane promote_to_review
```

#### Promote Specific Build Number

```bash
bundle exec fastlane promote_build build_number:123
```

#### Check Version Information

```bash
bundle exec fastlane version_info
```

---

## Manual Commands

### Download App Store Metadata

Useful for updating screenshots, descriptions, etc. locally:

```bash
bundle exec fastlane download_metadata
```

This creates `fastlane/metadata/` with all your App Store content.

### Update Metadata Without Submitting Build

```bash
bundle exec fastlane update_metadata
```

Edit files in `fastlane/metadata/en-US/` then run this command.

### Release Approved Build to Production

After Apple approves your build:

```bash
bundle exec fastlane release
```

This will make the approved build live on the App Store.

---

## Workflow Overview

```
┌─────────────────────┐
│  Xcode Cloud Build  │
│  (Automated)        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  TestFlight         │
│  (Auto-uploaded)    │
└──────────┬──────────┘
           │
           │ Manual or GitHub Action
           ▼
┌─────────────────────┐
│  App Store Review   │
│  (fastlane promote) │
└──────────┬──────────┘
           │
           │ Apple Reviews (2-3 days)
           ▼
┌─────────────────────┐
│  Approved           │
└──────────┬──────────┘
           │
           │ Manual or fastlane release
           ▼
┌─────────────────────┐
│  Live on App Store  │
└─────────────────────┘
```

---

## Troubleshooting

### "Authentication failed"

**Solution:** Regenerate your App Store Connect API key and update the JSON file.

### "Build not found"

**Possible causes:**
- The build is still processing on TestFlight
- Wrong build number specified
- Build was removed from TestFlight

**Solution:** Wait for TestFlight processing to complete (can take 10-30 minutes after upload).

### "Invalid provisioning profile"

**Solution:** This shouldn't happen when using Xcode Cloud builds, but if it does:
1. Ensure Xcode Cloud is using the correct provisioning profile
2. Rebuild in Xcode Cloud

### "Metadata validation failed"

**Solution:**
1. Download metadata: `bundle exec fastlane download_metadata`
2. Review the error message
3. Fix the issue in App Store Connect manually
4. Download metadata again

### "Rate limit exceeded"

**Solution:** Wait 1 hour and try again. Apple limits API calls.

---

## Best Practices

1. **Always test in TestFlight first** - Don't promote a build that hasn't been tested
2. **Use build numbers sequentially** - Makes tracking easier
3. **Document release notes** - Keep track of what's in each build
4. **Set automatic_release: false** - Gives you control over when the app goes live after approval
5. **Monitor App Store Connect** - Check for rejections or issues

---

## Automated Release Schedule Example

You can set up a scheduled release (e.g., every Monday):

1. Test latest build in TestFlight throughout the week
2. Friday EOD: Run `fastlane promote_to_review` for the latest stable build
3. Apple reviews over weekend/early week (2-3 days avg)
4. After approval: Run `fastlane release` or release manually via App Store Connect

---

## Security Notes

- ✅ `fastlane/.env` is in `.gitignore` - never commit this
- ✅ `app_store_connect_api_key.json` is in `.gitignore` - never commit this
- ✅ GitHub Secrets are encrypted and only accessible to workflows
- ✅ API keys can be revoked anytime in App Store Connect

---

## Support

For Fastlane documentation:
- https://docs.fastlane.tools
- https://docs.fastlane.tools/actions/deliver/

For App Store Connect API:
- https://developer.apple.com/documentation/appstoreconnectapi
