# export ssh
output "nixos_instance_ip" {
  value = module.nixos-instance.nixos_public_ip
}
