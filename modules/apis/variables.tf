# modules/apis/variables.tf

variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "apis" {
  description = "List of GCP APIs to enable."
  type        = list(string)
  default = [
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudscheduler.googleapis.com",
    "bigquery.googleapis.com",
    "billingbudgets.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "monitoring.googleapis.com",
    "pubsub.googleapis.com",
    "secretmanager.googleapis.com",
    "run.googleapis.com",
    "storage.googleapis.com",
    "eventarc.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
  ]
}
