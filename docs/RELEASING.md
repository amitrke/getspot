# Releasing

Two workflows ship the mobile apps. Both are adapted from `amitrke/voice-notes`.

- `.github/workflows/release.yml` (**Release to testers**) builds the app for both stores and ships it to testers:
  - **Android:** a signed App Bundle to the Play Console **Internal testing** track.
  - **iOS:** a signed IPA to **TestFlight**.
- `.github/workflows/promote.yml` (**Promote to production**) sends a tested build to production on both stores (see "To release").

They replace Xcode Cloud, the old `deploy-android.yml` / `deploy-ios-manual.yml` / `promote-to-appstore.yml` workflows and the `update-*-metadata.yml` listing workflows. Web, Cloud Functions and Firestore rules deploy separately, on merge to `main` (see `docs/DEPLOYMENT.md`).

## When test builds run

| Trigger | What ships |
|---|---|
| Push to `develop` touching `lib/`, `android/`, `ios/`, `assets/`, `pubspec.*` or the workflow | Both stores |
| Push of a tag `vX.Y.Z` matching the pubspec version | Both stores. Releases no longer need this (see "To release") |
| **Actions → Release to testers → Run workflow** | Choose `both`, `android` or `ios`, and Play status `completed` or `draft` |

A run first does `flutter analyze` (errors only, `lib` and `test`). Neither store job starts unless it passes. `flutter test` is not run yet because `test/widget_test.dart` is still the `flutter create` counter template.

## Version and build numbers

- **Version name** comes from `pubspec.yaml` (`version: 1.0.4+…`; the `+…` part is ignored). Bump it straight after a release.
- Once a version's tag `vX.Y.Z` exists, test builds of that version stop with an error telling you to bump pubspec. A tag must match pubspec: `v1.0.5` on a commit whose pubspec says `1.0.4` fails.
- **Build number** is `github.run_number + 100`, the same on both stores for the same run. The offset clears the highest numbers used before this workflow (Play versionCode 39, TestFlight build 50).
- Renaming or recreating `release.yml` resets `github.run_number`. If you do, raise `BUILD_NUMBER_OFFSET` above the highest build either store has seen.
- Releases up to 1.0.3 were tagged with the bare version (`1.0.3`). From 1.0.4 on, `promote.yml` tags `v1.0.4`.

## To release

Production gets the build testers already have; nothing is rebuilt.

1. Note the build number testers approved: the number in brackets in TestFlight and Play Console, e.g. `103` in `1.0.4 (103)`. It is the same on both stores.
2. Update the release notes, in each locale (`en-US`, `de-DE`, `es-ES`, `fr-FR`):
   - Play: `fastlane/metadata/android/<locale>/changelogs/default.txt` (500 characters at most).
   - App Store: `fastlane/metadata/ios/<locale>/release_notes.txt`.

   Change any listing text that is out of date too.
3. Merge `develop` into `main`. This also deploys web, functions and rules.
4. Run **Promote to production** from `main` with action `release` and that build number, then approve it in the `production` environment. It:
   - moves the build from Play internal testing to production, at the `rollout` percentage (100 is everyone), and uploads the Play listing and release notes;
   - sends the TestFlight build to App Review with the App Store listing and release notes, set to go live automatically once Apple approves it;
   - tags the commit `vX.Y.Z` once every store it covered has succeeded.
5. Bump `pubspec.yaml` on `develop`.

Do not push the tag yourself. A pushed tag makes `release.yml` upload a new test build, which replaces the tested one on Play's internal track, and the promotion then cannot find it. The workflow's own tag does not start `release.yml`.

To widen a staged Play rollout, run the workflow again (`release`, same build, `android`) with a higher `rollout`. If one store fails, fix it and run again for that store only: the tag waits until both have succeeded, and a re-run accepts its own tag.

## Store listings

The listing text for both stores lives in `fastlane/metadata`, one file per field, with `android/` (Play) and `ios/` (App Store). Screenshots are uploaded separately by `update-store-screenshots.yml`. Edit the files in a pull request like any other change.

- `release` uploads the listings with each release.
- `listing` uploads them alone. On Play they go live once Google accepts them. On the App Store most fields can change only on a version being prepared, so `listing` creates or updates the version in pubspec without submitting it; promotional text, description, URLs and release notes can also change on the live version.
- `check` downloads the live listings and prints how they differ from the repository (in the run's summary), except App Review details, which it lists by file name only. It changes nothing, but it still needs the store keys, so it waits for approval like the other actions. Run it before the first `release` or `listing`, and whenever someone may have edited a listing in a console, since an upload overwrites the console's text.

App Review details (the reviewer sign-in and contact) are not in the repository, so App Store Connect keeps the ones already there. The repository and its Actions logs are public: never add them here.

Not managed by these lanes: the Play **privacy policy URL** (Policy and programs → App content) and **contact email** (Store presence → Store settings). Edit those in Play Console.

## How iOS signing works

No certificates or provisioning profiles are stored anywhere. Instead:

1. Flutter generates the Xcode configuration (`flutter build ios --config-only`, which also runs `pod install`).
2. `xcodebuild archive` builds an **unsigned** archive.
3. `xcodebuild -exportArchive -allowProvisioningUpdates` with the App Store Connect API key signs it using Apple's **cloud-managed** distribution certificate. `ios/ExportOptions.plist` sets `destination: upload`, so the same command uploads it to TestFlight.

The archive is unsigned on purpose. A signed archive makes Xcode request a new Apple Development certificate on every fresh runner until the account hits its certificate limit.

Export compliance is answered by `ITSAppUsesNonExemptEncryption = false` in `ios/Runner/Info.plist`, so TestFlight builds need no manual compliance step.

## Secrets

| Secret | Used for |
|---|---|
| `SIGNING_KEY_BASE64`, `KEYSTOREPASSWORD`, `KEYALIAS`, `KEYPASSWORD` | Android upload keystore (base64) and its alias/passwords |
| `PLAYSTORE_SERVICE_ACCOUNT_JSON` | Play Console upload, promotion and listing. If unset, test bundles are built and kept as a workflow artifact but not uploaded |
| `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_ISSUER_ID`, `APP_STORE_CONNECT_API_PRIVATE_KEY` | iOS signing, upload, App Review submission and listing. If the private key is unset, iOS is compiled unsigned and not uploaded |
| `GOOGLE_SERVICE_INFO_PLIST_BASE64` | `ios/Runner/GoogleService-Info.plist`, which is not checked in |

**The App Store Connect API key must have the Admin role.** Cloud-managed signing refuses keys with lower roles (App Manager is not enough). Check it in App Store Connect → Users and Access → Integrations → App Store Connect API.

**The Play service account needs production and listing permissions**, not only testing. In Play Console → Users and permissions, the account in `PLAYSTORE_SERVICE_ACCOUNT_JSON` (its `client_email`) needs, for GetSpot or account-wide: "Release to production, exclude devices, and use Play App Signing", "Release apps to testing tracks", "Manage testing tracks and edit tester lists" and "Manage store presence".

To set the Firebase plist secret from the file the app is configured for (Firebase iOS app `1:932396176333:ios:d450a81c…`, matching `lib/firebase_options.dart`):

```bash
base64 -w0 path/to/GoogleService-Info.plist | gh secret set GOOGLE_SERVICE_INFO_PLIST_BASE64
```

## Production: the environment

`promote.yml` runs every store job in a GitHub environment named `production`. Create it under Settings → Environments, add yourself as a required reviewer (leave "Prevent self-review" off, since you start the runs too), and limit it to the `main` branch, so nothing reaches production without your approval. That limit is why every action, `check` included, runs from `main` only.

## Turning a store off

Set a repository variable to skip a store on every test-build run, without editing the workflow:

- `RELEASE_ANDROID` = `false`
- `RELEASE_IOS` = `false`

A manual run of either workflow can also narrow one run with its `platforms` input.

## Running a lane locally

With Ruby and Bundler: `bundle install`, then for example `bundle exec fastlane lanes`. The promote and listing lanes read their keys from `PLAY_JSON_KEY_PATH`, `ASC_KEY_ID`, `ASC_ISSUER_ID` and `ASC_KEY_PATH`.

## Notes

- A green iOS job means Apple accepted the upload. The build then spends 10 to 30 minutes processing before TestFlight offers it; a rejection at that stage arrives by email.
- Re-running a failed run reuses its build number, so a run that got as far as uploading cannot just be re-run.
