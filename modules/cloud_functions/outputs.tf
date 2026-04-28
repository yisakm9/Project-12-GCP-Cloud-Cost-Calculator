# modules/cloud_functions/outputs.tf

output "cost_api_function_url" {
  description = "The HTTPS URL of the Cost API Cloud Function."
  value       = google_cloudfunctions2_function.cost_api.service_config[0].uri
}

output "cost_api_function_name" {
  description = "The name of the Cost API Cloud Function."
  value       = google_cloudfunctions2_function.cost_api.name
}

output "cost_report_function_name" {
  description = "The name of the Cost Report Cloud Function."
  value       = google_cloudfunctions2_function.cost_report.name
}

output "source_bucket_name" {
  description = "The name of the function source staging bucket."
  value       = google_storage_bucket.function_source.name
}
