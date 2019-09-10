
output "kms" {
  value = module.secrets.secrets-kms-key.arn
}

output "docker_registry" {
  value = module.docker-registry.ecr.repository_url
}