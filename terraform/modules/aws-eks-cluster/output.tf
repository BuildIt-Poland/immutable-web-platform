output "eks" {
  value = module.eks
}

output "vpc" {
  value = module.vpc
}

output "sg" {
  value = aws_security_group.all_worker_mgmt
}
