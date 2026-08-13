# Updating Dependencies

## Flutter (`pubspec.yaml`)

```bash
flutter pub outdated              # see what's behind
flutter pub upgrade                # upgrade within existing version constraints
flutter pub upgrade --major-versions   # allow major version bumps (review breaking changes first)
```

Commit the updated `pubspec.lock` along with `pubspec.yaml`.

## Cloud Functions (`functions/package.json`)

Dependencies are managed with pnpm (see `functions/pnpm-lock.yaml`), though `npm install` also works locally.

```bash
cd functions
pnpm outdated          # or: npm outdated
pnpm update             # bump within semver ranges in package.json
pnpm add <pkg>@latest   # bump a specific package to latest major
```

Commit the updated `pnpm-lock.yaml`. After updating, run `npm run lint` and `npm run build` to catch breakage before opening a PR.

## Automated Updates

Dependabot is configured (`.github/dependabot.yml`) to open weekly PRs for the `functions/` npm dependencies. Review and merge these promptly; run `npm run lint && npm run build` locally if the PR touches anything beyond patch versions before merging.

## After Any Dependency Bump

Re-run the app (`flutter run`) or functions emulator (`npm run serve`) locally to sanity-check nothing broke before merging.
