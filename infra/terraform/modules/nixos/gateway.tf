resource "aws_internet_gateway" "test-env-gw" {
  vpc_id = "${aws_vpc.local-env.id}"
  tags   = "${var.common_tags}"
}
