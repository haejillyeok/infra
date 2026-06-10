output "backend_config" {
  value = {
    bucket = google_storage_bucket.terraform_state.name
    prefix = "haejillyeok/gcp"
  }
}

