
output "kms" {
  value = module.secrets.secrets-kms-key.arn
}

output "docker_registry" {
  value = module.docker-registry.ecr.repository_url
}

output "hydra" {
  value = module.hydra.instance.public_ip
}

output "vpc" {
  value = module.vpc.vpc_arn
}
