# export ssh
output "nixos_instance_ip" {
  value = module.nixos-instance.nixos_public_ip
}

output "nixos_build_path" {
  value = module.nixos-instance.nixos_path
}
