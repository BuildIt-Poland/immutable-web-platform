{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
in
with lib;
rec {

  imports = [
  ];

  options.skaffold = {
    enable = mkOption {
      default = false;
    };
  };

  config = mkIf cfg.skaffold.enable (mkMerge [
    ({
      checks = ["Enabling Skaffold for development"];

      packages = [
        pkgs.skaffold
      ];
    })
  ]);
}