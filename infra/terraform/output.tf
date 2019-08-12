# export ssh
output "env_vars" {
  value = local.env-vars
}

output "secrets_kms" {
  value = module.secrets.secrets-kms-key.arn
}

output "aws_security_groups_ids" {
  value = module.aws-ec2-network.security_groups_ids
}

output "nixos_public_ip" {
  value = module.aws-ec2-instances.instance_ip
}

output "nixos_build_path" {
  value = module.nixos-updater.nixos_path
}

output "kube_config" {
  value = module.cluster.eks.kubeconfig
}
