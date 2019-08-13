# TODO make module
resource "aws_internet_gateway" "test-env-gw" {
  vpc_id = "${aws_vpc.local-env.id}"
  tags   = "${var.common_tags}"
}

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

resource "aws_subnet" "public" {
  map_public_ip_on_launch = true
  cidr_block              = "${cidrsubnet(aws_vpc.local-env.cidr_block, 3, 1)}"
  vpc_id                  = "${aws_vpc.local-env.id}"
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"
  tags                    = "${var.common_tags}"
}

resource "aws_route_table" "route-table-test-env" {
  vpc_id = "${aws_vpc.local-env.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.test-env-gw.id}"
  }
  tags = "${var.common_tags}"
}

resource "aws_route_table_association" "subnet-association" {
  subnet_id      = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.route-table-test-env.id}"
}

resource "aws_security_group" "ingress" {
  name   = "allow-all-sg"
  vpc_id = "${aws_vpc.local-env.id}"
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }
  // Terraform removes the default rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = "${var.common_tags}"
}
