variable common_tags {
  type = "map"
}

variable region {}
variable project_name {}
variable env {}
variable cluster_name {}
variable base_domain {}
variable domain {}

variable vpc {}
variable ssh_pub_key {}

# variable worker_ssh_key {}
variable port {}

variable "nixos_configuration" {}
variable "app_name" {
  default = "hydra"
}
