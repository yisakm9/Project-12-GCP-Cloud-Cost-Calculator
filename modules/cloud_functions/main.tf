# modules/cloud_functions/main.tf
#
# Deploys two Cloud Functions (2nd Gen):
#   1. GetCostDataApi   — HTTP-triggered, serves cost data JSON
#   2. GetWeeklyCostReport — Pub/Sub-triggered, sends email report
#
# Both functions use source code uploaded to a staging GCS bucket.

# ──────────────────────────────────────────────
#  Source Code Staging Bucket
# ──────────────────────────────────────────────
resource "google_storage_bucket" "function_source" {
  project                     = var.project_id
  name                        = "${var.name_prefix}-gcf-source-${var.suffix}"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true

  labels = var.labels
}

# ──────────────────────────────────────────────
#  Cost API Function — Source Upload
# ──────────────────────────────────────────────
data "archive_file" "cost_api_zip" {
  type        = "zip"
  source_dir  = var.cost_api_source_path
  output_path = "${path.module}/tmp/get_cost_api.zip"
}

resource "google_storage_bucket_object" "cost_api_source" {
  name   = "functions/get_cost_api-${data.archive_file.cost_api_zip.output_md5}.zip"
  bucket = google_storage_bucket.function_source.name
  source = data.archive_file.cost_api_zip.output_path
}

# ──────────────────────────────────────────────
#  Cost API Function — Cloud Function (Gen2)
# ──────────────────────────────────────────────
resource "google_cloudfunctions2_function" "cost_api" {
  project     = var.project_id
  name        = "${var.name_prefix}-get-cost-api"
  location    = var.region
  description = "HTTP API that returns GCP cost data from BigQuery billing export"

  build_config {
    runtime     = "python311"
    entry_point = "get_cost_data"

    source {
      storage_source {
        bucket = google_storage_bucket.function_source.name
        object = google_storage_bucket_object.cost_api_source.name
      }
    }
  }

  service_config {
    max_instance_count    = 10
    min_instance_count    = 0
    available_memory      = "256M"
    timeout_seconds       = 120
    service_account_email = var.cost_api_sa_email

    environment_variables = {
      BILLING_PROJECT_ID = var.billing_project_id
      BILLING_DATASET_ID = var.billing_dataset_id
      BILLING_TABLE_ID   = var.billing_table_id
    }

    ingress_settings               = "ALLOW_ALL"
    all_traffic_on_latest_revision = true
  }

  labels = var.labels
}

# Allow unauthenticated invocations (public API for the dashboard)
resource "google_cloud_run_v2_service_iam_member" "cost_api_public" {
  project  = var.project_id
  location = var.region
  name     = google_cloudfunctions2_function.cost_api.service_config[0].service
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ──────────────────────────────────────────────
#  Cost Report Function — Source Upload
# ──────────────────────────────────────────────
data "archive_file" "cost_report_zip" {
  type        = "zip"
  source_dir  = var.cost_report_source_path
  output_path = "${path.module}/tmp/get_cost_report.zip"
}

resource "google_storage_bucket_object" "cost_report_source" {
  name   = "functions/get_cost_report-${data.archive_file.cost_report_zip.output_md5}.zip"
  bucket = google_storage_bucket.function_source.name
  source = data.archive_file.cost_report_zip.output_path
}

# ──────────────────────────────────────────────
#  Cost Report Function — Cloud Function (Gen2)
# ──────────────────────────────────────────────
resource "google_cloudfunctions2_function" "cost_report" {
  project     = var.project_id
  name        = "${var.name_prefix}-get-cost-report"
  location    = var.region
  description = "Generates and emails a weekly GCP cost report via SendGrid"

  build_config {
    runtime     = "python311"
    entry_point = "generate_cost_report"

    source {
      storage_source {
        bucket = google_storage_bucket.function_source.name
        object = google_storage_bucket_object.cost_report_source.name
      }
    }
  }

  service_config {
    max_instance_count    = 3
    min_instance_count    = 0
    available_memory      = "256M"
    timeout_seconds       = 300
    service_account_email = var.cost_report_sa_email

    environment_variables = {
      BILLING_PROJECT_ID = var.billing_project_id
      BILLING_DATASET_ID = var.billing_dataset_id
      BILLING_TABLE_ID   = var.billing_table_id
      SENDER_EMAIL       = var.sender_email
      RECIPIENT_EMAIL    = var.recipient_email
    }

    # SendGrid API key injected via Secret Manager
    secret_environment_variables {
      key        = "SENDGRID_API_KEY"
      project_id = var.project_id
      secret     = var.sendgrid_secret_name
      version    = "latest"
    }

    ingress_settings               = "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
  }

  # Pub/Sub event trigger from Cloud Scheduler
  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = var.report_trigger_topic_id
    retry_policy   = "RETRY_POLICY_RETRY"
  }

  labels = var.labels
}
