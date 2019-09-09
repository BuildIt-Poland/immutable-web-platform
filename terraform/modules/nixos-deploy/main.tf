data "external" "nixos-build" {
  program = ["${path.module}/build-nix.sh", "${var.nixos_configuration}"]
}

resource "null_resource" "bootstrap" {
  # TODO this should be configurable
  triggers = {
    config_changed = "${sha1(file("./nixos/configuration.nix"))}"
    image_changed  = "${sha1(file("./nixos/ec2-nixos.nix"))}"
  }

  depends_on = [
    data.external.nixos-build,
  ]

  connection {
    type  = "ssh"
    host  = var.host
    user  = "root"
    agent = true
  }

  provisioner "file" {
    content     = jsonencode(data.external.nixos-build.result)
    destination = "/tmp/build-result.json"
  }

  provisioner "local-exec" {
    command = <<EXEC
      ${path.module}/copy-nix.sh "${data.external.nixos-build.result["hash"]}" "${var.host}"
    EXEC
  }
}
