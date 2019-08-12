
provider "aws" {
  region = local.env-vars.region
}

module "backend" {
  source      = "./modules/backend"
  region      = local.env-vars.region
  bucket      = local.env-vars.tf_state_bucket
  dynamo_db   = local.env-vars.tf_state_table
  state_path  = local.env-vars.tf_state_path
  common_tags = local.common_tags
}

data "terraform_remote_state" "state" {
  backend = "s3"
  config = {
    bucket = local.env-vars.tf_state_bucket
    key    = local.env-vars.tf_state_path
    region = local.env-vars.region
  }
}

module "secrets" {
  source = "./modules/secrets"

  common_tags  = local.common_tags
  project_name = var.project_name
  env          = var.env
}

module "worker-build-cache" {
  source = "./modules/worker-build-cache"

  bucket       = local.env-vars.worker_bucket
  project_name = local.env-vars.project_name
  env          = local.env-vars.env
  common_tags  = local.common_tags
}

module "aws-ec2-network" {
  source       = "./modules/aws-network"
  common_tags  = local.common_tags
  project_name = local.env-vars.project_name
  env          = local.env-vars.env
  region       = local.env-vars.region

  ssh_pub_key = var.ssh_pub_key
}

module "aws-ec2-instances" {
  source = "./modules/aws-ec2"

  common_tags  = local.common_tags
  project_name = local.env-vars.project_name
  env          = local.env-vars.env
  region       = local.env-vars.region


  security_groups_ids = data.terraform_remote_state.state.outputs.aws_security_groups_ids
  subnet_id           = module.aws-ec2-network.subnet_id
  ssh_pub_key         = var.ssh_pub_key
}

module "nixos-updater" {
  source = "./modules/nixos-deploy"

  common_tags  = local.common_tags
  project_name = local.env-vars.project_name
  env          = local.env-vars.env
  region       = local.env-vars.region

  host                = module.aws-ec2-instances.instance_ip
  nixos_configuration = "${path.module}/nixos/ec2-nixos.nix"
  ssh_pub_key         = var.ssh_pub_key
}

locals {
  azs = data.aws_availability_zones.available.names
}

module "cluster" {
  source = "./modules/eks-cluster"

  common_tags  = local.common_tags
  project_name = local.env-vars.project_name
  env          = local.env-vars.env
  region       = local.env-vars.region

  cluster_name = "${local.env-vars.project_name}-${local.env-vars.env}"

  azs = local.azs

  worker_groups = [
    {
      instance_type        = "m4.large"
      asg_max_size         = 2
      asg_desired_capacity = 1
    }
  ]

  # map_users = var.map_users
  # map_roles = var.map_roles
}
