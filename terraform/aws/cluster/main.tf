provider "aws" {
  region = var.region
}

data "terraform_remote_state" "state" {
  backend = "s3"
  config = {
    key    = "${var.project_prefix}/cluster"
    region = var.region
    bucket = var.tf_state_bucket
  }
}

module "docker-registry" {
  source = "../../modules/aws-ecr"

  project_name = var.project_name
  env          = var.env
  region       = var.region
  common_tags  = local.common_tags
}

module "cluster" {
  source = "../../modules/aws-eks-cluster"

  project_name = var.project_name
  env          = var.env
  region       = var.region
  common_tags  = local.common_tags

  cluster_name = "${var.cluster_name}"

  azs = local.azs

  worker_groups = [
    {
      autoscaling_enabled  = "true"
      instance_type        = "m4.xlarge"
      asg_max_size         = 4
      asg_desired_capacity = 2
      bootstrap_extra_args = "--enable-docker-bridge true"
      # kubelet_extra_args   = "--node-labels=xxx=xxxx"
    },
  ]

  map_users = var.map_users
  map_roles = var.map_roles
}
