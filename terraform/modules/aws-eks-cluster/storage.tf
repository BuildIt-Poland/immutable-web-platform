
resource "aws_efs_file_system" "efs_provisioner" {
  tags = merge(var.common_tags, {
    Name = "efs.${var.cluster_name}"
  })
}

# read https://docs.aws.amazon.com/efs/latest/ug/security-considerations.html
# gut feeling telling me that should be in private
resource "aws_efs_mount_target" "efs_provisioner" {
  count = length(module.vpc.public_subnets)

  file_system_id  = aws_efs_file_system.efs_provisioner.id
  subnet_id       = module.vpc.public_subnets[count.index]
  security_groups = [aws_security_group.all_worker_mgmt.id]
}
