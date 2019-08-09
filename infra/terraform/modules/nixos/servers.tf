resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-${var.env}-deployer-key"
  public_key = file("${var.ssh_pub_key}")
}

resource "aws_eip" "nixos_instance_ip" {
  vpc      = true
  tags     = "${var.common_tags}"
  instance = "${aws_instance.nixos_instance.id}"
}

# TODO move to separate module
data "archive_file" "init" {
  type        = "zip"
  output_path = "terraform.zip"
  source_dir  = "./nixos"
}

resource "null_resource" "provision-builder" {
  triggers = {
    src_hash = "${data.archive_file.init.output_sha}"
  }

  provisioner "local-exec" {
    command = "echo 'Refreshing configuration'"
  }
}

data "external" "nixos-build" {
  program = ["${path.module}/build-nix.sh", "${var.nixos_configuration}"]

  depends_on = [
    aws_instance.nixos_instance,
    null_resource.provision-builder
  ]
}

locals {
  triggers = {
    instances_id = "${join(",", [aws_instance.nixos_instance.id])}"
    data         = "${join(",", [data.external.nixos-build.id])}"
  }
}
resource "null_resource" "bootstrap" {
  triggers = "${local.triggers}"

  depends_on = [
    data.external.nixos-build,
    aws_instance.nixos_instance
  ]

  connection {
    type  = "ssh"
    host  = "${aws_eip.nixos_instance_ip.public_ip}"
    user  = "root"
    agent = true
  }
  # will wait for ssh
  provisioner "file" {
    content     = "${jsonencode(data.external.nixos-build.result)}"
    destination = "/tmp/build-result.json"
  }

  provisioner "local-exec" {
    command = <<EXEC
      ${path.module}/copy-nix.sh "${data.external.nixos-build.result["hash"]}" "${aws_eip.nixos_instance_ip.public_ip}"
    EXEC
  }
}

resource "aws_instance" "nixos_instance" {
  ami = "${module.aws_image_nixos.ami}"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.deployer.key_name}"
  security_groups = ["${aws_security_group.ingress.id}"]
  subnet_id = "${aws_subnet.public.id}"

  lifecycle {
    # prevent_destroy = true
    # create_before_destroy = true
    # ignore_changes = [
    #   tags,
    # ]
  }

  tags = "${merge(
    var.common_tags,
    map(
      "Name", "nixos-${var.project_name}-ec2"
    )
  )}"
}
