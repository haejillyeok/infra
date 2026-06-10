variable "project" {
  type    = string
  default = "haejillyeok"
}

variable "location" {
  type    = string
  default = "koreacentral"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name for Terraform state storage."
  default     = "terraform"
}

variable "storage_account_name" {
  type        = string
  description = "Globally unique Azure Storage Account name. Use lowercase letters and numbers only."
  default     = "haejillyeokstate"
}

variable "container_name" {
  type    = string
  default = "tfstate"
}
