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

    test.enable = inputs.tests.enable;

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
          let
            functions = (import ./functions.nix { inherit pkgs; });

            # FIXME: move me somehwere else
            mkPriority = x: name: "${toString x}-${name}";
            high-priority = mkPriority 0;
            mid-priority = mkPriority 1;
            low-priority = mkPriority 2;
          in
          with kubenix.modules;
          {
            "${high-priority "istio"}"       = [ istio-service-mesh ];
            "${mid-priority  "knative"}"     = [ knative ];
            "${low-priority  "monitoring"}"  = [ weavescope knative-monitoring ];
            "${low-priority  "gitops"}"      = [ argocd ];
            "${low-priority  "ci"}"          = [ brigade ];
          } // functions;
      };

      namespace = {
        functions = "functions";
      };
    };

    bitbucket = {
      ssh-keys.location = ~/.ssh/bitbucket_webhook;
    };
  };
}