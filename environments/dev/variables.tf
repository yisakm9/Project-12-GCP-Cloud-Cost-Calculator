# environments/dev/variables.tf

# ──────────────────────────────────────────────
#  Project Configuration
# ──────────────────────────────────────────────
variable "project_id" {
  description = "The GCP project ID where resources will be created."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be 6-30 characters, lowercase letters, digits, and hyphens."
  }
}

variable "region" {
  description = "The default GCP region for regional resources."
  type        = string
  default     = "us-central1"
}

variable "app_name" {
  description = "Application name used as a prefix for all resources."
  type        = string
  default     = "costcalc"
}

variable "environment" {
  description = "The deployment environment (dev, staging, prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# ──────────────────────────────────────────────
#  Billing Configuration
# ──────────────────────────────────────────────
variable "billing_account_id" {
  description = "The GCP billing account ID for budget alerts (format: XXXXXX-XXXXXX-XXXXXX)."
  type        = string
}

variable "billing_project_id" {
  description = "The project ID where the BigQuery billing export dataset resides."
  type        = string
}

variable "billing_dataset_id" {
  description = "The BigQuery dataset ID containing the billing export."
  type        = string
  default     = "billing_export"
}

variable "billing_table_id" {
  description = "The BigQuery table ID for the standard billing export."
  type        = string
}

variable "budget_amount" {
  description = "Monthly budget threshold in USD. Alerts trigger at 50%, 80%, and 100%."
  type        = number
  default     = 100

  validation {
    condition     = var.budget_amount > 0
    error_message = "Budget amount must be greater than zero."
  }
}

# ──────────────────────────────────────────────
#  Notification Configuration
# ──────────────────────────────────────────────
variable "notification_email" {
  description = "The email address to receive budget alerts and weekly cost reports."
  type        = string
}

# ──────────────────────────────────────────────
#  Scheduling
# ──────────────────────────────────────────────
variable "report_schedule" {
  description = "Cron expression for the weekly cost report (Cloud Scheduler format)."
  type        = string
  default     = "0 9 * * 1" # Every Monday at 9:00 AM UTC
}
