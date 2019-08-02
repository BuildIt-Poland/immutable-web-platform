{config, pkgs, lib, kubenix, shell-modules, inputs, ...}: 
with pkgs.lib;
{
  imports = with shell-modules.modules; [
    project-configuration
    kubernetes
    kubernetes-resources
    docker
    brigade
    bitbucket
    git-secrets
    aws
    base
  ];

  config = {
    environment.type = inputs.environment.type;

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
      upload-images-type = ["functions" "cluster"];
      upload = inputs.docker.upload;
      namespace = "dev.local";
      registry = "";
      tag = makeDefault inputs.docker.tag "dev-build";
    };

    aws = {
      location = {
        credentials = ~/.aws/credentials;
        config = ~/.aws/config;
      };
      s3-buckets = {
        worker-cache = "${config.project.name}-worker-binary-store";
      };
    };

    brigade = {
      enabled = true;
      secret-key = inputs.brigade.secret;
    };

    git-secrets = {
      location = ../../secrets.json;
    };

    kubernetes = {
      cluster.clean = inputs.kubernetes.clean;
      imagePullPolicy = "Never";
      resources = {
        apply = inputs.kubernetes.update;
        list = 
          with kubenix.modules;
          # maybe it should be done in a way like queue works
          {
            istio         = [ istio-service-mesh ];
            knative       = [ knative ];
            monitoring    = [ weavescope knative-monitoring ];
            gitops        = [ argocd ];
            ci            = [ brigade ];
          } // (import ./functions.nix { inherit pkgs; });
      };

      namespace = {
        functions = "${config.environment.type}-functions";
      };
    };

    bitbucket = {
      ssh-keys.location = ~/.ssh/bitbucket_webhook;
    };
  };
}