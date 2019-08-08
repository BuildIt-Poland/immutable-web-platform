output "nixos_public_ip" {
  value = aws_eip.ip-test-env.public_ip
}
