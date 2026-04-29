# modules/storage/main.tf
#
# Creates a Cloud Storage bucket for hosting the static frontend.
# Configured with uniform bucket-level access and CORS for API calls.

resource "google_storage_bucket" "frontend" {
  project  = var.project_id
  name     = "${var.name_prefix}-dashboard-${var.suffix}"
  location = var.region

  # Uniform bucket-level access (no legacy ACLs)
  uniform_bucket_level_access = true

  # Enable versioning for rollback capability
  versioning {
    enabled = true
  }

  # Serve index.html when root URL is requested
  website {
    main_page_suffix = "index.html"
    not_found_page   = "index.html"
  }

  # CORS configuration for API calls from the frontend
  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD"]
    response_header = ["Content-Type"]
    max_age_seconds = 3600
  }

  # Force destroy for clean teardown (dev environment)
  force_destroy = true

  labels = var.labels
}

# Make the bucket objects publicly readable via IAM
# (required for serving static content via LB backend bucket)
resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.frontend.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
