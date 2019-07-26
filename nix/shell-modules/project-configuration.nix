{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
in
with lib;
rec {
  options.project = {
    name = mkOption {
      default = "future-is-comming";
    };

    version = mkOption {
      default = "0.0.1";
    };

    resources.yaml.location = mkOption {
      default = "$PWD/resources";
    };

    repositories = mkOption {
      default = {
        infra-k8s-yaml = "git@bitbucket.org:damian.baar/k8s-infra-descriptors.git";
      };
      # repository = {
      #   location = "bitbucket.org/digitalrigbitbucketteam/embracing-nix-docker-k8s-helm-knative"; # this name cannot be longer than 64
      #   git = "git@bitbucket.org:digitalrigbitbucketteam/embracing-nix-docker-k8s-helm-knative.git";
      # };
    };
  };
}