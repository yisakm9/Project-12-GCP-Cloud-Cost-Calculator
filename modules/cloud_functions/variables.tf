# modules/cloud_functions/variables.tf

variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The region for Cloud Functions."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "suffix" {
  description = "Random suffix for globally unique bucket name."
  type        = string
}

# ── Service Accounts ──
variable "cost_api_sa_email" {
  description = "Service account email for the Cost API function."
  type        = string
}

variable "cost_report_sa_email" {
  description = "Service account email for the Cost Report function."
  type        = string
}

# ── Source Code Paths ──
variable "cost_api_source_path" {
  description = "Absolute path to the Cost API function source directory."
  type        = string
}

variable "cost_report_source_path" {
  description = "Absolute path to the Cost Report function source directory."
  type        = string
}

# ── BigQuery Billing Export ──
variable "billing_project_id" {
  description = "The project ID where the billing export dataset resides."
  type        = string
}

variable "billing_dataset_id" {
  description = "The BigQuery dataset ID for billing export."
  type        = string
}

variable "billing_table_id" {
  description = "The BigQuery table ID for billing export."
  type        = string
}

# ── Email Configuration ──
variable "sender_email" {
  description = "The sender email address for cost reports."
  type        = string
}

variable "recipient_email" {
  description = "The recipient email address for cost reports."
  type        = string
}

variable "sendgrid_secret_name" {
  description = "The name of the Secret Manager secret containing the SendGrid API key."
  type        = string
}

# ── Pub/Sub ──
variable "report_trigger_topic_id" {
  description = "The fully-qualified ID of the Pub/Sub topic for report triggers."
  type        = string
}

# ── Labels ──
variable "labels" {
  description = "Labels to apply to resources."
  type        = map(string)
  default     = {}
}
