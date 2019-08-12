
data "aws_availability_zones" "available" {
  state = "available"
}

variable "ssh_pub_key" {
  default = "~/.ssh/id_rsa.pub"
}
