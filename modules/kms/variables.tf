# modules/kms/variables.tf

variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The region for the KMS keyring."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "labels" {
  description = "Labels to apply to the crypto key."
  type        = map(string)
  default     = {}
}
