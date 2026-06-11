variable "project" {
  type    = string
  default = "haejillyeok"
}

variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.10.1.0/24"
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.10.11.0/24", "10.10.12.0/24"]
}

variable "availability_zones" {
  type    = list(string)
  default = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "instance_type" {
  type        = string
  description = "Use a free-tier eligible instance type for the target account and region."
  default     = "t3.micro"
}

variable "ubuntu_ami_ssm_parameter" {
  type        = string
  description = "Canonical public SSM parameter for the latest Ubuntu 26.04 LTS server AMI."
  default     = "/aws/service/canonical/ubuntu/server/26.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

variable "ssh_public_key" {
  type        = string
  description = "Public SSH key for the default connection user."
  sensitive   = true
}

variable "ssh_username" {
  type        = string
  description = "Default SSH user for the Ubuntu EC2 AMI."
  default     = "ubuntu"
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

variable "root_volume_size" {
  type    = number
  default = 8
}

variable "db_username" {
  type        = string
  description = "RDS master username. Use TF_VAR_db_username or an untracked terraform.tfvars file."
  sensitive   = true
}

variable "db_password" {
  type        = string
  description = "RDS master password. Use TF_VAR_db_password or an untracked terraform.tfvars file."
  sensitive   = true
}

variable "postgres_major_version" {
  type    = string
  default = "16"
}

variable "db_instance_class" {
  type        = string
  description = "Use a free-tier eligible RDS class for the target account and region."
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}
