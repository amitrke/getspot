# Public invoker binding for callable functions.
#
# Firebase callable functions are served by Cloud Run and must allow
# unauthenticated invocation at the IAM layer; the function itself verifies the
# Firebase ID token (request.auth). Without this binding Cloud Run answers 401
# before the code runs (this is what broke cancelEvent). `firebase deploy`
# normally sets it, but silently doesn't when the deploying identity lacks
# setIamPolicy, so we assert it here.
#
# google_cloud_run_service_iam_member is additive: it only ensures this one
# member/role exists and never removes other bindings.

resource "google_cloud_run_service_iam_member" "callable_public_invoker" {
  for_each = toset(var.callable_functions)

  project  = var.project_id
  location = var.region
  # Gen2 functions run as Cloud Run services named after the function, lowercased.
  service = lower(each.value)
  role    = "roles/run.invoker"
  member  = "allUsers"
}
