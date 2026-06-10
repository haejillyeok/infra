variable "project" {
  type    = string
  default = "haejillyeok"
}

variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "state_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for Terraform state."
  default     = "haejillyeok-terraform-state-aws"
}
