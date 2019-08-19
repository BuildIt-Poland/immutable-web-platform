module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = var.cluster_name

  write_kubeconfig      = true
  write_aws_auth_config = true

  subnets = module.vpc.private_subnets
  vpc_id  = module.vpc.vpc_id

  worker_groups_launch_template = var.worker_groups_launch_template
  worker_groups                 = var.worker_groups

  workers_additional_policies = [aws_iam_policy.worker-policy.arn]

  tags = var.common_tags

  config_output_path = "./.kube/"
  # kubeconfig_name    = "kubeconfig"

  worker_additional_security_group_ids = [
    aws_security_group.all_worker_mgmt.id
  ]

  map_users = var.map_users
  map_roles = var.map_roles
}
