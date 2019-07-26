{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
  [b] 
in
with lib;
rec {

  imports = [
  ];

  options.skaffold = {
  };

  config = mkIf cfg.aws.enabled (mkMerge [
    ({
      checks = ["Enabling Skaffold for development"];

      packages = [
        pkgs.skaffold
      ];
    })
  ]);
}