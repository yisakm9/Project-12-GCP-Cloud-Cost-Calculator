# modules/iam/outputs.tf

output "cost_api_sa_email" {
  description = "Email of the Cost API service account."
  value       = google_service_account.cost_api_sa.email
}

output "cost_report_sa_email" {
  description = "Email of the Cost Report service account."
  value       = google_service_account.cost_report_sa.email
}

output "cost_api_sa_id" {
  description = "Fully qualified ID of the Cost API service account."
  value       = google_service_account.cost_api_sa.id
}

output "cost_report_sa_id" {
  description = "Fully qualified ID of the Cost Report service account."
  value       = google_service_account.cost_report_sa.id
}
