{pkgs, lib, callPackage, buildGoPackage, fetchFromGitHub, project-config}:
let
  nix-terraform = callPackage ./terraform-provider-nix.nix {};
  nix-provider-nix = nix-terraform;
  terraform = pkgs.terraform_0_12.withPlugins (plugins: [
    plugins.aws
    nix-provider-nix
  ]);
  config = rec {
    region = project-config.aws.region;
    project_name = project-config.project.name;
    owner = project-config.project.author-email;
    env = project-config.environment.type;

    worker_bucket   = "${project-config.aws.s3-buckets.worker-cache}";

    tf_state_bucket = "${project_name}-${env}-state";
    tf_state_table  = "${project_name}-${env}-state";
    tf_state_path = "network/terraform.tfstate";
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
    # dynamodb_table = config.tf_state_table;
    region = config.region;
  };

  init-vars-file = pkgs.writeText "tf-backend-values.hcl" ''
    ${lib.generators.toKeyValue {} 
      (builtins.mapAttrs (x: y: "\"${y}\"") init-vars)}
  '';
in 
[
  (pkgs.runCommand "terraform" {
    buildInputs = [pkgs.makeWrapper];
  } ''
    mkdir -p $out/bin
    echo ${config-env-vars}
    makeWrapper ${terraform}/bin/terraform $out/bin/terraform \
      ${config-env-vars}
  '')

  (pkgs.writeScriptBin "terraform-init" ''
    echo "vars values: \n $(cat ${init-vars-file})"
    ${terraform}/bin/terraform init -backend-config=${init-vars-file} $*
  '')

  (pkgs.writeScriptBin "terraform-bootstrap" ''
    echo "create s3 and dynamodb table"
  '')
]