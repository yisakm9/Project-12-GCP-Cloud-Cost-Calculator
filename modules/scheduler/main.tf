# modules/scheduler/main.tf
#
# Creates a Cloud Scheduler job that triggers the weekly cost report
# Cloud Function via a Pub/Sub message.

resource "google_cloud_scheduler_job" "weekly_report" {
  project     = var.project_id
  region      = var.region
  name        = "${var.name_prefix}-weekly-cost-report"
  description = "Triggers the weekly GCP cost report Cloud Function every Monday at 9:00 AM UTC"
  schedule    = var.schedule
  time_zone   = var.time_zone

  pubsub_target {
    topic_name = var.pubsub_topic_id
    data       = base64encode("{\"action\": \"generate_weekly_report\"}")
  }

  retry_config {
    retry_count          = 3
    min_backoff_duration = "10s"
    max_backoff_duration = "300s"
    max_doublings        = 3
  }
}
