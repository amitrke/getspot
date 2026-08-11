# Local Development Guide

Detailed setup instructions for running GetSpot locally. For a quick-reference command list once you're set up, see the root [`README.md`](../README.md#quick-start) Quick Start section or `CLAUDE.md`'s Common Commands.

## Prerequisites

- **Flutter SDK 3.8.1+** — [install instructions](https://flutter.dev/docs/get-started/install)
- **Firebase CLI** — `npm install -g firebase-tools`, then `firebase login`
- **Node.js 22+** — required for Cloud Functions (see `functions/package.json`'s `engines.node`)
- **An IDE** — VS Code (with the Flutter extension) or Android Studio recommended
- For iOS builds: a macOS machine with Xcode

## Setup

1. **Clone and install dependencies:**
   ```bash
   git clone https://github.com/amitrke/getspot.git
   cd getspot
   flutter pub get

   cd functions
   npm install
   cd ..
   ```

2. **Firebase config files:** the app needs platform-specific Firebase config that is **not committed to the repo**:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist` (generated in CI by `ios/ci_scripts/ci_post_clone.sh`; for local iOS builds, download it yourself from Firebase Console → Project Settings → your iOS app)
   - `lib/firebase_options.dart` is committed and points at the `getspot01` Firebase project — no local changes needed unless you're pointing at a different project

   Download the missing files from [Firebase Console](https://console.firebase.google.com/project/getspot01/settings/general) if you don't already have them.

## Running the App

```bash
flutter run              # connected device or emulator
flutter run -d chrome    # web, in Chrome
```

## Running Cloud Functions Locally

```bash
cd functions
npm run serve   # builds TypeScript, then starts the functions emulator
```

This only emulates Functions — there's no configured Firestore/Auth emulator, so functions running locally still read/write the real `getspot01` Firestore. Be mindful of this when testing against live data.

## Building the App

```bash
flutter build apk     # Android APK
flutter build appbundle  # Android App Bundle (for Play Store — see docs/DEPLOYMENT.md)
flutter build ios     # iOS (requires macOS/Xcode)
flutter build web     # Web (output in build/web)
```

For actual release builds to the Play Store / App Store, prefer the automated GitHub Actions workflows described in `docs/DEPLOYMENT.md` rather than building locally.

## Troubleshooting

- **"Firebase project not found" / auth errors on launch:** confirm `google-services.json` / `GoogleService-Info.plist` are present and match the `getspot01` project.
- **Functions won't build:** run `npm run lint` and `npm run build` inside `functions/` — the predeploy hook runs both, so build/lint errors block deploys too.
- See `docs/ENVIRONMENTS.md` for the (currently single-project) environment setup, and `CONTRIBUTING.md` for coding conventions before opening a PR.
