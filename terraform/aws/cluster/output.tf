output "kube_config" {
  value = module.cluster.eks.kubeconfig
}
