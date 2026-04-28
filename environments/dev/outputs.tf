# environments/dev/outputs.tf

output "dashboard_url" {
  description = "The URL for the Cloud Cost Calculator dashboard."
  value       = module.load_balancer.dashboard_url
}

output "load_balancer_ip" {
  description = "The static external IP address of the Load Balancer."
  value       = module.load_balancer.load_balancer_ip
}

output "cost_api_function_url" {
  description = "The direct HTTPS URL of the Cost API Cloud Function."
  value       = module.cloud_functions.cost_api_function_url
}

output "frontend_bucket_name" {
  description = "The name of the Cloud Storage bucket for the frontend."
  value       = module.storage.bucket_name
}

output "scheduler_job_name" {
  description = "The name of the Cloud Scheduler job for weekly reports."
  value       = module.scheduler.scheduler_job_name
}

output "budget_name" {
  description = "The name of the billing budget."
  value       = module.monitoring.budget_name
}
