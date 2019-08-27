output "kube_config" {
  value = module.cluster.eks.kubeconfig
}

output "bastion" {
  value = module.bastion.public_ip
}

output "iam" {
  value = module.cluster.policy.arn
}
