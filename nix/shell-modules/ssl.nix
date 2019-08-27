{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
in
with lib;
rec {

  options.ssl = {
    enabled = mkOption {
      default = true;
    };
    domains = mkOption {
      default = [];
    };
  };

  config = mkIf cfg.ssl.enabled (mkMerge [
    ({
      checks = ["Enabling ssl module"];

      packages = with pkgs; [
      ];
    })
  ]);
}