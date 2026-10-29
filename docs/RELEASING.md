# Releasing to testers

`.github/workflows/release.yml` builds the app for both stores and ships it to testers:

- **Android:** a signed App Bundle to the Play Console **Internal testing** track.
- **iOS:** a signed IPA to **TestFlight**.

It replaces Xcode Cloud and the old `deploy-android.yml` / `deploy-ios-manual.yml` workflows. Promotion to production is unchanged: `promote-to-appstore.yml` for iOS, Play Console by hand for Android (see `docs/DEPLOYMENT.md`).

## When it runs

| Trigger | What ships |
|---|---|
| Push to `develop` touching `lib/`, `android/`, `ios/`, `assets/`, `pubspec.*` or the workflow | Both stores |
| Tag push matching the pubspec version (e.g. `1.0.4`) | Both stores |
| **Actions → Release to testers → Run workflow** | Choose `both`, `android` or `ios`, and Play status `completed` or `draft` |

A run first does `flutter analyze` (errors only, `lib` and `test`). Neither store job starts unless it passes. `flutter test` is not run yet because `test/widget_test.dart` is still the `flutter create` counter template.

## Version and build numbers

- **Version name** comes from `pubspec.yaml` (`version: 1.0.4+…`; the `+…` part is ignored). If a git tag with that version already exists, the run fails: bump the version in `pubspec.yaml` first.
- **Build number** is `github.run_number + 100`, the same on both stores for the same run. The offset clears the highest numbers used before this workflow (Play versionCode 39, TestFlight build 50).
- Renaming or recreating `release.yml` resets `github.run_number`. If you do, raise `BUILD_NUMBER_OFFSET` above the highest build either store has seen.

## How iOS signing works

No certificates or provisioning profiles are stored anywhere. Instead:

1. Flutter generates the Xcode configuration (`flutter build ios --config-only`, which also runs `pod install`).
2. `xcodebuild archive` builds an **unsigned** archive.
3. `xcodebuild -exportArchive -allowProvisioningUpdates` with the App Store Connect API key signs it using Apple's **cloud-managed** distribution certificate. `ios/ExportOptions.plist` sets `destination: upload`, so the same command uploads it to TestFlight.

The archive is unsigned on purpose. A signed archive makes Xcode request a new Apple Development certificate on every fresh runner until the account hits its certificate limit.

## Secrets

| Secret | Used for |
|---|---|
| `SIGNING_KEY_BASE64`, `KEYSTOREPASSWORD`, `KEYALIAS`, `KEYPASSWORD` | Android upload keystore (base64) and its alias/passwords |
| `PLAYSTORE_SERVICE_ACCOUNT_JSON` | Play Console upload. If unset, the bundle is built and kept as a workflow artifact but not uploaded |
| `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_ISSUER_ID`, `APP_STORE_CONNECT_API_PRIVATE_KEY` | iOS signing and upload. If the private key is unset, iOS is compiled unsigned and not uploaded |
| `GOOGLE_SERVICE_INFO_PLIST_BASE64` | `ios/Runner/GoogleService-Info.plist`, which is not checked in |

**The App Store Connect API key must have the Admin role.** Cloud-managed signing refuses keys with lower roles (App Manager is not enough). Check it in App Store Connect → Users and Access → Integrations → App Store Connect API.

To set the Firebase plist secret from the file the app is configured for (Firebase iOS app `1:932396176333:ios:d450a81c…`, matching `lib/firebase_options.dart`):

```bash
base64 -w0 path/to/GoogleService-Info.plist | gh secret set GOOGLE_SERVICE_INFO_PLIST_BASE64
```

## Turning a store off

Set a repository variable to skip a store on every run, without editing the workflow:

- `RELEASE_ANDROID` = `false`
- `RELEASE_IOS` = `false`
