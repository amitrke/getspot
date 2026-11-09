variable "project_id" {
  description = "GCP / Firebase project ID."
  type        = string
  default     = "getspot01"
}

variable "region" {
  description = "Region all GetSpot resources are deployed to."
  type        = string
  default     = "us-east4"
}

variable "chat_channel_display_name" {
  description = <<-EOT
    Display name of the existing Google Chat notification channel. Chat
    channels need an interactive authorization in the console, so Terraform
    looks the channel up instead of creating it.
  EOT
  type        = string
  default     = "GetSpot"
}

variable "callable_functions" {
  description = <<-EOT
    Callable (onCall) Cloud Functions. Firebase callables must be publicly
    invokable at the Cloud Run layer; auth is enforced in code via
    request.auth. Keep in sync with functions/src (httpsCallable names in lib/).
    Triggers and scheduled functions must NOT be listed here.
  EOT
  type        = list(string)
  default = [
    "createGroup",
    "findGroupByCode",
    "manageJoinRequest",
    "manageGroupMember",
    "withdrawFromEvent",
    "cancelEvent",
    "updateEventCapacity",
    "updateFcmToken",
    "updateUserDisplayName",
    "requestAccountDeletion",
  ]
}
