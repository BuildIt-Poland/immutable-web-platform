{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
  get-terraform-output = pkgs.writeScriptBin "get-terraform-output" ''
    out=$(cd ${cfg.terraform.location}/aws/cluster && terraform output $1)
    echo $out
  '';
  terraform-projects = pkgs.writeScriptBin "tf-project" ''
    dir=$1
    shift

    ${pkgs.lib.log.info "Running terraform for project: $dir"}
    cd "${cfg.terraform.location}/$dir" && ${pkgs.terraform-with-plugins}/bin/terraform $@
  '';
  terraform-export = pkgs.writeScriptBin "tf-nix-exporter" ''
    dir=$1

    ${pkgs.lib.log.info "Running state exporter for project: $dir"}

    cd "${cfg.terraform.location}/$dir" && \
    ${pkgs.terraform-with-plugins}/bin/terraform state rm module.export-to-nix.null_resource.vars && \
    ${pkgs.terraform-with-plugins}/bin/terraform apply -target module.export-to-nix.null_resource.vars
  '';
in
with lib;
rec {

  options.terraform = {
    enable = mkOption {
      default = true;
    };

    location = mkOption {
      default = "";
    };

    # TODO make it more descriptive - what kind of fields it expec
    vars = mkOption {
      default = {};
    };

    backend-vars = mkOption {
      default = {};
    };

    stateFiles = mkOption {
      default = {};
    };

    # TODO think about it
    outputs = mkOption {
      default = {};
    };
  };

  config = mkIf (cfg.terraform.enable) (mkMerge [
    { checks = ["Enabling terraform module"]; }
    ({
      help = [
        "-- Terraform integration --"
        "You can use 'tf-project <name_of_project> <command>', to avoid the need to go to terraform folders."
        "You can use 'tf-nix-exporter <name_of_project>', it is required to define module.export-to-nix in module."
      ];

      warnings = 
        let
          files = builtins.attrValues cfg.terraform.stateFiles;
          not-exists = builtins.filter (x: !(builtins.pathExists x)) files;
          messages = builtins.map (x: ''
            Output from terraform state file does not exists, try to run 'tf-nix-exporter' to generate <${builtins.baseNameOf x}> file.
          '') not-exists;
        in
          messages;

      packages = with pkgs; [
        get-terraform-output
        terraform-projects
        terraform-export
        terraform-with-plugins
      ];
    })
  ]);
}