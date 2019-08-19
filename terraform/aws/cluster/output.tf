output "kube_config" {
  value = module.cluster.eks.kubeconfig
}

output "bastion_public_ip" {
  value = module.bastion.public_ip
}

output "efs_provisoner" {
  value = module.cluster.efs_provisoner.id
}
