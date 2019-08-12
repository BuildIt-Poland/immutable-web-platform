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

variable "folder_to_watch" {
  default = "./nixos"
}

variable "user" {
  default = "root"
}


variable "host" {
  default     = ""
  description = ""
}
