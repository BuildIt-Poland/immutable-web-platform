provider "aws" {
  region = "${var.region}"
}

module "backend" {
  source = "./modules/backend"

  bucket         = "${var.tf_state_bucket}"
  dynamodb_table = "${var.tf_state_table}"
  key            = "${var.tf_state_path}"
  common_tags    = "${local.common_tags}"
}

module "secrets" {
  source = "./modules/secrets"

  common_tags  = "${local.common_tags}"
  project_name = "${var.project_name}"
  env          = "${var.env}"
}

module "worker-build-cache" {
  source = "./modules/worker-build-cache"

  bucket       = "${var.worker_bucket}"
  common_tags  = "${local.common_tags}"
  project_name = "${var.project_name}"
  env          = "${var.env}"
}

module "nixos-instance" {
  source              = "./modules/nixos"
  common_tags         = "${local.common_tags}"
  ssh_pub_key         = "~/.ssh/id_rsa.pub"
  project_name        = "${var.project_name}"
  env                 = "${var.env}"
  nixos_configuration = "${path.module}/nixos/ec2-nixos.nix"
  region              = "${var.region}"
}
