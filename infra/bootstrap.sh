#!/usr/bin/env bash
# One-time bootstrap for GetSpot's Terraform setup. Run locally by a project
# owner AFTER `gcloud auth login` and `gcloud auth application-default login`.
#
# Creates what Terraform itself depends on (so it can't manage it):
#   1. APIs
#   2. GCS state bucket (versioned, private)
#   3. terraform-ci service account + least-privilege roles
#   4. Workload Identity Federation pool/provider trusting ONLY github.com/amitrke/getspot
# Then imports the two pre-existing alert policies so they aren't recreated.
#
# Idempotent-ish: re-running skips things that already exist.
set -euo pipefail

PROJECT_ID="getspot01"
REGION="us-east4"
BUCKET="${PROJECT_ID}-tfstate"
SA_NAME="terraform-ci"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
POOL="github"
PROVIDER="github-getspot"
REPO="amitrke/getspot"

# Existing console-created policies (see Monitoring > Alerting > Policies).
ERROR_LOGS_POLICY_ID="16000387597959882328"
DB_QUERY_POLICY_ID="1890579074505347472"

PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"

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

echo "==> Service account ${SA_EMAIL}"
if ! gcloud iam service-accounts describe "$SA_EMAIL" --project "$PROJECT_ID" >/dev/null 2>&1; then
  gcloud iam service-accounts create "$SA_NAME" --project "$PROJECT_ID" \
    --display-name "Terraform CI (GitHub Actions)"
fi

# Project roles: edit alert policies, read the Chat channel, set IAM on Cloud
# Run services. run.admin is broader than ideal but is the predefined role that
# includes run.services.setIamPolicy; tighten with a custom role later if desired.
for ROLE in roles/monitoring.alertPolicyEditor roles/monitoring.notificationChannelViewer \
            roles/run.admin roles/serviceusage.serviceUsageConsumer; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member "serviceAccount:${SA_EMAIL}" --role "$ROLE" --condition=None >/dev/null
done
# State bucket access limited to this bucket.
gcloud storage buckets add-iam-policy-binding "gs://${BUCKET}" \
  --member "serviceAccount:${SA_EMAIL}" --role roles/storage.objectAdmin >/dev/null

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
# Only workflows from this repo may impersonate the SA.
gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" --project "$PROJECT_ID" \
  --role roles/iam.workloadIdentityUser \
  --member "principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL}/attribute.repository/${REPO}" >/dev/null

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

Add these as GitHub repository VARIABLES (Settings > Secrets and variables > Actions > Variables):
  GCP_WORKLOAD_IDENTITY_PROVIDER = projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL}/providers/${PROVIDER}
  GCP_TERRAFORM_SERVICE_ACCOUNT  = ${SA_EMAIL}
EOF
