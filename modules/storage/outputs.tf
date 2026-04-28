# modules/storage/outputs.tf

output "bucket_name" {
  description = "The name of the frontend storage bucket."
  value       = google_storage_bucket.frontend.name
}

output "bucket_url" {
  description = "The URL of the frontend storage bucket."
  value       = google_storage_bucket.frontend.url
}

output "bucket_self_link" {
  description = "The self link of the frontend storage bucket."
  value       = google_storage_bucket.frontend.self_link
}
