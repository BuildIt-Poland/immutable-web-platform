output "instance" {
  value = aws_spot_instance_request.nixos_instance
}

output "key" {
  value = aws_key_pair.instance
}