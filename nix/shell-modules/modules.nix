{
  base = ./base.nix;
  project-configuration = ./project-configuration.nix;
  kubernetes = ./kubernetes.nix;
  docker = ./docker.nix;
  local-cluster = ./local-cluster.nix;
  aws = ./aws.nix;
  brigade = ./brigade.nix;
  bitbucket = ./bitbucket.nix;
  terraform = ./terraform.nix;
  eks-cluster = ./eks-cluster.nix;
  git-secrets = ./git-secrets.nix;
  kubernetes-resources = ./kubernetes-resources.nix;
  bitbucket-k8s-repo = ./bitbucket-k8s-repo.nix;
  storage = ./storage.nix;
  ssl = ./ssl.nix;
  load-balancer = ./load-balancer.nix;
  service-mesh = ./service-mesh.nix;
}