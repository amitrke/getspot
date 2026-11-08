# Monitoring & Infrastructure as Code

GetSpot's Google Cloud alerting and a few IAM bindings are managed with
Terraform in [`infra/`](../infra), applied by GitHub Actions. Firebase deploys
(functions, rules, hosting) remain in their own workflows.

## What is managed

| Resource | File | Purpose |
|---|---|---|
| Alert policy **Error Logs** | `infra/monitoring.tf` | `severity=ERROR` logs from functions/Firestore (everything except `RunQuery`) |
| Alert policy **DB Query Alert** | `infra/monitoring.tf` | Firestore `RunQuery` errors (e.g. missing index), Critical |
| Alert policy **Callable rejected or failed** | `infra/monitoring.tf` | Cloud Run 401/403/5xx request logs |
| Public `run.invoker` on callables | `infra/iam.tf` | Callables must be publicly invokable; auth is enforced in code |

All alerts notify the existing **GetSpot Google Chat** space, at most one
notification per policy per 10 minutes.

### Why a separate 401/403/5xx alert?

A callable function that is not publicly invokable returns **401 in ~0 ms**
from Cloud Run, logged at **WARNING** severity, before any function code runs.
Severity-based alerts never see it. This is what broke `cancelEvent` in
Nov 2026. `firebase deploy` normally grants `allUsers` the invoker role, but
skips it silently when the deploying identity lacks `setIamPolicy`, so
`infra/iam.tf` asserts it.

### Adding a new callable function

Add its name to `callable_functions` in `infra/variables.tf` (names must match
the `httpsCallable('...')` calls in `lib/`). Do **not** add triggers or
scheduled functions.

## The Google Chat channel

Chat notification channels are a Preview feature that needs an interactive
authorization, so Terraform cannot create one. Terraform looks it up by display
name (`GetSpot`, type `google_chat`). To recreate it: Monitoring > Alerting > Edit
notification channels > Google Chat.

## State

State is in GCS: `gs://getspot01-tfstate` (prefix `terraform/state`), with
object versioning enabled for rollback and locking handled by the GCS backend.
Never commit state files.

## One-time setup

Run once by a project owner (`gcloud auth login` and
`gcloud auth application-default login` first):

```bash
bash infra/bootstrap.sh
```

It enables APIs, creates the state bucket, a `terraform-ci` service account
with least-privilege roles, a Workload Identity Federation pool restricted to
`github.com/amitrke/getspot`, and imports the two pre-existing alert policies.
It prints two values to save as **GitHub repository variables**:

- `GCP_WORKLOAD_IDENTITY_PROVIDER`
- `GCP_TERRAFORM_SERVICE_ACCOUNT`

Optionally add required reviewers to the `terraform-apply` GitHub Environment
for a manual approval before apply.

## Day to day

1. Edit `infra/*.tf` on a feature branch and open a PR to `develop`.
2. CI runs `fmt`, `validate` and `plan`; read the plan in the job summary.
3. When the change reaches `main`, CI applies it.

Locally: `cd infra && terraform init && terraform plan`.

Avoid editing these resources in the Cloud console: the next plan will show
the drift and apply will revert it.

## Ideas for later

Billing budget alert, Firestore backups / PITR, uptime checks on key callables,
SLOs, Secret Manager. All are supported by Terraform and would live in `infra/`.
