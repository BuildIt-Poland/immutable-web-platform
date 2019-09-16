locals {
  azs = data.aws_availability_zones.available.names

  nixos_configuration = "${var.root_folder}/nix/nixos/hydra.nix"

  common_tags = map(
    "Owner", var.owner,
    "Project Name", var.project_name,
    "Env", var.env
  )
}

data "aws_availability_zones" "available" {
  state = "available"
}

variable "bootstrap" {
  default = false
}

variable "ssh_pub_key" {
  default = "~/.ssh/id_rsa.pub"
}
