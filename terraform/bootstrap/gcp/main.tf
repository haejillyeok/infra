provider "google" {
  project = var.project_id
}

locals {
  labels = {
    project    = var.project
    managed_by = "terraform"
    purpose    = "terraform-state"
  }

  required_services = toset([
    "storage.googleapis.com"
  ])
}

resource "google_project_service" "required" {
  for_each = local.required_services

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_storage_bucket" "terraform_state" {
  name                        = var.state_bucket_name
  project                     = var.project_id
  location                    = var.location
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  labels                      = local.labels

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.required]
}
