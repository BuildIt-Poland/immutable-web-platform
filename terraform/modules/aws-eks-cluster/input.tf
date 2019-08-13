variable "common_tags" {
  type = "map"
}

variable "region" {}
variable "project_name" {}
variable "env" {}
variable "worker_groups" {}
variable "azs" {}
variable "cluster_name" {}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type        = list(map(string))
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type        = list(map(string))
}
