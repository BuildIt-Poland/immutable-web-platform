resource "aws_subnet" "subnet" {
  cidr_block        = "${cidrsubnet(aws_vpc.local-env.cidr_block, 3, 1)}"
  vpc_id            = "${aws_vpc.local-env.id}"
  availability_zone = "eu-west-2a"
  tags              = "${var.common_tags}"
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
  subnet_id      = "${aws_subnet.subnet.id}"
  route_table_id = "${aws_route_table.route-table-test-env.id}"
}
