# Log-based alert policies, all notifying the existing Google Chat space.
#
# Why three policies:
#  - error_logs:       ERROR-severity logs (functions, Firestore rules/listen
#                      errors). Previously excluded ALL of Firestore, which hid
#                      rules errors; only RunQuery is split out below.
#  - db_query_errors:  Firestore RunQuery errors (e.g. missing index), Critical.
#  - callable_failures: Cloud Run request logs with 401/403/5xx. A callable that
#                      isn't publicly invokable returns 401 at WARNING level,
#                      before function code runs, so severity-based alerts miss it.

data "google_monitoring_notification_channel" "chat" {
  display_name = var.chat_channel_display_name
  type         = "google_chat"
}

locals {
  channels = [data.google_monitoring_notification_channel.chat.name]
}

resource "google_monitoring_alert_policy" "error_logs" {
  display_name = "Error Logs"
  combiner     = "OR"
  severity     = "ERROR"

  documentation {
    mime_type = "text/markdown"
    content   = "ERROR-severity log from a GetSpot Cloud Function or Firestore (not RunQuery). Open Logs Explorer for project `getspot01`, filter `severity=ERROR`, and inspect the entry named in the alert."
  }

  conditions {
    display_name = "Error Logs"
    condition_matched_log {
      filter = <<-EOT
        severity="ERROR"
        protoPayload.methodName!="google.firestore.v1.Firestore.RunQuery"
      EOT
    }
  }

  alert_strategy {
    notification_prompts = ["OPENED"]
    notification_rate_limit {
      period = "600s"
    }
    auto_close = "604800s"
  }

  notification_channels = local.channels
}

resource "google_monitoring_alert_policy" "db_query_errors" {
  display_name = "DB Query Alert"
  combiner     = "OR"
  severity     = "CRITICAL"

  documentation {
    mime_type = "text/markdown"
    content   = "Firestore RunQuery returned an error (often a missing composite index). Check `firestore.indexes.json` and Logs Explorer for the failing query."
  }

  conditions {
    display_name = "DB Query Alert"
    condition_matched_log {
      filter = <<-EOT
        severity="ERROR"
        protoPayload.methodName="google.firestore.v1.Firestore.RunQuery"
        protoPayload.serviceName="firestore.googleapis.com"
      EOT
    }
  }

  alert_strategy {
    notification_prompts = ["OPENED"]
    notification_rate_limit {
      period = "600s"
    }
    auto_close = "604800s"
  }

  notification_channels = local.channels
}

resource "google_monitoring_alert_policy" "callable_failures" {
  display_name = "Callable rejected or failed"
  combiner     = "OR"
  severity     = "ERROR"

  documentation {
    mime_type = "text/markdown"
    content   = "A Cloud Run / Cloud Functions request returned 401, 403 or 5xx. A 401 with ~0 ms latency means the service is not publicly invokable (missing `allUsers` run.invoker binding), so the function never ran. Check `infra/iam.tf` and the service's Security tab. For 5xx, check the function's logs."
  }

  conditions {
    display_name = "HTTP 401/403/5xx on Cloud Run"
    condition_matched_log {
      filter = <<-EOT
        resource.type="cloud_run_revision"
        httpRequest.status:*
        (httpRequest.status=401 OR httpRequest.status=403 OR httpRequest.status>=500)
      EOT
    }
  }

  alert_strategy {
    notification_prompts = ["OPENED"]
    notification_rate_limit {
      period = "600s"
    }
    auto_close = "604800s"
  }

  notification_channels = local.channels
}
