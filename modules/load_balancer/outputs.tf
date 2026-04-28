# modules/load_balancer/outputs.tf

output "load_balancer_ip" {
  description = "The static external IP address of the Load Balancer."
  value       = google_compute_global_address.default.address
}

output "dashboard_url" {
  description = "The HTTP URL for the cost dashboard."
  value       = "http://${google_compute_global_address.default.address}"
}

output "url_map_id" {
  description = "The ID of the URL map."
  value       = google_compute_url_map.default.id
}
