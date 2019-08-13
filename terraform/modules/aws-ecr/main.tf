variable "common_tags" {
  type = "map"
}

variable "region" {}
variable "project_name" {}
variable "env" {}

resource "aws_ecr_repository" "docker-registry" {
  name = "${var.project_name}-${var.env}"
  tags = var.common_tags
}
