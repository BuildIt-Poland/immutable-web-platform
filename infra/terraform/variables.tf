# WRAP terraform and provide these values from nix
# populated from ./nix/terraform
variable "project_name" {
  default = ""
}

variable "region" {
  default = ""
}

variable "env" {
  default = ""
}

variable "owner" {
  default     = ""
  description = "AWS Region"
}

variable "worker_bucket" {
  default = ""
}

# REMOTE STATE
variable "tf_state_bucket" {
  default     = ""
  description = "AWS S3 Bucket name for Terraform state"
}

variable "tf_state_table" {
  default     = ""
  description = "AWS DynamoDB table for state locking"
}
variable "tf_state_path" {
  default     = ""
  description = "Key for Terraform state at S3 bucket"
}

locals {
  common_tags = {
    Owner = "${var.owner}"
  }
}
