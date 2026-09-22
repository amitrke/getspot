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

## Resolving OSV-Scanner Vulnerability Findings

The `.github/workflows/osv-scanner.yml` workflow scans `functions/pnpm-lock.yaml` and
`tests/requirements.txt` on every push to `main`/`develop` and weekly on a schedule, and
fails the job (and reports to the Security tab) when it finds a known vulnerability. Most
findings are in **transitive** dependencies (pulled in by direct deps like `firebase-tools`,
`jest`, `eslint`, or `httpx`) rather than packages listed directly in `package.json` or
`requirements.txt`, so a plain `pnpm update` / re-pinning the direct dependency won't fix them.

### Cloud Functions (npm/pnpm)

```bash
cd functions
pnpm audit               # see current findings
pnpm audit --fix         # writes/updates pnpm.overrides in pnpm-workspace.yaml
pnpm install             # regenerate pnpm-lock.yaml against the new overrides
pnpm audit                # confirm "No known vulnerabilities found"
npm run lint && npm run build && npm test   # sanity check nothing broke
```

`pnpm audit --fix` edits the `overrides` block in `functions/pnpm-workspace.yaml` (that file,
not `package.json`, is where this project's pnpm overrides live — see the comments in that
file for why). It does **not** preserve comments when it rewrites that block, so re-add the
rationale comments for the pre-existing entries (the Cloud Build `minimumReleaseAge` pins)
after running it, before committing.

**Run `npm test`, not just `npm run build`.** `tsc` only checks our own source against the
package's declared `.d.ts` types — it can't catch a dependency's *runtime* shape changing.
Several of these overrides force a package past a major version bump that the thing actually
requiring it (e.g. `firebase-tools`, `firebase-functions-test`) doesn't support:

- `uuid` dropped its CommonJS build entirely at v12 (ESM-only). `gaxios`/`google-auth-library`
  — pulled in transitively by `firebase-admin`, in **production**, not just tests — do
  `require("uuid")` and throw `ERR_REQUIRE_ESM` if the resolver picks anything ≥12. The
  override pins `^11.1.1`, the last line with both the CVE fix and a CJS export, not a bare
  `>=`.
- `stream-json` (`GHSA-528h-pc64-c93x`) and `ts-deepmerge` (`GHSA-87mf-gv2c-c62c`) can't be
  overridden at all: their fixed versions are breaking major bumps, and `firebase-tools` /
  `firebase-functions-test` still require the old major even in their latest release (deep
  `require()` of a path that moved, and a renamed export, respectively). Forcing either one
  breaks `firebase emulators:exec` / the whole test suite outright. These are suppressed via
  `functions/osv-scanner.toml` (`IgnoredVulns`) instead, with the incompatibility documented
  in both that file and the `pnpm-workspace.yaml` overrides comment — check there before
  re-attempting an override for either package, and revisit once the parent package updates
  its own dependency.

The general rule: after any override that crosses a major version, run the full test suite
(`npm test`, which spins up the Firestore emulator), not just lint/build, before trusting the
fix.

### Python tests (`tests/requirements.txt`)

`pip` doesn't pin transitive dependencies, so the exact version installed for something like
`anyio` or `pygments` depends on when you last ran `pip install` — which is also why a local
venv can be clean while CI's fresh resolve picks up an old, vulnerable version. Fix it by
pinning the flagged package directly in `requirements.txt`, even though it isn't a direct
dependency:

```bash
cd tests
./venv/Scripts/python.exe -m pip show <package>   # confirm what pulls it in, and current version
```

Add a line for it (with a `# via <parent-package>` comment) at or above the version OSV-Scanner
reports as patched, e.g.:

```
anyio==4.14.2             # via httpx
```

Then reinstall and re-collect the tests to confirm nothing broke:

```bash
./venv/Scripts/python.exe -m pip install -r requirements.txt
./venv/Scripts/python.exe -m pytest --collect-only -q
```
