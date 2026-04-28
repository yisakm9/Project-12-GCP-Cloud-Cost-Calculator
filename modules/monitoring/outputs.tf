# modules/monitoring/outputs.tf

output "notification_channel_id" {
  description = "The ID of the email notification channel."
  value       = google_monitoring_notification_channel.email.id
}

output "budget_name" {
  description = "The name of the billing budget."
  value       = google_billing_budget.monthly_budget.display_name
}

output "uptime_check_id" {
  description = "The ID of the dashboard uptime check."
  value       = google_monitoring_uptime_check_config.dashboard.uptime_check_id
}
