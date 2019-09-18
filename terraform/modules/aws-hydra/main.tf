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

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
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
  instance_type       = "t2.large"
}

# watcher
data "archive_file" "watcher" {
  type        = "zip"
  source_dir = dirname(var.nixos_configuration)
  output_path = "${path.module}/config.watcher.zip"
}

module "nixos-updater" {
  source = "../nixos-deploy"

  common_tags  = var.common_tags
  project_name = var.project_name
  env          = var.env
  region       = var.region

  watch = {
    # config_changes = sha1(file(var.nixos_configuration))
    dir_changes = data.archive_file.watcher.output_sha
  }

  nixos_configuration = var.nixos_configuration

  host                = module.aws-ec2-instance.instance.public_ip
  ssh_pub_key         = module.aws-ec2-instance.key.key_name # var.ssh_pub_key
  # ssh_pub_key         = var.ssh_pub_key
}
