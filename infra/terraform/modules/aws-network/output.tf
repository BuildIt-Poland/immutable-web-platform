output "security_groups_ids" {
  value = ["${aws_security_group.ingress.id}"]
}

output "subnet_id" {
  value = aws_subnet.public.id
}
