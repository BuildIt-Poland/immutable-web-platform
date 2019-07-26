{
  base = ./base.nix;
  project-configuration = ./project-configuration.nix;
  kubernetes = ./kubernetes.nix;
  docker = ./docker.nix;
  local-cluster = ./local-cluster.nix;
  aws = ./aws.nix;
  brigade = ./brigade.nix;
  bitbucket = ./bitbucket.nix;
}