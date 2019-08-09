resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("${var.ssh_pub_key}")
}

resource "aws_eip" "nixos_instance_ip" {
  vpc  = true
  tags = "${var.common_tags}"
  # instance = "${aws_instance.nixos_instance.id}"
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = "${aws_instance.nixos_instance.id}"
  allocation_id = "${aws_eip.nixos_instance_ip.id}"
}

# data "tls_public_key" "example" {
#   private_key_pem = "${file("~/.ssh/id_rsa")}"
# }

data "external" "nixos" {
  program = ["${path.module}/build-nix.sh", "${var.nixos_configuration}"]
}

resource "null_resource" "nixos_instance" {
  triggers = {
    instances_id = "${join(",", [aws_instance.nixos_instance.id])}"
  }

  depends_on = [
    data.external.nixos,
    aws_eip_association.eip_assoc,
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
    content     = "${jsonencode(data.external.nixos.result)}"
    destination = "/tmp/build-result.json"
  }

  provisioner "local-exec" {
    command = <<EXEC
      echo "cool"
    EXEC
  }

  provisioner "remote-exec" {
    inline = [
      "cat /tmp/build-result.json"
    ]
  }
}

resource "null_resource" "provision_nixos" {
  depends_on = [
    data.external.nixos,
    null_resource.nixos_instance
  ]

  provisioner "local-exec" {
    command = <<EXEC
      ${path.module}/copy-nix.sh \
        "${data.external.nixos.result["hash"]}" \
        "${aws_eip.nixos_instance_ip.public_ip}"
    EXEC
  }
}
# data "external" "copy-nixos" {

#   depends_on = [
#     data.external.nixos
#   ]

#   provisioner "local-exec" {
#     command = <<EXEC
#       build_hash="${data.external.nixos.result["hash"]}"
#       machine_ip=${aws_eip.nixos_instance_ip.public_ip}
#       NIX_SSHOPTS="-o StrictHostKeyChecking=no -o BatchMode=yes"
#       echo "Machine address: $machine_ip, build: $build_hash"

#       until [[ $(ssh $NIX_SSHOPTS -o ConnectTimeout=5 root@$machine_ip echo ok) ]] ; do
#         sleep 2
#         echo .
#       done
#       nix copy --to "ssh://root@$machine_ip" $build_hash
#     EXEC
#     # inline = [
#     #   "echo ${data.external.nixos.result["hash"]}"
#     # ]
#     # ssh root@$machine_ip "sudo $build_hash/bin/switch-to-configuration switch"""
#     # build_hash="${data.external.nixos.result["hash"]}"
#     # machine_ip=${aws_eip.nixos_instance_ip.public_ip}
#     # NIX_SSHOPTS="-o StrictHostKeyChecking=accept-new -o BatchMode=yes"
#     # echo "Machine address: $machine_ip, build: $build_hash"

#     # ssh_read=$(ssh -o BatchMode=yes -o ConnectTimeout=5 root@$machine_ip echo ok 2>&1)

#     # until [[ $status == ok ]] ; do
#     #   nix copy --to "ssh://root@$machine_ip" $build_hash
#     # done
# }

#   depends_on = [
#     # aws_eip.nixos_instance_ip,
#     aws_instance.nixos_instance
#     # aws_eip_association.eip_assoc
#   ]
# }

# TODO
# resource "aws_instance" "nodes" {
#   count = "${var.instance_count}"

# https://www.terraform.io/docs/provisioners/null_resource.html
# resource "aws_instance" "cluster" {
#   count = 3
#   # ...
# }

# module "deploy_nixos" {
#   # triggers = {
#   #   // Also re-deploy whenever the VM is re-created
#   #   instance_id = "${aws_instance.nixos_instance.id}"
#   # }
#   source       = "github.com/tweag/terraform-nixos/deploy_nixos"
#   nixos_config = "./nixos/configuration.nix"
#   target_host  = "${aws_eip.nixos_instance_ip.public_ip}"
#   target_user  = "root"
#   NIX_PATH     = "nixpkgs=/Users/damianbaar/.nix-defexpr/channels/nixpkgs"

#   keys = {
#     foo = "bar"
#   }
# }

resource "aws_instance" "nixos_instance" {
  ami             = "${module.aws_image_nixos.ami}"
  instance_type   = "t2.micro"
  key_name        = "${aws_key_pair.deployer.key_name}"
  security_groups = ["${aws_security_group.ingress.id}"]
  subnet_id       = "${aws_subnet.public.id}"

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
      "Name", "NixOS#${var.project_name}#ec2"
    )
  )}"
}
