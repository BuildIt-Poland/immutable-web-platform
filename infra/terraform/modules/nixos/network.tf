resource "aws_vpc" "local-env" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = "${merge(
    var.common_tags,
    map(
      "Name", "NixOS VPC instance"
    )
  )}"
}
