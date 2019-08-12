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

variable "security_groups_ids" {
  default = []
}

variable "subnet_id" {
  default = ""
}

data "aws_availability_zones" "available" {
  state = "available"
}
