# modules/apis/main.tf
#
# Enables all required Google Cloud APIs for the project.
# This module should be applied first, as all other resources depend on these APIs.

resource "google_project_service" "required_apis" {
  for_each = toset(var.apis)

  project = var.project_id
  service = each.value

  # Do not disable the API when the resource is destroyed.
  # This prevents accidental disruption if resources still depend on it.
  disable_dependent_services = false
  disable_on_destroy         = false
}
