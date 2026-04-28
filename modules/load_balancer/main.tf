# modules/load_balancer/main.tf
#
# Creates a Global HTTP(S) Load Balancer with:
#   - Backend Bucket (Cloud CDN) for static frontend assets
#   - Serverless NEG for Cloud Functions API
#   - URL Map routing: /costs → Cloud Function, /* → Frontend
#   - Static IP address for DNS

# ──────────────────────────────────────────────
#  Static External IP Address
# ──────────────────────────────────────────────
resource "google_compute_global_address" "default" {
  project = var.project_id
  name    = "${var.name_prefix}-lb-ip"
}

# ──────────────────────────────────────────────
#  Backend Bucket — Static Frontend (Cloud CDN)
# ──────────────────────────────────────────────
resource "google_compute_backend_bucket" "frontend" {
  project     = var.project_id
  name        = "${var.name_prefix}-frontend-backend"
  bucket_name = var.frontend_bucket_name
  enable_cdn  = true

  cdn_policy {
    cache_mode                   = "CACHE_ALL_STATIC"
    default_ttl                  = 3600
    max_ttl                      = 86400
    client_ttl                   = 3600
    negative_caching             = true
    serve_while_stale            = 86400
    signed_url_cache_max_age_sec = 0
  }
}

# ──────────────────────────────────────────────
#  Serverless NEG — Cloud Functions API
# ──────────────────────────────────────────────
resource "google_compute_region_network_endpoint_group" "cost_api_neg" {
  project               = var.project_id
  name                  = "${var.name_prefix}-cost-api-neg"
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_function {
    function = var.cost_api_function_name
  }
}

resource "google_compute_backend_service" "cost_api" {
  project     = var.project_id
  name        = "${var.name_prefix}-cost-api-backend"
  protocol    = "HTTPS"
  timeout_sec = 30

  backend {
    group = google_compute_region_network_endpoint_group.cost_api_neg.id
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# ──────────────────────────────────────────────
#  URL Map — Route /costs to API, everything else to frontend
# ──────────────────────────────────────────────
resource "google_compute_url_map" "default" {
  project         = var.project_id
  name            = "${var.name_prefix}-url-map"
  default_service = google_compute_backend_bucket.frontend.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "all-paths"
  }

  path_matcher {
    name            = "all-paths"
    default_service = google_compute_backend_bucket.frontend.id

    path_rule {
      paths   = ["/costs", "/costs/*"]
      service = google_compute_backend_service.cost_api.id
    }
  }
}

# ──────────────────────────────────────────────
#  HTTP Proxy + Forwarding Rule
# ──────────────────────────────────────────────
resource "google_compute_target_http_proxy" "default" {
  project = var.project_id
  name    = "${var.name_prefix}-http-proxy"
  url_map = google_compute_url_map.default.id
}

resource "google_compute_global_forwarding_rule" "http" {
  project    = var.project_id
  name       = "${var.name_prefix}-http-forwarding"
  target     = google_compute_target_http_proxy.default.id
  ip_address = google_compute_global_address.default.address
  port_range = "80"
}
