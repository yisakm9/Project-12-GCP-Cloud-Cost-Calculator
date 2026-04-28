# modules/kms/main.tf
#
# Creates a Cloud KMS keyring and crypto key for encrypting
# sensitive data (Secret Manager secrets, Cloud Function env vars).

resource "google_kms_key_ring" "this" {
  project  = var.project_id
  name     = "${var.name_prefix}-keyring"
  location = var.region
}

resource "google_kms_crypto_key" "this" {
  name     = "${var.name_prefix}-key"
  key_ring = google_kms_key_ring.this.id

  # Rotate keys automatically every 90 days
  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = false
  }

  labels = var.labels
}
