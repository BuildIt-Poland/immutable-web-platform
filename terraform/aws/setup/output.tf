
output "kms" {
  value = module.secrets.secrets-kms-key.arn
}

output "docker_registry" {
  value = module.docker-registry.ecr.repository_url
}

output "aws_security_groups_ids" {
  value = module.aws-ec2-network.security_groups_ids
}

output "hydra_ip" {
  value = module.aws-ec2-instances.instance_ip
}
