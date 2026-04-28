# modules/monitoring/variables.tf

variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "project_number" {
  description = "The GCP project number (numeric)."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "alert_email" {
  description = "The email address for alert notifications."
  type        = string
}

variable "billing_account_id" {
  description = "The GCP billing account ID for budget alerts."
  type        = string
}

variable "budget_amount" {
  description = "Monthly budget threshold in USD."
  type        = number
  default     = 100
}

variable "budget_alerts_topic_id" {
  description = "The fully-qualified ID of the Pub/Sub topic for budget alerts."
  type        = string
}

variable "load_balancer_ip" {
  description = "The IP address of the Load Balancer for uptime checks."
  type        = string
}
