{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
in
with lib;
rec {

  options.service-mesh = {
    enabled = mkOption {
      default = true;
    };
    helm-overrdings = mkOption {
      default = "";
    };
  };

  config = mkIf cfg.service-mesh.enabled (mkMerge [
    ({
      checks = ["Enabling service-mesh module"];

      packages = with pkgs; [
      ];
    })
  ]);
}