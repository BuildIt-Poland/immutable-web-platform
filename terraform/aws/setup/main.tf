
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

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.6.0"

  name                 = "${var.cluster_name}-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = local.azs
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = local.common_tags

  vpc_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

# to refresh - terraform taint tls_private_key.hydra-token
resource "tls_private_key" "hydra-token" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

module "hydra" {
  source      = "../../modules/aws-hydra"
  common_tags = local.common_tags
  vpc = module.vpc
  project_name = var.project_name
  env          = var.env
  region       = var.region
  cluster_name = var.cluster_name
  ssh_pub_key  = var.ssh_pub_key

  port = 3000
  nixos_configuration = local.nixos_configuration
  # TODO
  worker_ssh_key = tls_private_key.hydra-token.public_key_openssh
}