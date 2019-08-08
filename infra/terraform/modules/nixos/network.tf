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

resource "aws_eip" "ip-test-env" {
  instance = "${aws_instance.nixos_instance.id}"
  vpc      = true
  tags     = "${var.common_tags}"
}
