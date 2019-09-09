# separate module
module "aws_image_nixos" {
  source  = "github.com/tweag/terraform-nixos/aws_image_nixos"
  release = "latest"
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-${var.env}-key"
  public_key = file("${var.ssh_pub_key}")
}

resource "aws_eip" "nixos_instance_ip" {
  vpc      = true
  tags     = var.common_tags
  instance = aws_instance.nixos_instance.id
}

resource "aws_instance" "nixos_instance" {
  ami           = module.aws_image_nixos.ami
  instance_type = "t2.micro"
  key_name      = "${aws_key_pair.deployer.key_name}"
  # INFO: don't use security_groups will recreate an instance - https://github.com/hashicorp/terraform/issues/16235
  vpc_security_group_ids = "${var.security_groups_ids}"
  subnet_id              = "${var.subnet_id}"

  tags = "${merge(
    var.common_tags,
    map(
      "Name", "nixos-${var.project_name}-ec2"
    )
  )}"
}
