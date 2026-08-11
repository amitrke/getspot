# Hosting Files for Universal Links / App Links

Configuration files for deep linking, served at `https://app.getspot.org/.well-known/`. See **`docs/DEEP_LINKS.md`** for the full setup, deployment, testing, and troubleshooting guide — this README just describes what's in this directory.

## Files

- **`apple-app-site-association`** (no file extension) — iOS Universal Links config. Must be hosted at `/.well-known/apple-app-site-association`.
- **`assetlinks.json`** — Android App Links config. Must be hosted at `/.well-known/assetlinks.json`.
- **`join/`** — unused static landing page, kept only as a reference. The Flutter web app (deployed to the same domain) handles `/join/{code}` directly via `onGenerateRoute`, so this isn't needed in normal operation.

## Deployment

These files are copied into `build/web/.well-known/` and deployed automatically by `.github/workflows/firebase-hosting-merge.yml` on every push to `main`. To update them: edit the file here, commit, and push — see `docs/DEEP_LINKS.md` for manual/local deploy steps.

## Notes

- Both files must be served with `Content-Type: application/json` and `Access-Control-Allow-Origin: *`, with no redirects (configured in `firebase.json`'s `headers` block).
- The Android `package_name` and the iOS `appID` suffix must both be `org.getspot` (the app's real bundle/application ID).
