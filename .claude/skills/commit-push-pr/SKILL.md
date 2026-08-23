---
name: commit-push-pr
description: Commit the current changes, push the branch, and open a pull request following GetSpot's conventions (conventional commit messages, feature-branch → develop → main flow, gh pr create with a Summary/Test plan body). Use whenever the user asks to commit, push, ship, or open a PR for work in this repo.
---

# Commit, push, and open a PR (GetSpot)

Use this whenever the user asks to commit work, push a branch, "ship" a change,
or open a pull request in this repo. Follow every step — don't skip the
confirmation gates, since push and PR creation are visible to others.

## 1. Assess state first

Run in parallel:
- `git status` (never `-uall`)
- `git diff` (unstaged) and `git diff --staged`
- `git log --oneline -15` — this repo uses **Conventional Commits**
  (`type(scope): imperative summary`, lowercase, no trailing period). Common
  types seen in history: `feat`, `fix`, `chore`, `ci`, `refactor`, `docs`.
  Common scopes: the touched area (`functions`, `android`, `ios`, `ci`, `deps`).

Confirm nothing unexpected is staged (secrets, `.env`, generated files) before
proceeding. If `git status` after a broad `git add` shows files you didn't
expect, stop and check their contents.

## 2. Figure out the right branch — don't commit straight to `main`, and be
   careful committing straight to `develop`

Branch model (see `docs/DEPLOYMENT.md`):
- Feature/fix work → its own branch → **PR into `develop`**.
- Once verified on the `develop` preview channel → **PR `develop` into `main`**
  → merging to `main` deploys web, functions, and Firestore rules to
  production together.

So:
- **On `main`**: stop. Never commit or push here directly — ask the user how
  they want to proceed.
- **On `develop`, with changes that are a normal feature/fix** (i.e. this
  isn't an intentional develop→main release PR): create a new branch off
  `develop` first — `git checkout -b <type>/<short-kebab-description>`
  (e.g. `fix/join-request-membership-check`) — then commit there. Don't leave
  ad hoc work sitting as uncommitted changes directly on `develop`.
- **On a feature branch already**: commit there as normal.
- **Deliberately preparing a `develop` → `main` release PR**: stay on
  `develop`; the target base branch for the PR is `main` instead of the usual
  default.

If it's unclear which of these applies (e.g. ambiguous whether this is meant
as a release), ask the user rather than guessing.

## 3. Commit

- Stage specific files by name — avoid `git add -A`/`git add .`.
- Write a Conventional Commit message matching the style above. Focus the
  summary on *why*, not a restatement of the diff.
- Only create commits when the user has asked for one (or clearly asked for
  the full commit→push→PR flow in this same request).
- Append the standard trailer:
  ```
  Co-Authored-By: Claude <noreply@anthropic.com>
  ```
- Never use `--no-verify`, `--amend` (unless explicitly asked), or skip hooks.
  If a pre-commit hook fails, fix the underlying issue and make a new commit.

## 4. Confirm before pushing

Pushing and opening a PR are actions visible to others. Before doing either,
show the user what will be pushed (branch name, target base, commit summary)
and get an explicit go-ahead — unless they already asked for the full
commit→push→PR flow in the same message that triggered this skill, in which
case proceed and just narrate what you're doing.

## 5. Push

```
git push -u origin <branch>
```

Never force-push without explicit user instruction, and never force-push to
`main`/`develop` at all.

## 6. Open the PR

```
gh pr create --base <develop-or-main> --title "<type(scope): summary>" --body "$(cat <<'EOF'
## Summary
- <1-3 bullet points, what changed and why>

## Test plan
- [ ] <how this was/should be verified>
EOF
)"
```

- Default base is `develop`, unless this is a deliberate `develop`→`main`
  release PR (see step 2), or the user names a different base explicitly.
- Base the Summary on everything in the diff, not just the latest commit if
  there are several commits going into this PR.
- Return the PR URL to the user when done.

## Repo-specific things worth mentioning to the user, when relevant

- PRs touching `functions/**` or `main/**` now get a real `pull_request`-time
  lint+build check (`dry-run-functions.yml`, `dry-run-main.yml`) — CodeQL and
  GitGuardian passing is not the same as the build/lint actually passing.
  Dependabot-triggered PR runs don't get repo secrets, so those checks only
  run lint + build for such PRs, not an authenticated deploy dry-run.
- Firestore rules only deploy on push to `main` (`deploy-firestore-rules.yml`)
  — a rules change merged to `develop` isn't live until the `develop`→`main`
  PR merges.
