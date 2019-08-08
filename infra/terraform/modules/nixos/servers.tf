resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("${var.ssh_pub_key}")
}

resource "aws_instance" "nixos_instance" {
  ami             = "ami-03a40fd3a02fe95ba"
  instance_type   = "t2.micro"
  key_name        = "${aws_key_pair.deployer.key_name}"
  security_groups = ["${aws_security_group.ingress.id}"]
  subnet_id       = "${aws_subnet.subnet.id}"

  tags = "${merge(
    var.common_tags,
    map(
      "Name", "NixOS instance"
    )
  )}"
}
