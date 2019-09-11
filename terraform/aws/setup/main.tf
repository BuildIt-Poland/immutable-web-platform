
provider "aws" {
  region = var.region
}

data "terraform_remote_state" "state" {
  count   = var.bootstrap ? 0 : 1
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
  root_folder  = var.root_folder
  domain       = var.domain
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

  # INFO has to be aligned with nix/integration-modules/eks-cluster.nix -> docker.namespace
  cluster_name = var.cluster_name
  region       = var.region
  common_tags  = local.common_tags
}

# TODO move this to setup
# https://velero.io/docs/v1.0.0/aws-config/
module "backup" {
  source      = "../../modules/backup"
  bucket_name = var.backup_bucket
  common_tags = local.common_tags
}
