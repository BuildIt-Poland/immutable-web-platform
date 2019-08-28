{config, pkgs, lib, kubenix, integration-modules, inputs, ...}: 
with pkgs.lib;
let
  functions = (import ./modules/functions.nix { inherit pkgs; });
in
{
  imports = with integration-modules.modules; [
    ./kubernetes-modules.nix
    project-configuration
    eks-cluster
    kubernetes
    kubernetes-resources
    bitbucket-k8s-repo
    local-cluster
    docker
    storage
    brigade
    bitbucket
    terraform
    git-secrets
    aws
    base
  ];

  config = {
    environment = {
      type = inputs.environment.type;
      runtime = inputs.environment.runtime;
      vars = {
        PROJECT_NAME = config.project.name;
      };
    };

    project = rec {
      name = inputs.project.name;
      author-email = "damian.baar@wipro.com";
      # IMPORTANT you have to own it
      domain = "buildit.consulting";
      subdomains = ["*.services" "*.functions"];
      version = "0.0.1";
      resources.yaml.folder = "$PWD/resources";
      repositories = {
        k8s-resources = "git@bitbucket.org:damian.baar/k8s-infra-descriptors.git";
        code-repository = "git@bitbucket.org:digitalrigbitbucketteam/embracing-nix-docker-k8s-helm-knative.git";
      };

      # FIXME move me to somewhere else ... or not
      make-sub-domain = 
        name: 
          (lib.concatStringsSep "." 
            (builtins.filter (x: x != "") [
              name
              config.project.name
              config.environment.type
              config.project.domain
            ]));
    };

    test.enable = inputs.tests.enable;

    docker = {
      upload = inputs.docker.upload;
      namespace = "dev.local";
      # registry = "";
      tag = makeDefault inputs.docker.tag "dev-build";
    };

    aws = {
      account = "006393696278";
      location = {
        credentials = ~/.aws/credentials;
        config = ~/.aws/config;
      };
      s3-buckets = {
        worker-cache = "${config.project.name}-${config.environment.type}-worker-binary-store";
      };
    };

    storage.backup.bucket = "${config.project.name}-${config.environment.type}-backup";

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
          overridings = {
            kubernetes = {
              cacheStorageClass = "cache-storage";
              buildStorageClass = "build-storage";
            };
          };
        };
      };
    };

    git-secrets = {
      location = ../../secrets.json;
    };

    eks-cluster = {
      enable = inputs.kubernetes.target == "eks";
      configuration = 
        let
          terraform-output = 
            builtins.fromJSON 
              (builtins.readFile config.terraform.stateFiles.aws_cluster); # actually I can merge these state files
        in
        {
          bastion = terraform-output.bastion;
        };
    };

    storage.dataDirHostPath = "/var/lib/rook";
    storage.backup.schedules = {
      all-ns = {
        schedule = "2 * * * *";
        template = ''
        '';
      };
    };

    local-cluster.enable = inputs.kubernetes.target == "minikube";

    terraform = rec {
      enable = true;

      location = toString ../../terraform;

      vars = rec {
        region = config.aws.region;
        project_name = config.project.name;
        domain = (config.project.make-sub-domain "");
        owner = config.project.author-email;
        hash = config.project.hash;
        env = config.environment.type;
        cluster_name = config.kubernetes.cluster.name;
        output_state_file = config.terraform.stateFiles;
        project_prefix = "${project_name}-${env}-${region}";
        root_folder = toString ../..;

        backup_bucket = config.storage.backup.bucket;
        worker_bucket   = "${config.aws.s3-buckets.worker-cache}";

        # TODO bucket does not need to be prefixed - there will be folder inside
        # no point to have tons of buckets
        tf_state_bucket = "${project_prefix}-state";
        tf_state_table  = tf_state_bucket;
      };

      backend-vars = {
        bucket = vars.tf_state_bucket;
        dynamodb_table = vars.tf_state_table;
        region = vars.region;
      };
    };

    kubernetes = {
      target = inputs.kubernetes.target;

      namespace = {
        functions = "functions";
        argo = "gitops";
        brigade = "ci";
      };

      cluster = {
        clean = inputs.kubernetes.clean;
        name = "${config.project.name}-${config.environment.type}-cluster";
      };
      patches.enable = inputs.kubernetes.patches;
      resources = {
        apply = inputs.kubernetes.update;
        save = inputs.kubernetes.save;
      };
    };

    # should be autogenerated from terraform for dev env
    bitbucket = {
      ssh-keys.location = ~/.ssh/bitbucket_webhook;
    };
  };
}