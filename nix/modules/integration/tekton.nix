{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
in
with lib;
rec {

  options.tekton = {
    enabled = mkOption {
      default = true;
    };
  };

  config = mkIf cfg.tekton.enabled (mkMerge [
    { checks = ["Enabling tekton module"]; }

    ({
      environment.vars = {
      };

      packages = with pkgs;[
        kubectl-tkn
      ];
    })
  ]);
}