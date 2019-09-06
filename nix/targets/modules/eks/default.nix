{config, pkgs, lib, kubenix, integration-modules, inputs, ...}: 
with pkgs.lib;
let
  resources = config.kubernetes.resources;
  priority = resources.priority;
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
    imports = with integration-modules.modules; [
      kubernetes
    ];

  config = {
    kubernetes.resources.list."${priority.high "eks"}" = [ ./kubernetes ];

    project = {
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

    environment = {
      type = inputs.environment.type;
      runtime = inputs.environment.runtime;
      vars = {
        PROJECT_NAME = config.project.name;
        RESTIC_PASSWORD_COMMAND = "get-restic-repo-password";
      };
    };

    docker = rec {
      upload = inputs.docker.upload;
      namespace = mkForce cluster-name;
      tag = mkForce cfg.project.hash;
      imageName = mkForce (name: "${namespace}");
      imageTag = mkForce (name: "${name}-${tag}");
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
  };
}