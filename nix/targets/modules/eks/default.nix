{config, pkgs, lib, kubenix, integration-modules, inputs, ...}: 
with pkgs.lib;
let
  resources = config.kubernetes.resources;
  priority = resources.priority;
  cluster-name = config.kubernetes.cluster.name;
in
{
  imports = with integration-modules.modules; [
    ./options.nix
    project-configuration
    kubernetes
    kubernetes-resources
    bitbucket-k8s-repo
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

    kubernetes = {
      resources.list."${priority.high "eks"}" = [ ./kubernetes ];

      namespace = {
        istio = {
          name = "${config.environment.type}-functions";
          metadata.annotations = {
            "iam.amazonaws.com/allowed-roles" = "[\"${config.kubernetes.cluster.name}*\"]";
          };
        };
      };
    };

    docker = rec {
      upload = inputs.docker.upload;
      namespace = mkForce cluster-name;
      tag = mkForce config.project.hash;
      registry = ""; # CHECK THIS
      imageName = mkForce (name: "${cluster-name}");
      imageTag = mkForce (name: "${name}-${config.docker.tag}");
    };

    storage.backup.bucket = "${config.project.name}-${config.environment.type}-backup";

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
        schedule = "@every 1h";
        template = {
          ttl = "4h0m0s";
        };
      };
    };

    terraform = rec {
      enable = true;

      location = toString ../../../../terraform;

      vars = rec {
        region = config.aws.region;
        project_name = config.project.name;
        domain = (config.project.make-sub-domain "");
        owner = config.project.authorEmail;
        hash = config.project.hash;
        env = config.environment.type;
        cluster_name = config.kubernetes.cluster.name;
        output_state_file = config.terraform.stateFiles;
        project_prefix = "${project_name}-${env}-${region}";
        root_folder = config.project.rootFolder;

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
  };
}