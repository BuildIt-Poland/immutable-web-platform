{pkgs, lib, callPackage, buildGoPackage, fetchFromGitHub, project-config}:
let
  nix-terraform = callPackage ./terraform-provider-nix.nix {};
  nix-provider-nix = nix-terraform;
  terraform = pkgs.terraform_0_12.withPlugins (plugins: [
    plugins.aws
    plugins.null
    plugins.random
    plugins.local
    plugins.template
    plugins.archive
    plugins.external
    nix-provider-nix
  ]);
  config = rec {
    region = project-config.aws.region;
    project_name = project-config.project.name;
    owner = project-config.project.author-email;
    env = project-config.environment.type;
    cluster_name = project-config.kubernetes.cluster.name;

    worker_bucket   = "${project-config.aws.s3-buckets.worker-cache}";

    tf_state_bucket = "${project_name}-${env}-${region}-state";
    tf_state_table  = "${project_name}-${env}-${region}-state";
    tf_state_path = "terraform-${project_name}-${env}-${region}.tfstate";
  };

  config-file = pkgs.writeText "terraform-tfvars" ''
    ${builtins.toJSON config}
  '';

  config-env-vars = 
    lib.concatStringsSep " "
      (builtins.attrValues 
        (builtins.mapAttrs (n: v: "--set TF_VAR_${n} ${v}") config));

  init-vars = {
    bucket = config.tf_state_bucket;
    key = config.tf_state_path;
    dynamodb_table = config.tf_state_table;
    region = config.region;
  };

  init-vars-file = pkgs.writeText "tf-backend-values.hcl" ''
    ${lib.generators.toKeyValue {} 
      (builtins.mapAttrs (x: y: "\"${y}\"") init-vars)}
  '';

  print-env-vars = pkgs.writeText "print-tf-env-vars" ''
    "-- Terraform env vars --"
    ${config-env-vars}
  '';

  # TODO or maybe generate tfvar file and link to every module?
  wrap-terraform-init = pkgs.writeScript "wrap-terraform-init" ''
    extraArgs="-backend-config=${init-vars-file}"
    [[ $1 = "init" ]] || extraArgs=""

    cat ${print-env-vars}
    ${terraform}/bin/terraform $* $extraArgs
  '';
in 
[
  (pkgs.runCommand "terraform" {
    buildInputs = [pkgs.makeWrapper];
  } ''
    mkdir -p $out/bin
    makeWrapper ${wrap-terraform-init} $out/bin/terraform \
      ${config-env-vars}
  '')

  (pkgs.writeScriptBin "terraform-bootstrap" ''
    echo "create s3 and dynamodb table"
  '')
]