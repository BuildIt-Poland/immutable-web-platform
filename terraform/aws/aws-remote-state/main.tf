provider "aws" {
  region = var.region
}

locals {
  common_tags = map(
    "Owner", var.owner,
    "Project Name", var.project_name,
    "Env", var.env
  )
}

module "backend" {
  source      = "../../modules/aws-backend"
  region      = var.region
  bucket      = var.tf_state_bucket
  dynamo_db   = var.tf_state_table
  common_tags = local.common_tags
}


