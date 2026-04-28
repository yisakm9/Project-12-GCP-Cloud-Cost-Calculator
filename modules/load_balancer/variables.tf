# modules/load_balancer/variables.tf

variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The region for regional resources (Serverless NEG)."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "frontend_bucket_name" {
  description = "The name of the Cloud Storage bucket for the frontend."
  type        = string
}

variable "cost_api_function_name" {
  description = "The name of the Cost API Cloud Function for the serverless NEG."
  type        = string
}
