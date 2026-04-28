# modules/scheduler/variables.tf

variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The region for Cloud Scheduler."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "pubsub_topic_id" {
  description = "The fully-qualified ID of the Pub/Sub topic to publish to."
  type        = string
}

variable "schedule" {
  description = "Cron expression for the schedule (Cloud Scheduler format)."
  type        = string
  default     = "0 9 * * 1" # Every Monday at 9:00 AM UTC
}

variable "time_zone" {
  description = "Time zone for the schedule."
  type        = string
  default     = "UTC"
}
