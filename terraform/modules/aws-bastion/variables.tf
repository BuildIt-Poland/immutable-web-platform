variable "ssh_pub_key" {}
variable "common_tags" {
  type = "map"
}

variable "project_name" {
  default = ""
}
variable "cluster_name" {
  default = ""
}

variable "vpc" {

}

variable "env" {
  default = ""
}

variable "region" {
  default = ""
}
