variable "common_tags" {
  type = "map"
}

variable "region" {}
variable "cluster_name" {}

resource "aws_ecr_repository" "docker-registry" {
  name = var.cluster_name
  tags = var.common_tags
}
