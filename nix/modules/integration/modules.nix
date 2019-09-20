{
  base = ./base.nix;
  project-configuration = ./project-configuration.nix;
  kubernetes = ./kubernetes.nix;
  kubernetes-tools = ./kubernetes-tools.nix;
  docker = ./docker.nix;
  aws = ./aws.nix;
  brigade = ./brigade.nix;
  bitbucket = ./bitbucket.nix;
  terraform = ./terraform.nix;
  git-secrets = ./git-secrets.nix;
  kubernetes-resources = ./kubernetes-resources.nix;
  bitbucket-k8s-repo = ./bitbucket-k8s-repo.nix;
  storage = ./storage.nix;
  skaffold = ./skaffold.nix;
  tekton = ./tekton.nix;
  shell-tools = ./shell-tools.nix;
  service-mesh = ./service-mesh.nix;
}