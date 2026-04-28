# modules/scheduler/outputs.tf

output "scheduler_job_name" {
  description = "The name of the Cloud Scheduler job."
  value       = google_cloud_scheduler_job.weekly_report.name
}

output "scheduler_job_id" {
  description = "The ID of the Cloud Scheduler job."
  value       = google_cloud_scheduler_job.weekly_report.id
}
