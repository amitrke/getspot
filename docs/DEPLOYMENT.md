# Deployment Guide

This document outlines the process for deploying the GetSpot application to Web, Android (Google Play Store), and iOS (Apple App Store).

## 1. Web Deployment (Firebase Hosting)

Web deployment is **fully automated** via GitHub Actions.

- **Trigger:** A push or merge to the `main` branch.
- **Workflow File:** `.github/workflows/firebase-hosting-merge.yml`
- **Process:**
    1. The workflow checks out the code.
    2. It sets up Flutter and builds the web application (`flutter build web`).
    3. It deploys the contents of the `build/web` directory to Firebase Hosting.
No PR preview deployment is currently configured — only merges to `main` trigger a deploy.

No manual steps are required for web deployment.

---

## 2. Android Deployment (Google Play Store)

Building and uploading to Play is automated via a GitHub Actions workflow you trigger manually. Promoting between Play tracks (Internal → Production) is still a manual step in the Play Console.

### One-time setup (already done for this project)

- Google Play Developer account + app listing created in Play Console.
- An upload keystore was generated (`keytool -genkey ...`) and its contents, alias, and passwords stored as GitHub Actions secrets: `SIGNING_KEY_BASE64`, `KEYALIAS`, `KEYPASSWORD`, `KEYSTOREPASSWORD`.
- A Play Console service account JSON was created and stored as the `PLAYSTORE_SERVICE_ACCOUNT_JSON` secret (used by `r0adkll/upload-google-play`).

### Deploying a build

1. Go to **GitHub → Actions → "Deploy Android to Google Play"** (`.github/workflows/deploy-android.yml`) and run it via `workflow_dispatch`.
2. The workflow: decodes the keystore from secrets, writes `android/key.properties`, sets the build number to the GitHub Actions run number (version *name* comes from `pubspec.yaml`, only the build number is auto-incremented), runs `flutter build appbundle`, and uploads the `.aab` to the **Internal testing** track via the Play Developer API.
3. **Promote to Production:** still manual — open the Play Console, move the build from Internal testing to the desired track, and roll it out.

---

## 3. iOS Deployment (Apple App Store)

Building, signing, and uploading to TestFlight is automated via GitHub Actions (runs on `macos-14`/`macos-latest` runners, no local Mac needed for routine releases). Promoting a TestFlight build to App Store review is a second, separate automated workflow.

### One-time setup (already done for this project)

- Apple Developer Program account, App ID (`org.getspot`), and app record in App Store Connect.
- An App Store Connect API key stored as secrets: `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_ISSUER_ID`, `APP_STORE_CONNECT_API_PRIVATE_KEY`, plus `APP_APPLE_ID`.
- See `docs/IOS_RELEASE_AUTOMATION.md` / `docs/IOS_RELEASE_QUICKSTART.md` for the full one-time Fastlane/signing setup.

### Deploying a build

1. Go to **GitHub → Actions → "Manual iOS TestFlight Deployment"** (`.github/workflows/deploy-ios-manual.yml`), run via `workflow_dispatch`, and supply the base version (e.g. `1.0.3`) — the build number is set to the GitHub Actions run number.
2. The workflow builds an unsigned IPA (`flutter build ipa --no-codesign`) and uploads it to TestFlight via Fastlane (`pilot upload`).
3. **Promote to App Store review:** run **"Promote to App Store"** (`.github/workflows/promote-to-appstore.yml`) via `workflow_dispatch`, optionally specifying a build number (defaults to latest). This runs `fastlane promote_to_review`/`promote_build` to move the TestFlight build to App Store review — no local Xcode step needed.

> **Known issue:** `promote-to-appstore.yml` currently hardcodes `APP_IDENTIFIER=com.getspot.app` in its generated `.env`, but the app's real bundle ID is `org.getspot`. This looks like the same stale-identifier issue found elsewhere in the docs, but it's in a live workflow file — worth verifying/fixing separately before relying on this workflow.
