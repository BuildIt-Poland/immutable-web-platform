variable "common_tags" {
  type = "map"
}

variable "region" {}
variable "project_name" {}
variable "env" {}
variable "worker_groups" {}
variable "azs" {}
variable "cluster_name" {}

module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = var.cluster_name

  write_kubeconfig = true

  subnets = module.vpc.private_subnets
  vpc_id  = module.vpc.vpc_id

  worker_groups = var.worker_groups
  tags          = var.common_tags

  config_output_path = "./.kube/"

  worker_additional_security_group_ids = [aws_security_group.all_worker_mgmt.id]

  # worker_groups_launch_template_mixed = [
  #   {
  #     name                    = "spot-1"
  #     override_instance_types = ["m5.large", "m5a.large", "m5d.large", "m5ad.large"]
  #     spot_instance_pools     = 4
  #     asg_max_size            = 5
  #     asg_desired_capacity    = 5
  #     kubelet_extra_args      = "--node-labels=kubernetes.io/lifecycle=spot"
  #     public_ip               = true
  #   },
  # ]

  map_users = var.map_users
  map_roles = var.map_roles
}
