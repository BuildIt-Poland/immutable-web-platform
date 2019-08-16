
provider "aws" {
  region = var.region
}

data "terraform_remote_state" "state" {
  backend = "s3"
  config = {
    key    = "${var.project_prefix}/setup"
    region = var.region
    bucket = var.tf_state_bucket
  }
}

module "secrets" {
  source = "../../modules/secrets"

  common_tags  = local.common_tags
  project_name = var.project_name
  env          = var.env
}

module "worker-build-cache" {
  source = "../../modules/worker-build-cache"

  bucket       = var.worker_bucket
  project_name = var.project_name
  env          = var.env
  common_tags  = local.common_tags
}

module "docker-registry" {
  source = "../../modules/aws-ecr"

  # Has to be aligned with nix/shell-modules/eks-cluster.nix -> docker.namespace
  cluster_name = var.cluster_name
  region       = var.region
  common_tags  = local.common_tags
}

output "state" {
  value = data.terraform_remote_state.state.outputs
}
