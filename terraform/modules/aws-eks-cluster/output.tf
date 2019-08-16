output "eks" {
  value = module.eks
}

output "vpc" {
  value = module.vpc
}

output "sg" {
  value = aws_security_group.all_worker_mgmt
}

output "efs_provisoner" {
  value = aws_efs_file_system.efs_provisioner
}
