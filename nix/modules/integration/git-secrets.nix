{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
in
with lib;
rec {

  options.git-secrets = {
    enabled = mkOption {
      default = true;
    };
    location = mkOption {
      default = "";
    };
  };

  config = mkIf (cfg.git-secrets.enabled && cfg.environment.isLocal) (mkMerge [
    ({
      checks = ["Enabling secret handling module"];

      packages = with pkgs; [
        sops
      ];
    })
  ]);
}