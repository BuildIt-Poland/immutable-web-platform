output "kube_config" {
  value = module.cluster.eks.kubeconfig
}

output "docker_registry" {
  value = module.docker-registry.ecr.repository_url
}
