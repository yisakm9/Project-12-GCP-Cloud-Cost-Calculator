# modules/kms/outputs.tf

output "key_id" {
  description = "The ID of the Cloud KMS crypto key."
  value       = google_kms_crypto_key.this.id
}

output "keyring_id" {
  description = "The ID of the Cloud KMS keyring."
  value       = google_kms_key_ring.this.id
}
