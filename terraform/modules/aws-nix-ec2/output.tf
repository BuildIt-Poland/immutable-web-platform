output "instance" {
  value = aws_instance.nixos_instance
}

output "key" {
  value = aws_key_pair.instance
}