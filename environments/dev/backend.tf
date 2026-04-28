# environments/dev/backend.tf
#
# Terraform remote state stored in a GCS bucket with versioning.
# This bucket must be created manually before running terraform init:
#
#   gsutil mb -p YOUR_PROJECT_ID -l us-central1 gs://costcalc-terraform-state-dev
#   gsutil versioning set on gs://costcalc-terraform-state-dev

terraform {
  backend "gcs" {
    bucket = "costcalc-terraform-state-dev"
    prefix = "terraform/state"
  }
}
