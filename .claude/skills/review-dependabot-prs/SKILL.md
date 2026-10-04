---
name: review-dependabot-prs
description: Triage open Dependabot pull requests for GetSpot and automatically merge every one that is not failing its PR checks (into develop), without asking per PR. Use whenever the user asks to review, triage, process, clear, or merge dependabot PRs or dependency updates in this repo.
---

# Triage and auto-merge Dependabot PRs (GetSpot)

Dependabot is configured (`.github/dependabot.yml`) weekly for `/functions` (npm),
`/main` (npm), `/tests` (pip), and GitHub Actions, all targeting **`develop`**.
Policy: **merge everything that is not failing the automatic checks that run on
PR creation.** No confirmation is needed per PR, and bump size (including major)
is not a reason to hold. Merging to `develop` doesn't deploy to production; that
only happens when `develop` is merged into `main`.

## 1. List open Dependabot PRs

```
gh pr list --author "app/dependabot" --state open --limit 50 \
  --json number,title,baseRefName,mergeable,mergeStateStatus,statusCheckRollup,url
```

If there are none, say so and stop. Skip (and report) any PR whose base isn't
`develop`.

## 2. Classify each PR from `statusCheckRollup`

- **Failing**: any `CheckRun` with conclusion `FAILURE`, `TIMED_OUT`,
  `CANCELLED`, or `ACTION_REQUIRED`, or any `StatusContext` with state
  `FAILURE`/`ERROR`. **Do not merge.** Find the cause
  (`gh pr checks <n>`, `gh run view <run-id> --log-failed`) and report it in
  one line.
- **Pending**: any check not yet `COMPLETED`, or `mergeable` is `UNKNOWN`. Don't
  merge yet; report as pending and suggest re-running the skill shortly. Don't
  poll or sleep in a loop.
- **Conflicting**: `mergeable` is `CONFLICTING`. Don't merge; comment
  `@dependabot rebase` (`gh pr comment <n> --body "@dependabot rebase"`) and
  report it.
- **Not failing**: every check is `SUCCESS`, `SKIPPED`, or `NEUTRAL` and the PR
  is `MERGEABLE`. **Merge.**

Skipped checks (e.g. `OSV-Scanner / scan-scheduled`) are fine. A PR with zero
checks reported is treated as pending, not passing.

## 3. Merge

```
gh pr merge <n> --merge
```

Use `--merge` (the repo history uses merge commits, e.g. "Merge pull request
#178 from ..."). Never use `--admin` to bypass failing or missing required
checks.

Merge one at a time. After each merge, re-check the remaining PRs with
`gh pr view <n> --json mergeable,mergeStateStatus`; PRs touching the same
lockfile commonly turn conflicting, and those get `@dependabot rebase` and are
picked up on the next run.

## 4. Report

Give a short table: merged (number, package, from→to), failing (with cause),
pending, conflicting/awaiting rebase, skipped (non-`develop` base). Call out any
**major version bumps** or bumps of `firebase-admin`/`firebase-functions` that
were merged, so the user knows to sanity-check `develop`'s preview deploy before
promoting to `main`.

Don't close PRs or comment `@dependabot ignore` unless the user asks.
