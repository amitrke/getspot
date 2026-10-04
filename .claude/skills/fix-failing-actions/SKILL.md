---
name: fix-failing-actions
description: Look through the most recent GitHub Actions runs for GetSpot, diagnose the failing ones, and fix the ones whose cause is in the repo (code, lint, build, workflow config) on a branch with a PR. Use when the user asks to check CI, look at failing workflows/actions/builds, or fix broken pipelines.
---

# Diagnose and fix failing GitHub Actions runs (GetSpot)

Workflows live in `.github/workflows/` (dry-run lint/build for `functions` and
`main`, data-integrity tests, OSV/dependency-review, and deploys for Android,
iOS, functions, Firestore rules, and Firebase Hosting). The goal is to find
real failures, fix what is fixable from the repo, and clearly report the rest.

## 1. Find recent failures

```
gh run list --limit 40 --json databaseId,workflowName,displayTitle,headBranch,event,conclusion,status,createdAt,url
```

Keep runs with `conclusion` of `failure` or `timed_out`. Ignore `cancelled`,
`skipped`, and in-progress runs. Then **dedupe**: for each (workflow, branch),
only the newest run matters. If a newer run of the same workflow on the same
branch succeeded, the failure is already resolved, so skip it and say so.

## 2. Diagnose each remaining failure

```
gh run view <id> --json jobs -q '.jobs[] | select(.conclusion=="failure") | {name, steps: [.steps[] | select(.conclusion=="failure") | .name]}'
gh run view <id> --log-failed | tail -n 80
```

Find the failing step and the actual error line. Note: npm `warn` lines (for
example `ERESOLVE overriding peer dependency`) are noise, so keep reading to the
real error. Classify the cause:

- **Fixable in the repo**: lint errors, TypeScript/build errors, failing tests
  caused by code, broken workflow YAML, wrong paths/versions/Node version in a
  workflow, lockfile out of sync with `package.json`.
- **Dependabot PR broken by the bump itself** (e.g. a major bump with an
  incompatible peer dependency): not a repo bug. Report it and recommend
  holding or closing the PR; don't hand-edit Dependabot branches.
- **Infra / transient / external**: network timeouts, registry outages, runner
  failures, store API rate limits. Suggest `gh run rerun <id> --failed`, and
  only rerun if the user says so.
- **Needs secrets or the user's accounts**: expired or missing secrets,
  signing certificates/provisioning profiles, Play Console / App Store Connect /
  Firebase auth errors. Do **not** attempt a workaround; report exactly what
  the user must refresh. Never print, echo, or add secret values.

## 3. Reproduce locally before fixing

Check out the failing ref and run the same commands the workflow runs:
- `functions/`: `npm ci && npm run lint && npm run build`
- `main/`: `npm ci && npm run lint && npm run build` (confirm against
  `dry-run-main.yml`)
- Flutter: `flutter pub get && flutter analyze && flutter test`
- `tests/`: see `dry-run-tests.yml` for the exact steps

Read the workflow file for the authoritative commands and working directory.
Confirm the failure reproduces, make the smallest fix, and re-run the same
commands to confirm it passes. If it won't reproduce locally, say so rather
than guessing at a fix.

## 4. Ship fixes safely

- Never commit directly to `main` or `develop`, and never touch a Dependabot
  branch. Branch off the failing branch's base (normally `develop`):
  `git checkout -b fix/ci-<short-description> origin/develop`.
- If the failure is on a feature branch the user owns, fix on that branch
  after telling them.
- Don't weaken CI to get green: no removing checks, adding `continue-on-error`,
  loosening lint rules, or skipping tests, unless the user explicitly asks.
- Changes to deploy workflows (`deploy-*.yml`, `firebase-hosting-merge.yml`,
  `promote-to-appstore.yml`) run against production; make the minimal fix and
  call it out in the PR.
- Commit and open the PR using the `commit-push-pr` skill (Conventional
  Commits, `type(ci|functions|...)`, base `develop`). One PR per distinct root
  cause.

## 5. Report

Give a table of recent failures: workflow, branch, run link, cause, and
outcome (fixed in PR link / needs user action / transient, rerun suggested /
Dependabot bump incompatible / already resolved). Don't claim a fix works
until the local reproduction passes, and say that CI on the PR still has to
confirm it.
