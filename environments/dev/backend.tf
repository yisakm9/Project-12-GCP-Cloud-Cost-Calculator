# environments/dev/backend.tf
#
# Terraform remote state stored in a GCS bucket with versioning.
# This bucket must be created manually before running terraform init:
#
#   gsutil mb -p YOUR_PROJECT_ID -l us-central1 gs://costcalc-terraform-state-dev
#   gsutil versioning set on gs://costcalc-terraform-state-dev

terraform {
  backend "gcs" {
    bucket = "costcalc-tfstate-6cdce5b2"
    prefix = "terraform/state"
  }
}
