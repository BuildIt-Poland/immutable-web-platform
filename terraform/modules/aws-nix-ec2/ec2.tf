# separate module
module "aws_image_nixos" {
  source  = "github.com/tweag/terraform-nixos/aws_image_nixos"
  release = "latest"
}

resource "aws_key_pair" "instance" {
  key_name   = "${var.project_name}-${var.env}-key"
  public_key = file("${var.ssh_pub_key}")
}

resource "aws_instance" "nixos_instance" {
  ami           = module.aws_image_nixos.ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.instance.key_name
  # INFO: don't use security_groups will recreate an instance - https://github.com/hashicorp/terraform/issues/16235
  vpc_security_group_ids = var.security_groups_ids
  subnet_id              = var.subnet_id
  associate_public_ip_address = true

  tags = merge(
    var.common_tags,
    map(
      "Name", "nixos-${var.project_name}-ec2"
    )
  )
}
