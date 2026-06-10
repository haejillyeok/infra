variable "project_id" {
  type        = string
  description = "GCP project ID that owns the Terraform state bucket."
}

variable "project" {
  type    = string
  default = "haejillyeok"
}

variable "location" {
  type    = string
  default = "ASIA-NORTHEAST3"
}

variable "state_bucket_name" {
  type        = string
  description = "Globally unique GCS bucket name for Terraform state."
  default     = "haejillyeok-terraform-state-gcp"
}
