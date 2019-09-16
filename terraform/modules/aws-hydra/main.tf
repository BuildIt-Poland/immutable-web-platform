resource "aws_security_group" "hydra-sg" {
  name   = "${var.cluster_name}-hydra-security-group"
  vpc_id = var.vpc.vpc_id

  # ssh  
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  # hydra
  ingress {
    protocol    = "tcp"
    from_port   = var.port
    to_port     = var.port
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.common_tags
}

resource "random_integer" "subnet" {
  min     = 0
  max     = length(var.vpc.public_subnets) - 1
}

module "aws-ec2-instance" {
  source = "../aws-nix-ec2"

  common_tags  = var.common_tags
  project_name = var.project_name
  env          = var.env
  region       = var.region


  security_groups_ids = [aws_security_group.hydra-sg.id]
  subnet_id           = var.vpc.public_subnets[random_integer.subnet.result]
  ssh_pub_key         = var.ssh_pub_key
}

module "nixos-updater" {
  source = "../nixos-deploy"

  common_tags  = var.common_tags
  project_name = var.project_name
  env          = var.env
  region       = var.region

  host                = module.aws-ec2-instance.instance_ip
  nixos_configuration = "${var.root_folder}/nix/nixos/hydra.nix"
  ssh_pub_key         = var.ssh_pub_key
}
