# modules/pubsub/main.tf
#
# Creates Pub/Sub topics for event-driven communication.
# - Report trigger topic: Cloud Scheduler → Cloud Function
# - Budget alert topic: Cloud Billing Budget → Notification

resource "google_pubsub_topic" "report_trigger" {
  project = var.project_id
  name    = "${var.name_prefix}-report-trigger"
  labels  = var.labels

  message_retention_duration = "86400s" # 24 hours
}

resource "google_pubsub_topic" "budget_alerts" {
  project = var.project_id
  name    = "${var.name_prefix}-budget-alerts"
  labels  = var.labels

  message_retention_duration = "86400s"
}

# Note: The Cloud Billing service account is granted publish permissions
# automatically when a google_billing_budget targets this topic.
