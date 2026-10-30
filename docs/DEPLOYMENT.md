# Deployment Guide

This document outlines the process for deploying the GetSpot application to Web, Android (Google Play Store), and iOS (Apple App Store).

## 1. Web Deployment (Firebase Hosting)

Web deployment is **fully automated** via GitHub Actions.

- **Trigger:** A push or merge to the `main` branch.
- **Workflow File:** `.github/workflows/firebase-hosting-merge.yml`
- **Process:**
    1. The workflow checks out the code.
    2. It sets up Flutter and builds the web application (`flutter build web`).
    3. It deploys the contents of the `build/web` directory to Firebase Hosting (`live` channel).

No manual steps are required for web deployment to production.

### Preview channel (`develop` branch)

- **Trigger:** A push to the `develop` branch (see branching workflow below).
- **Workflow File:** `.github/workflows/firebase-hosting-preview.yml`
- **Process:** Same build as production, but deployed to a persistent Firebase Hosting **preview channel** (`channelId: develop`, target `app` only — the marketing site isn't previewed) instead of `live`. The channel URL is printed in the workflow run output and stays live for 30 days, refreshed on every push to `develop`.
- **Important limitation:** this previews the Flutter web app's static build only. Cloud Functions and Firestore rules/data are **not** isolated — the preview channel still talks to the production `getspot01` backend. It's useful for UI/visual review, not for testing backend-affecting changes (new functions, rule changes, data migrations) against non-production data. For full backend isolation, see the (not-yet-implemented) dual-project strategy in `docs/ENVIRONMENTS.md`.

### Branching workflow

- Feature branches → PR into `develop` → push to `develop` deploys the preview channel above for manual QA.
- Once verified, PR `develop` into `main` → merge triggers the production deploy (web, functions, Firestore rules all go live together on push to `main`).

---

## 2. Android Deployment (Google Play Store)

Building and uploading to Play's Internal testing track is automated, and so is promoting a tested build to Production (`.github/workflows/promote.yml`). See `docs/RELEASING.md`.

### One-time setup (already done for this project)

- Google Play Developer account + app listing created in Play Console.
- An upload keystore was generated (`keytool -genkey ...`) and its contents, alias, and passwords stored as GitHub Actions secrets: `SIGNING_KEY_BASE64`, `KEYALIAS`, `KEYPASSWORD`, `KEYSTOREPASSWORD`.
- A Play Console service account JSON was created and stored as the `PLAYSTORE_SERVICE_ACCOUNT_JSON` secret (used by `r0adkll/upload-google-play`).

### Deploying a build

1. Builds ship automatically from **"Release to testers"** (`.github/workflows/release.yml`) on pushes to `develop` that change the app, on version tags, or by running it via `workflow_dispatch`. See `docs/RELEASING.md`.
2. The workflow decodes the keystore from secrets, builds a signed `.aab` (version name from `pubspec.yaml`, build number `run_number + 100`, shared with iOS), and uploads it to the **Internal testing** track via the Play Developer API.
3. **Promote to Production:** merge `develop` into `main`, then run **"Promote to production"** (`.github/workflows/promote.yml`) from `main` with the tested build number and a rollout percentage, and approve it in the `production` environment. It promotes that build from Internal testing to Production with the listing and release notes from `fastlane/metadata/android`. See `docs/RELEASING.md`.

---

## 3. iOS Deployment (Apple App Store)

Building, signing, and uploading to TestFlight is automated via GitHub Actions (`macos-latest` runners, no local Mac or Xcode Cloud needed). Submitting a tested TestFlight build to App Review is done by the same **"Promote to production"** workflow as Android.

### One-time setup (already done for this project)

- Apple Developer Program account, App ID (`org.getspot`), and app record in App Store Connect.
- An App Store Connect API key stored as secrets: `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_ISSUER_ID`, `APP_STORE_CONNECT_API_PRIVATE_KEY`, plus `APP_APPLE_ID`. The key must have the **Admin** role for cloud-managed signing.
- `GOOGLE_SERVICE_INFO_PLIST_BASE64` secret holding the Firebase iOS config.
- See `docs/RELEASING.md` for signing, secrets and the `production` environment.

### Deploying a build

1. The same **"Release to testers"** workflow (`.github/workflows/release.yml`) builds iOS alongside Android. See `docs/RELEASING.md`.
2. It archives unsigned with `xcodebuild`, then `xcodebuild -exportArchive` signs with Apple's cloud-managed certificate (authorised by the API key) and uploads to TestFlight.
3. **Submit to App Review:** the **"Promote to production"** run above (`platforms: both` or `ios`) sends the same build number to App Review with the listing and release notes from `fastlane/metadata/ios`, set to go live automatically once Apple approves it. See `docs/RELEASING.md`.
