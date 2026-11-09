#!/usr/bin/env bash
# One-time bootstrap for GetSpot's Terraform setup. Run locally by a project
# owner AFTER `gcloud auth login` (and optionally
# `gcloud auth application-default login`).
#
# Creates what Terraform itself depends on (so it can't manage it):
#   1. APIs
#   2. GCS state bucket (versioned, private)
#   3. TWO service accounts with separate trust (least privilege):
#        terraform-plan  - READ-ONLY. Impersonable only by pull_request runs of
#                          this repo. Cannot change infra or write state
#                          (plans run with -lock=false).
#        terraform-apply - can change alerts/Cloud Run IAM and write state.
#                          Impersonable ONLY by jobs that run in the
#                          `terraform-apply` GitHub Environment, so the
#                          environment's protection rules (required reviewers,
#                          deployment branch = main) gate every privileged run.
#   4. Workload Identity Federation pool/provider limited to this repo.
# Then imports the two pre-existing alert policies so they aren't recreated.
#
# Safe to re-run; also migrates away from the legacy single `terraform-ci` SA.
set -euo pipefail

PROJECT_ID="getspot01"
REGION="us-east4"
BUCKET="${PROJECT_ID}-tfstate"
PLAN_SA_NAME="terraform-plan"
APPLY_SA_NAME="terraform-apply"
PLAN_SA="${PLAN_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
APPLY_SA="${APPLY_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
LEGACY_SA="terraform-ci@${PROJECT_ID}.iam.gserviceaccount.com"
POOL="github"
PROVIDER="github-getspot"
REPO="amitrke/getspot"
APPLY_ENVIRONMENT="terraform-apply"

# Existing console-created policies (see Monitoring > Alerting > Policies).
ERROR_LOGS_POLICY_ID="16000387597959882328"
DB_QUERY_POLICY_ID="1890579074505347472"

PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"
POOL_PATH="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL}"

echo "==> Enabling APIs"
gcloud services enable \
  monitoring.googleapis.com run.googleapis.com iam.googleapis.com \
  iamcredentials.googleapis.com sts.googleapis.com \
  cloudresourcemanager.googleapis.com storage.googleapis.com \
  serviceusage.googleapis.com --project "$PROJECT_ID"

echo "==> State bucket gs://${BUCKET}"
if ! gcloud storage buckets describe "gs://${BUCKET}" --project "$PROJECT_ID" >/dev/null 2>&1; then
  gcloud storage buckets create "gs://${BUCKET}" --project "$PROJECT_ID" \
    --location "$REGION" --uniform-bucket-level-access --public-access-prevention
fi
gcloud storage buckets update "gs://${BUCKET}" --versioning

create_sa() {
  local name="$1" email="$2" display="$3"
  if ! gcloud iam service-accounts describe "$email" --project "$PROJECT_ID" >/dev/null 2>&1; then
    gcloud iam service-accounts create "$name" --project "$PROJECT_ID" --display-name "$display"
  fi
}

echo "==> Service accounts"
create_sa "$PLAN_SA_NAME" "$PLAN_SA" "Terraform plan (read-only, PR runs)"
create_sa "$APPLY_SA_NAME" "$APPLY_SA" "Terraform apply (protected environment only)"

# --- terraform-plan: read-only everywhere, read-only on state ---------------
for ROLE in roles/monitoring.viewer roles/run.viewer roles/serviceusage.serviceUsageConsumer; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member "serviceAccount:${PLAN_SA}" --role "$ROLE" --condition=None >/dev/null
done
gcloud storage buckets add-iam-policy-binding "gs://${BUCKET}" \
  --member "serviceAccount:${PLAN_SA}" --role roles/storage.objectViewer >/dev/null

# --- terraform-apply: can change infra and state ----------------------------
# run.admin is broader than ideal but is the predefined role that includes
# run.services.setIamPolicy; tighten with a custom role later if desired.
for ROLE in roles/monitoring.alertPolicyEditor roles/monitoring.notificationChannelViewer \
            roles/run.admin roles/serviceusage.serviceUsageConsumer; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member "serviceAccount:${APPLY_SA}" --role "$ROLE" --condition=None >/dev/null
done
gcloud storage buckets add-iam-policy-binding "gs://${BUCKET}" \
  --member "serviceAccount:${APPLY_SA}" --role roles/storage.objectAdmin >/dev/null

echo "==> Workload Identity Federation"
if ! gcloud iam workload-identity-pools describe "$POOL" --location global --project "$PROJECT_ID" >/dev/null 2>&1; then
  gcloud iam workload-identity-pools create "$POOL" --location global \
    --project "$PROJECT_ID" --display-name "GitHub Actions"
fi
if ! gcloud iam workload-identity-pools providers describe "$PROVIDER" \
     --workload-identity-pool "$POOL" --location global --project "$PROJECT_ID" >/dev/null 2>&1; then
  gcloud iam workload-identity-pools providers create-oidc "$PROVIDER" \
    --workload-identity-pool "$POOL" --location global --project "$PROJECT_ID" \
    --issuer-uri "https://token.actions.githubusercontent.com" \
    --attribute-mapping "google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref" \
    --attribute-condition "assertion.repository == '${REPO}'"
fi

# Trust is bound to the exact OIDC *subject*, not just the repository:
#   plan  <- repo:<repo>:pull_request                  (PR runs only)
#   apply <- repo:<repo>:environment:terraform-apply   (that environment only)
# A plain branch push or other workflow gets neither subject, so it can't
# impersonate either account.
gcloud iam service-accounts add-iam-policy-binding "$PLAN_SA" --project "$PROJECT_ID" \
  --role roles/iam.workloadIdentityUser \
  --member "principal://iam.googleapis.com/${POOL_PATH}/subject/repo:${REPO}:pull_request" >/dev/null
gcloud iam service-accounts add-iam-policy-binding "$APPLY_SA" --project "$PROJECT_ID" \
  --role roles/iam.workloadIdentityUser \
  --member "principal://iam.googleapis.com/${POOL_PATH}/subject/repo:${REPO}:environment:${APPLY_ENVIRONMENT}" >/dev/null

# Retire the legacy single SA, whose trust was repo-wide (any workflow/branch).
if gcloud iam service-accounts describe "$LEGACY_SA" --project "$PROJECT_ID" >/dev/null 2>&1; then
  echo "==> Deleting legacy service account ${LEGACY_SA}"
  gcloud iam service-accounts delete "$LEGACY_SA" --project "$PROJECT_ID" --quiet
fi

echo "==> terraform init + import existing alert policies"
cd "$(dirname "$0")"
# Use the active gcloud account for Terraform if ADC isn't configured.
if ! gcloud auth application-default print-access-token >/dev/null 2>&1; then
  export GOOGLE_OAUTH_ACCESS_TOKEN="$(gcloud auth print-access-token)"
fi
terraform init
terraform import google_monitoring_alert_policy.error_logs \
  "projects/${PROJECT_ID}/alertPolicies/${ERROR_LOGS_POLICY_ID}" || true
terraform import google_monitoring_alert_policy.db_query_errors \
  "projects/${PROJECT_ID}/alertPolicies/${DB_QUERY_POLICY_ID}" || true

cat <<EOF

Done. Review with:  cd infra && terraform plan

Set these as GitHub repository VARIABLES (Settings > Secrets and variables > Actions > Variables):
  GCP_WORKLOAD_IDENTITY_PROVIDER      = ${POOL_PATH}/providers/${PROVIDER}
  GCP_TERRAFORM_PLAN_SERVICE_ACCOUNT  = ${PLAN_SA}
  GCP_TERRAFORM_APPLY_SERVICE_ACCOUNT = ${APPLY_SA}
(GCP_TERRAFORM_SERVICE_ACCOUNT is obsolete; delete it if you created it.)

Also create the GitHub Environment "${APPLY_ENVIRONMENT}" (Settings > Environments) and:
  - add yourself as a required reviewer
  - set "Deployment branches" to "Selected branches" = main
Without that restriction, any branch's workflow could run in the environment.
EOF
