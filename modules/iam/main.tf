# modules/iam/main.tf
#
# Creates dedicated service accounts with least-privilege IAM bindings.
# Follows the principle of least privilege — each function gets only
# the permissions it needs.

# ──────────────────────────────────────────────
#  Service Account: Cost API Function
# ──────────────────────────────────────────────
resource "google_service_account" "cost_api_sa" {
  project      = var.project_id
  account_id   = "${var.name_prefix}-cost-api-sa"
  display_name = "Cost API Cloud Function SA"
  description  = "Service account for the Cost Data API Cloud Function (BigQuery read-only access)"
}

# Grant BigQuery Data Viewer — read-only access to billing export data
resource "google_project_iam_member" "cost_api_bq_viewer" {
  project = var.project_id
  role    = "roles/bigquery.dataViewer"
  member  = "serviceAccount:${google_service_account.cost_api_sa.email}"
}

# Grant BigQuery Job User — required to execute queries
resource "google_project_iam_member" "cost_api_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.cost_api_sa.email}"
}

# ──────────────────────────────────────────────
#  Service Account: Cost Report Function
# ──────────────────────────────────────────────
resource "google_service_account" "cost_report_sa" {
  project      = var.project_id
  account_id   = "${var.name_prefix}-report-sa"
  display_name = "Cost Report Cloud Function SA"
  description  = "Service account for the Weekly Cost Report Cloud Function (BigQuery + Secret Manager)"
}

# Grant BigQuery Data Viewer
resource "google_project_iam_member" "cost_report_bq_viewer" {
  project = var.project_id
  role    = "roles/bigquery.dataViewer"
  member  = "serviceAccount:${google_service_account.cost_report_sa.email}"
}

# Grant BigQuery Job User
resource "google_project_iam_member" "cost_report_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.cost_report_sa.email}"
}

# Grant Secret Manager accessor — to read the SendGrid API key
resource "google_project_iam_member" "cost_report_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cost_report_sa.email}"
}

# Grant Eventarc Event Receiver — to receive Pub/Sub events
resource "google_project_iam_member" "cost_report_eventarc" {
  project = var.project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.cost_report_sa.email}"
}

# Grant Cloud Run Invoker — Gen2 functions run on Cloud Run
resource "google_project_iam_member" "cost_report_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.cost_report_sa.email}"
}
