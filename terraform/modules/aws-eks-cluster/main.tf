# TODO figure out spot instances for brigade
module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = var.cluster_name

  write_kubeconfig = true

  subnets = module.vpc.private_subnets
  vpc_id  = module.vpc.vpc_id

  worker_groups = var.worker_groups
  tags          = var.common_tags

  config_output_path = "./.kube/"
  # kubeconfig_name    = "kubeconfig"

  worker_additional_security_group_ids = [aws_security_group.all_worker_mgmt.id]

  map_users = var.map_users
  map_roles = var.map_roles
}
