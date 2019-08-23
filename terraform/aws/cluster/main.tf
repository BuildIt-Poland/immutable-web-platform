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

# TODO nodeaffinity/taints - test should not take run on spot
# TODO from kubelet: in 1.15, --node-labels in the 'kubernetes.io' namespace must begin with an allowed prefix (kubelet.kubernetes.io, node.kubernetes.io) or be in the sp
# https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler/cloudprovider/aws#scaling-a-node-group-to-0

# mixedtemplates works since 0.14 -> 
# https://github.com/kubernetes/autoscaler/issues/2246 - waiting for september
# https://github.com/kubernetes/autoscaler/pull/2248/files
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
      asg_max_size         = 3
      asg_desired_capacity = 2
      kubelet_extra_args   = "--node-labels=kubernetes.io/lifecycle=on-demand,rook-ceph=cluster"
      key_name             = module.bastion.ssh_key.key_name
      ebs_optimized        = true
    },
  ]

  worker_groups_launch_template = [
    {
      name                = "spot-1"
      autoscaling_enabled = "true"
      # override_instance_types = ["m5.xlarge", "m4.xlarge"]
      override_instance_types = ["m4.xlarge"] #, "m4.xlarge"]
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

# count        = var.createResource ? 1 : 0
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
    kubeconfig = yamldecode(module.cluster.eks.kubeconfig)
    bastion    = module.bastion.public_ip
  }
  file-output = "${var.output_state_file["aws_cluster"]}" # convention path from terraform folder perspective
}

# FIXME take from nix
resource "aws_route53_zone" "primary" {
  name = var.domain
  tags = local.common_tags

  vpc {
    vpc_id = module.cluster.vpc.vpc_id
  }
}

resource "aws_route53_record" "www-primary" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.${var.domain}"
  type    = "NS"
  ttl     = "30"
  records = [
    "${aws_route53_zone.primary.name_servers.0}",
    "${aws_route53_zone.primary.name_servers.1}",
    "${aws_route53_zone.primary.name_servers.2}",
    "${aws_route53_zone.primary.name_servers.3}",
  ]
}
