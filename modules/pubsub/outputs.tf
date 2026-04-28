# modules/pubsub/outputs.tf

output "report_trigger_topic_name" {
  description = "The name of the report trigger Pub/Sub topic."
  value       = google_pubsub_topic.report_trigger.name
}

output "report_trigger_topic_id" {
  description = "The ID of the report trigger Pub/Sub topic."
  value       = google_pubsub_topic.report_trigger.id
}

output "budget_alerts_topic_name" {
  description = "The name of the budget alerts Pub/Sub topic."
  value       = google_pubsub_topic.budget_alerts.name
}

output "budget_alerts_topic_id" {
  description = "The ID of the budget alerts Pub/Sub topic."
  value       = google_pubsub_topic.budget_alerts.id
}
