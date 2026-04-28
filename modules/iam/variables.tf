# modules/iam/variables.tf

variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names (e.g., 'costcalc-dev')."
  type        = string
}
