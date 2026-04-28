# .tflint.hcl — TFLint configuration for the GCP provider

config {
  force = false
}

plugin "google" {
  enabled = true
  version = "0.30.0"
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}
