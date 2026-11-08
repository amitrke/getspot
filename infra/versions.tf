# Terraform + provider configuration for GetSpot's Google Cloud resources
# (monitoring alerts, Cloud Run invoker IAM). Firebase deploys (functions,
# rules, hosting) stay in their own workflows; this only manages what those
# tools don't: alerting and the public-invoker bindings for callables.
#
# State lives in a GCS bucket created once by infra/bootstrap.sh (a state
# bucket can't manage itself). Versioning is enabled on it for rollback.

terraform {
  required_version = ">= 1.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  backend "gcs" {
    bucket = "getspot01-tfstate"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
