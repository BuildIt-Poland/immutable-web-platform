# only for dev!
resource "tls_private_key" "hydra-token" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.hydra-token.public_key_openssh
}

module "aws-ec2-network" {
  source       = "./modules/aws-network"
  common_tags  = local.common_tags
  project_name = var.project_name
  env          = var.env
  region       = var.region

  ssh_pub_key = var.ssh_pub_key
}

module "aws-ec2-instances" {
  source = "./modules/aws-ec2"

  common_tags  = local.common_tags
  project_name = var.project_name
  env          = var.env
  region       = var.region


  security_groups_ids = module.aws-ec2-network.security_groups_ids
  subnet_id           = module.aws-ec2-network.subnet_id
  ssh_pub_key         = var.ssh_pub_key
}

module "nixos-updater" {
  source = "./modules/nixos-deploy"

  common_tags  = local.common_tags
  project_name = var.project_name
  env          = var.env
  region       = var.region

  host                = module.aws-ec2-instances.instance_ip
  nixos_configuration = "${var.root_folder}/nix/nixos/hydra.nix"
  ssh_pub_key         = var.ssh_pub_key
}

