# environments/dev/terraform.tfvars
#
# IMPORTANT: Update these values for your environment before deploying.

project_id  = "project-6cdce5b2-1881-424f-a94"
region      = "us-central1"
environment = "dev"
app_name    = "costcalc"

# ── Billing Configuration ──
# Find your billing account: gcloud billing accounts list
billing_account_id = "0145C1-35A0C2-4A5E6F"

# The project where billing export is configured
billing_project_id = "project-6cdce5b2-1881-424f-a94"

# BigQuery dataset and table for billing export
# Table format: gcp_billing_export_v1_XXXXXX_XXXXXX_XXXXXX (hyphens → underscores)
billing_dataset_id = "billing_export"
billing_table_id   = "gcp_billing_export_v1_0145C1_35A0C2_4A5E6F"

# ── Alerts & Reports ──
notification_email = "yisakmesifin@gmail.com"
budget_amount      = 100
report_schedule    = "0 9 * * 1" # Every Monday at 9:00 AM UTC
