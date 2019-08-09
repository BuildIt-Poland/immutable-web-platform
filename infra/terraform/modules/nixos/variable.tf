variable "ssh_pub_key" {}
variable "common_tags" {
  type = "map"
}

variable "project_name" {
  default = ""
}

variable "env" {
  default = ""
}

variable "region" {
  default = ""
}

variable "nixos_configuration" {
  default = ""
}


data "aws_availability_zones" "available" {
  state = "available"
}
