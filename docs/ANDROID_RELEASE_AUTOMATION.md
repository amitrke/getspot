# Android Release Automation Guide

This guide explains how to push Google Play Store listing metadata (title, descriptions) using Fastlane, without going through the Play Console UI by hand.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Using the Automation](#using-the-automation)
4. [Manual Commands](#manual-commands)
5. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- Access to Google Play Console for this app
- Ruby 3.0+ and Bundler (`gem install bundler`) for local use

---

## Initial Setup

### 1. Install Dependencies

```bash
# From the project root directory
bundle install
```

### 2. You Likely Already Have the Service Account Key

`deploy-android.yml` (release uploads) already uses a `PLAYSTORE_SERVICE_ACCOUNT_JSON` GitHub secret. `update-android-metadata.yml` reuses the same one — **no new secret is required** unless that service account lacks the right Play Console permission (see below).

### 3. Check the Service Account's Play Console Permission

Uploading a release and editing the store listing are **separate permission grants** on the same service account in Play Console. To confirm (or grant) the one this workflow needs:

1. Play Console → **Users and permissions**
2. Find the service account email used for `PLAYSTORE_SERVICE_ACCOUNT_JSON` (it's the `client_email` field inside that JSON key)
3. Under its **App permissions** for GetSpot, confirm **"Store presence"** is checked (specifically the ability to edit the store listing) — release-related permissions alone aren't enough for `fastlane supply` metadata updates
4. If it's missing, add it and save

If you don't have the JSON key handy to read `client_email` from, it's also visible as a service account in Google Cloud Console → IAM & Admin → Service Accounts, under the project linked to Play Console's API access page (Play Console → Setup → API access).

### 4. (Optional) Local Development Setup

```bash
# Save a local copy of the same service account JSON used in PLAYSTORE_SERVICE_ACCOUNT_JSON.
# Any *.json file directly under android/fastlane/ is gitignored, so it's safe
# to drop it there — but never commit it regardless of where it lives.
export SUPPLY_JSON_KEY_FILE=/path/to/your/play-service-account.json
```

---

## Using the Automation

### Option 1: GitHub Actions (Recommended)

1. Edit files under `android/fastlane/metadata/android/en-US/` (`title.txt`, `short_description.txt`, `full_description.txt`)
2. Go to **Actions → "Update Android Play Store Metadata" → Run workflow**

This only touches store listing text — `skip_upload_apk`, `skip_upload_aab`, `skip_upload_images`, `skip_upload_screenshots`, and `skip_upload_changelogs` are all on, so it's safe to run without a corresponding build or release notes.

Note: the Play Store **Privacy Policy URL** and **contact email** are *not* managed by this workflow — `fastlane supply` doesn't cover those fields. They still need a manual edit in Play Console (**Policy and programs → App content → Privacy policy**, and **Grow users → Store presence → Store settings** respectively).

### Option 2: Local Command Line

```bash
cd android
SUPPLY_JSON_KEY_FILE=/path/to/your/play-service-account.json bundle exec fastlane update_metadata
```

---

## Manual Commands

### Update Metadata Without Submitting a Build

```bash
cd android
SUPPLY_JSON_KEY_FILE=/path/to/key.json bundle exec fastlane update_metadata
```

Edit files in `android/fastlane/metadata/android/en-US/` first, then run this.

---

## Troubleshooting

### "Permission denied" / "The caller does not have permission"

**Solution:** The service account is missing the "Store presence" permission in Play Console → Users and permissions. See [step 3 above](#3-check-the-service-accounts-play-console-permission).

### "Package not found" / invalid package name

**Solution:** Confirm `android/fastlane/Appfile`'s `package_name` matches `applicationId` in `android/app/build.gradle` (currently `org.getspot`).

### Changes don't appear on the Play Store

**Solution:** Play Console can take some time to propagate store listing changes. Also confirm you edited the right locale folder (`en-US`) — Play Console falls back to the default listing language if a locale isn't explicitly translated.

---

## Security Notes

- ✅ Never commit a Play Console service account JSON key to the repository
- ✅ `PLAYSTORE_SERVICE_ACCOUNT_JSON` is a GitHub encrypted secret, only accessible to workflows
- ✅ Service account keys can be rotated/revoked anytime in Google Cloud Console

---

## Support

For Fastlane documentation:
- https://docs.fastlane.tools
- https://docs.fastlane.tools/actions/supply/

For the Google Play Developer API:
- https://developers.google.com/android-publisher
