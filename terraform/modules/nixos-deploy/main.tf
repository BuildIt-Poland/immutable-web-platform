data "external" "nixos-build" {
  program = ["${path.module}/build-nix.sh", "${var.nixos_configuration}"]
}

resource "null_resource" "bootstrap" {
  triggers = var.watch

  # FIXME this should be configurable
  # missing ec2 instance - less waiting calls
  depends_on = [
    data.external.nixos-build,
  ]

  # INFO: this piece cannot cannect thru ssh - shouting about key mismatch - investigate
  # provisioner "file" {
  #   connection {
  #     type  = "ssh"
  #     host  = var.host
  #     user  = "root"
  #     agent = true
  #   }

  #   content     = jsonencode(data.external.nixos-build.result)
  #   destination = "/tmp/build-result.json"
  # }

  provisioner "local-exec" {
    command = <<EXEC
      ${path.module}/wait-for-ssh.sh root ${var.host}
      ssh root@${var.host} "echo '${jsonencode(data.external.nixos-build.result)}' > /tmp/build-result.json"
      ${path.module}/copy-nix.sh "${data.external.nixos-build.result["hash"]}" "${var.host}"
    EXEC
  }
}
