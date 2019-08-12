variable "project_name" {
  default = ""
}

variable "region" {
  default     = ""
  description = "AWS Region"
}

variable "env" {
  default = ""
}

variable "owner" {
  default = ""
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
  env-vars = {
    region          = var.region
    tf_state_bucket = var.tf_state_bucket
    tf_state_table  = var.tf_state_table
    tf_state_path   = var.tf_state_path
    env             = var.env
    owner           = var.owner
    worker_bucket   = var.worker_bucket
    project_name    = var.project_name
  }

  common_tags = map(
    "Owner", var.owner,
    "Project Name", var.project_name,
    "Env", var.env
  )
}
