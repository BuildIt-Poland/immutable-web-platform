output "kube_config" {
  value = module.cluster.eks.kubeconfig
}

output "bastion_public_ip" {
  value = module.bastion.public_ip
}
