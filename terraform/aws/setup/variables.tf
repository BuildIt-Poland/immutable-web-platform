locals {
  common_tags = map(
    "Owner", var.owner,
    "Project Name", var.project_name,
    "Env", var.env
  )
}

data "aws_availability_zones" "available" {
  state = "available"
}

variable "ssh_pub_key" {
  default = "~/.ssh/id_rsa.pub"
}
