provider "aws" {
  region = var.region
}

data "terraform_remote_state" "state" {
  backend = "s3"
  config = {
    key    = "${var.project_prefix}/cluster"
    region = var.region
    bucket = var.tf_state_bucket
  }
}

data "terraform_remote_state" "setup-state" {
  backend = "s3"
  config = {
    key    = "${var.project_prefix}/setup"
    region = var.region
    bucket = var.tf_state_bucket
  }
}

# TODO add spot instances and node labels
# TODO add autoscaller priority
# TODO nodeaffinity/taints - test should not take run on spot
# TODO from kubelet: in 1.15, --node-labels in the 'kubernetes.io' namespace must begin with an allowed prefix (kubelet.kubernetes.io, node.kubernetes.io) or be in the sp
module "cluster" {
  source = "../../modules/aws-eks-cluster"

  project_name = var.project_name
  env          = var.env
  region       = var.region
  common_tags  = local.common_tags

  cluster_name = "${var.cluster_name}"

  azs = local.azs

  # think about buildit aws limits / Running On-Demand m4 hosts 2
  worker_groups = [
    {
      autoscaling_enabled  = "true"
      instance_type        = "m4.xlarge"
      asg_max_size         = 2
      asg_desired_capacity = 1
      kubelet_extra_args   = "--node-labels=kubernetes.io/lifecycle=on-demand"
      key_name             = module.bastion.ssh_key.key_name
      ebs_optimized        = true
    },
  ]

  worker_groups_launch_template_mixed = [
    {
      name                    = "spot-1"
      override_instance_types = ["m4.large", "m4.xlarge"]
      spot_instance_pools     = 4
      asg_desired_capacity    = 2
      asg_max_size            = 5
      name_prefix             = "spot"
      bootstrap_extra_args    = "--enable-docker-bridge true"
      kubelet_extra_args      = "--node-labels=kubernetes.io/lifecycle=spot"
      key_name                = module.bastion.ssh_key.key_name
      ebs_optimized           = true
    },
  ]

  map_users = var.map_users
  map_roles = var.map_roles
}

module "bastion" {
  source       = "../../modules/aws-bastion"
  project_name = var.project_name
  env          = var.env
  region       = var.region
  cluster_name = var.cluster_name
  common_tags  = local.common_tags
  ssh_pub_key  = var.ssh_pub_key
  vpc          = module.cluster.vpc
}

# INFO: cmd to generate: `tf-nix-exporter aws/cluster`
module "export-to-nix" {
  source = "../../modules/export-to-nix"
  data = {
    # TODO formatitng of yaml seems to be inccorect
    kubeconfig = yamldecode(module.cluster.eks.kubeconfig)
    bastion    = module.bastion.public_ip
    efs        = module.cluster.efs_provisoner.id
  }
  file-output = "${var.root_folder}/nix/cluster-vars.json"
}
