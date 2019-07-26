{config, pkgs, shell-modules, inputs, ...}: 
with pkgs.lib;
{
  imports = with shell-modules.modules; [
    project-configuration
    kubernetes
    docker
    brigade
    bitbucket
    git-secrets
    aws
    base
  ];

  config = {
    environment.type = "local";

    # TODO move to defaults
    project = {
      name = "future-is-comming";
      author-email = "damian.baar@wipro.com";
      version = "0.0.1";
      resources.yaml.folder = "$PWD/resources";
      repositories = {
        k8s-resources = "git@bitbucket.org:damian.baar/k8s-infra-descriptors.git";
        code-repository = "git@bitbucket.org:digitalrigbitbucketteam/embracing-nix-docker-k8s-helm-knative.git";
      };
    };

    docker = {
      upload-images = ["functions" "cluster"];
      namespace = "dev.local";
      registry = "";
      tag = makeDefault inputs.docker.hash "dev-build";
    };

    aws = {
      region = "eu-west-2";
      location = {
        credentials = ~/.aws/credentials;
        config = ~/.aws/config;
      };
    };

    brigade = {
      enabled = true;
      secret-key = inputs.brigade.secret;
    };

    git-secrets = {
      location = "$PWD/secrets.json";
    };

    kubernetes = {
      resources.apply = inputs.kubernetes.update;
      cluster.clean = inputs.kubernetes.clean;
      imagePullPolicy = "Never";
    };

    bitbucket = {
      ssh-keys.location = ~/.ssh/bitbucket_webhook;
    };
  };
}