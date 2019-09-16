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

variable "user" {
  default = "root"
}

variable "host" {
  default     = ""
  description = ""
}

variable "watch" {
  default = {}
}

variable "nixos_configuration" {}
