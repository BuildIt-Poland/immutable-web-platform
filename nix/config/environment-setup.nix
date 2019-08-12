{config, pkgs, lib, kubenix, shell-modules, inputs, ...}: 
with pkgs.lib;
{
  imports = with shell-modules.modules; [
    project-configuration
    kubernetes
    kubernetes-resources
    bitbucket-k8s-repo
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
      projects = {
        brigade-project = {
          project-name = "embracing-nix-docker-k8s-helm-knative";
          pipeline-file = ../../pipeline/infrastructure.ts; # think about these long paths
          clone-url = config.project.repositories.code-repository;
          ssh-key = config.bitbucket.ssh-keys.priv;
          # https://github.com/brigadecore/k8s-resources/blob/master/k8s-resources/brigade-project/values.yaml
          overridings = {};
        };
      };
    };

    git-secrets = {
      location = ../../secrets.json;
    };

    kubernetes = {
      target = inputs.kubernetes.target;
      cluster = {
        clean = inputs.kubernetes.clean;
        name = "${config.project.name}-${config.environment.type}";
      };
      patches.enable = inputs.kubernetes.patches;
      imagePullPolicy = "Never";
      resources = 
        with kubenix.modules;
        let
          functions = (import ./functions.nix { inherit pkgs; });
          resources = config.kubernetes.resources;
          extra-resources = builtins.getAttr config.kubernetes.target {
            eks = {
              "${priority.high "eks-cluster"}"       = [ eks-cluster ];
            };
            minikube = {};
          };
          priority = resources.priority;
          # TODO apply skip
          modules = {
            "${priority.high "istio"}"       = [ istio-service-mesh ];
            "${priority.mid  "knative"}"     = [ knative ];
            "${priority.low  "monitoring"}"  = [ weavescope knative-monitoring ];
            "${priority.low  "gitops"}"      = [ argocd ];
            "${priority.low  "ci"}"          = [ brigade ];
            "${priority.low  "secrets"}"     = [ secrets ];
          } // functions // extra-resources;
          in
          {
            apply = inputs.kubernetes.update;
            save = inputs.kubernetes.save;
            list = modules;
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