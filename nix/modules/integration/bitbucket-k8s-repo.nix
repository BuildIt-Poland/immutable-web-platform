{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
in
with lib;
rec {

  options.bitbucket = {
    k8s-resources = {
      enable = mkOption {
        default = false;
      };

      # INFO https://github.com/lukepatrick/bitbucket-bitbucket-gateway#bitbucket-integration
      repository = mkOption {
        default = "";
      };
    };
  };

  config = mkIf cfg.bitbucket.k8s-resources.enable (mkMerge [
    { checks = ["Enabling k8s resources repository"]; }
    (
      let
        cmd = lib.bitbucket.push-k8s-resources-to-repo;
      in
      {
      packages = [cmd];

      help = [
        "-- Bitbucket k8s resources --"
        "To push yamls to repository use, ${cmd.name}"
      ];
    })
  ]);
}