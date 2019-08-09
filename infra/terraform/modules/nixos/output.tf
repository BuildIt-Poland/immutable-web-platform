# without this get cyclic error - investigate - in the middle of imports
output "nixos_public_ip" {
  value = aws_eip.nixos_instance_ip.public_ip
}

output "nixos_path" {
  value = data.external.nixos-build.result
}

