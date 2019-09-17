output "instance" {
  value = module.aws-ec2-instance.instance
}

output "sg" {
  value = aws_security_group.hydra-sg
}