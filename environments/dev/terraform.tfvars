# environments/dev/terraform.tfvars
#
# IMPORTANT: Update these values for your environment before deploying.

project_id  = "cloud-cost-calculator-dev"
region      = "us-central1"
environment = "dev"
app_name    = "costcalc"

# ── Billing Configuration ──
# Find your billing account: gcloud billing accounts list
billing_account_id = "XXXXXX-XXXXXX-XXXXXX"

# The project where billing export is configured
billing_project_id = "cloud-cost-calculator-dev"

# BigQuery dataset and table for billing export
# Table format: gcp_billing_export_v1_XXXXXX_XXXXXX_XXXXXX (hyphens → underscores)
billing_dataset_id = "billing_export"
billing_table_id   = "gcp_billing_export_v1_XXXXXX_XXXXXX_XXXXXX"

# ── Alerts & Reports ──
notification_email = "yisakmesifin@gmail.com"
budget_amount      = 100
report_schedule    = "0 9 * * 1" # Every Monday at 9:00 AM UTC
