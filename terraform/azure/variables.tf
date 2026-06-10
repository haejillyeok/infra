variable "project" {
  type    = string
  default = "haejillyeok"
}

variable "location" {
  description = "Location for Azure workload resources such as VNet, VM, Public IP, and PostgreSQL."
  type        = string
  default     = "koreacentral"
}

variable "resource_group_location" {
  description = "Location metadata for the existing terraform resource group."
  type        = string
  default     = "koreasouth"
}

variable "resource_group_name" {
  type    = string
  default = "terraform"
}

variable "vnet_cidr" {
  type    = string
  default = "10.30.0.0/16"
}

variable "vm_subnet_cidr" {
  type    = string
  default = "10.30.1.0/24"
}

variable "db_subnet_cidr" {
  type    = string
  default = "10.30.11.0/24"
}

variable "vm_size" {
  type        = string
  description = "Azure VM size for the selected workload location."
  default     = "Standard_B2als_v2"
}

variable "admin_username" {
  type    = string
  default = "ubuntu"
}

variable "ssh_public_key" {
  type        = string
  description = "RSA public SSH key for the default connection user. Azure VM admin_ssh_key does not accept ed25519."
  sensitive   = true
}

variable "deploy_username" {
  type    = string
  default = "deploy"
}

variable "deploy_ssh_public_key" {
  type        = string
  description = "Public SSH key for the deploy user. Use RSA to keep Azure setup consistent."
  sensitive   = true
}

variable "os_disk_size_gb" {
  type    = number
  default = 30
}

variable "ubuntu_image_publisher" {
  type    = string
  default = "Canonical"
}

variable "ubuntu_image_offer" {
  type        = string
  description = "Azure Ubuntu 26.04 LTS image offer."
  default     = "ubuntu-26_04-lts"
}

variable "ubuntu_image_sku" {
  type        = string
  description = "Azure Ubuntu 26.04 LTS image SKU."
  default     = "server"
}

variable "ubuntu_image_version" {
  type    = string
  default = "latest"
}

variable "postgres_version" {
  type    = string
  default = "16"
}

variable "postgres_server_name" {
  type    = string
  default = "haejillyeok-postgresql"
}

variable "postgres_zone" {
  type    = string
  default = "1"
}

variable "postgres_sku_name" {
  type        = string
  description = "Azure PostgreSQL Flexible Server SKU for the selected workload location."
  default     = "B_Standard_B1ms"
}

variable "postgres_storage_mb" {
  type    = number
  default = 32768
}

variable "db_username" {
  type        = string
  description = "PostgreSQL administrator username. Use TF_VAR_db_username or an untracked terraform.tfvars file."
  sensitive   = true
}

variable "db_password" {
  type        = string
  description = "PostgreSQL administrator password. Use TF_VAR_db_password or an untracked terraform.tfvars file."
  sensitive   = true
}
