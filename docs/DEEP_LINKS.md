# Deep Links: Universal Links (iOS) & App Links (Android)

GetSpot uses native Universal Links (iOS) and App Links (Android) to let users share group invitations via links that open the app directly — no Firebase Dynamic Links, no third-party dependency, no backend URL shortening.

```
https://app.getspot.org/join/{GROUP_CODE}
```

Old `https://www.getspot.org/join/{code}` links (from before the marketing site split off, see `main/` and `docs/hosting/README.md`) still work via a 302 redirect to `app.getspot.org`.

## How it works

**If the app is installed:** tapping the link opens the app directly to the join screen with the group code pre-filled.

**If the app is not installed:** the link opens `https://app.getspot.org/join/{code}` in a browser. Since the Flutter **web build itself is deployed to `app.getspot.org`**, this is just the normal Flutter web app rendering `JoinGroupScreen` via `onGenerateRoute` — there's no separate static landing page to maintain.

## Implementation

**Packages:** `share_plus` (native sharing), `app_links` (deep link handling) — see `pubspec.yaml` for pinned versions.

**Code:**
- `lib/screens/group_details_screen.dart` — share button/action
- `lib/screens/join_group_screen.dart` — handles the join flow when a deep link arrives
- `lib/main.dart` — `onGenerateRoute` (web routing) + `app_links` listener (`_handleDeepLink`)

**iOS** (`ios/Runner/Runner.entitlements`):
```xml
<key>com.apple.developer.associated-domains</key>
<array>
  <string>applinks:app.getspot.org</string>
</array>
```

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="https" android:host="app.getspot.org" android:pathPrefix="/join"/>
</intent-filter>
```

## Hosting config files

Two files must be served at `https://app.getspot.org/.well-known/`, as `application/json` with `Access-Control-Allow-Origin: *` (both requirements, plus "no redirects", configured in `firebase.json`'s `headers` block):

| File | Source | Purpose |
|---|---|---|
| `apple-app-site-association` (no extension) | `docs/hosting/apple-app-site-association` | iOS Universal Links — `appID` must be `{APPLE_TEAM_ID}.org.getspot` |
| `assetlinks.json` | `docs/hosting/assetlinks.json` | Android App Links — `package_name` must be `org.getspot`, plus your release key's SHA-256 fingerprint |

`docs/hosting/join/` contains an unused static landing page kept only as a reference — the Flutter web app makes it unnecessary.

Get the values you need:
- **Apple Team ID:** [developer.apple.com/account](https://developer.apple.com/account) → Membership
- **Android SHA-256 fingerprint:** Play Console → your app → Setup → App Signing → SHA-256 certificate fingerprint (or `keytool -list -v -keystore /path/to/release.keystore -alias your-key-alias`)

## Deployment (automatic via CI)

`.github/workflows/firebase-hosting-merge.yml` copies both files into the build output and deploys on every push to `main` that touches `docs/hosting/**`, `firebase.json`, `lib/**`, `web/**`, or `pubspec.yaml`:

```yaml
- name: Setup deep links for Universal Links / App Links
  run: |
    mkdir -p build/web/.well-known
    cp docs/hosting/apple-app-site-association build/web/.well-known/
    cp docs/hosting/assetlinks.json build/web/.well-known/
```

To update the config: edit `docs/hosting/apple-app-site-association` and/or `docs/hosting/assetlinks.json`, commit, and push to `main` — no other steps needed.

**Local/manual deploy** (for testing before merging):
```bash
./scripts/setup-deep-links.sh   # builds web + copies .well-known files
firebase deploy --only hosting
```

## Verifying a deployment

```bash
# Both should return JSON, not 404/HTML
curl https://app.getspot.org/.well-known/apple-app-site-association
curl https://app.getspot.org/.well-known/assetlinks.json
```

## Testing

**iOS:** uninstall and reinstall the app (refreshes entitlements), then send yourself the link (e.g. via Messages/Notes) and tap it — it should open the app, not Safari. Local simulator test: `xcrun simctl openurl booted "https://app.getspot.org/join/ABC-DEF-GHI"`.

**Android:** uninstall and reinstall, then:
```bash
adb shell pm verify-app-links --re-verify org.getspot
adb shell pm get-app-links org.getspot   # should show "verified" for app.getspot.org
```
Local test: `adb shell am start -W -a android.intent.action.VIEW -d "https://app.getspot.org/join/ABC-DEF-GHI" org.getspot`

**Web fallback:** open the link in a desktop browser — should show the Flutter web app with the join screen.

## Troubleshooting

**iOS opens Safari instead of the app:**
- `curl -I https://app.getspot.org/.well-known/apple-app-site-association` — confirm `Content-Type: application/json` and a 200
- Confirm the Team ID in the JSON is correct
- Uninstall/reinstall the app; verification is cached and only refreshes on install

**Android opens the browser instead of the app:**
- `curl https://app.getspot.org/.well-known/assetlinks.json` — confirm it's reachable
- Confirm the SHA-256 fingerprint matches your release signing key
- `adb shell pm verify-app-links --re-verify org.getspot`, then check `adb shell pm get-app-links org.getspot`

**App opens but nothing happens:** check logs for `_handleDeepLink` output in `main.dart`, confirm the user is signed in, confirm the group code is valid.

**"Group Not Found":** check the group still exists in Firestore and that its `groupCodeSearch` field is set.

**GitHub Actions didn't deploy the files:** Actions tab → latest hosting-deploy run → check the "Setup deep links" step; confirm `docs/hosting/apple-app-site-association` and `docs/hosting/assetlinks.json` exist and are valid JSON/plist.

## Why not Firebase Dynamic Links?

Dynamic Links is deprecated by Google. Native Universal Links / App Links avoid that deprecation risk, need no third-party service, have no link-creation API limits, and add no redirect hop.

## Future enhancements

- Deferred deep linking (persist the group code through an app-store install, then auto-navigate on first launch)
- Extend the same pattern to event sharing (`/event/{eventId}`)
- Link-click analytics beyond the existing share-event logging

## References

- [Apple: Supporting universal links](https://developer.apple.com/ios/universal-links/)
- [Android: App Links](https://developer.android.com/training/app-links)
- [`app_links` package](https://pub.dev/packages/app_links)
- [`share_plus` package](https://pub.dev/packages/share_plus)
