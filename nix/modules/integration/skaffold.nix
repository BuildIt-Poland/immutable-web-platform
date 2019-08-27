{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
in
with lib;
rec {

  imports = [
  ];

  options.skaffold = {
  };

  config = mkIf (cfg.aws.enabled && cfg.environment.isLocal) (mkMerge [
    ({
      checks = ["Enabling Skaffold for development"];

      packages = [
        pkgs.skaffold
      ];
    })
  ]);
}