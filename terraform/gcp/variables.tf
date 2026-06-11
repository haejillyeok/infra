variable "project_id" {
  type        = string
  description = "GCP project ID."
}

variable "project" {
  type    = string
  default = "haejillyeok"
}

variable "region" {
  type    = string
  default = "us-west1"
}

variable "zone" {
  type    = string
  default = "us-west1-a"
}

variable "app_subnet_cidr" {
  type    = string
  default = "10.20.1.0/24"
}

variable "private_service_cidr_prefix_length" {
  type    = number
  default = 16
}

variable "machine_type" {
  type        = string
  description = "Use a free-tier eligible machine type and region when possible."
  default     = "e2-micro"
}

variable "ubuntu_image_project" {
  type        = string
  description = "GCP public image project that publishes Ubuntu images."
  default     = "ubuntu-os-cloud"
}

variable "ubuntu_image_family" {
  type        = string
  description = "Ubuntu 26.04 LTS image family for GCP Compute Engine."
  default     = "ubuntu-2604-lts-amd64"
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

variable "ssh_public_key" {
  type        = string
  description = "Public SSH key for the default connection user. Keep real values in terraform.tfvars or TF_VAR_ssh_public_key."
  sensitive   = true
}

variable "deploy_username" {
  type    = string
  default = "deploy"
}

variable "deploy_ssh_public_key" {
  type        = string
  description = "Public SSH key for the deploy user."
  sensitive   = true
}

variable "agent_ssh_public_key" {
  type        = string
  description = "Optional public SSH key for the Agent to access the deploy user. Set from AGENT_SSH_KEY only when it contains a public key."
  sensitive   = true
  default     = ""
}

variable "boot_disk_size_gb" {
  type    = number
  default = 10
}

variable "database_version" {
  type    = string
  default = "POSTGRES_16"
}

variable "database_tier" {
  type        = string
  description = "Cloud SQL has no always-free DB tier; this is a small PostgreSQL tier for cost control."
  default     = "db-f1-micro"
}

variable "disk_size_gb" {
  type    = number
  default = 10
}

variable "db_username" {
  type        = string
  description = "Cloud SQL user name. Use TF_VAR_db_username or an untracked terraform.tfvars file."
  sensitive   = true
}

variable "db_password" {
  type        = string
  description = "Cloud SQL user password. Use TF_VAR_db_password or an untracked terraform.tfvars file."
  sensitive   = true
}
