# without this get cyclic error - investigate - in the middle of imports
output "instance_ip" {
  value = aws_eip.nixos_instance_ip.public_ip
}
