{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
in
with lib;
rec {

  options.bitbucket = {
    k8s-resources = {
      enabled = mkOption {
        default = true;
      };

      # INFO https://github.com/lukepatrick/bitbucket-bitbucket-gateway#bitbucket-integration
      repository = mkOption {
        default = "";
      };
    };
  };

  config = mkIf cfg.bitbucket.k8s-resources.enabled (mkMerge [
    { checks = ["Enabling k8s resources repository"]; }
    ({
      packages = with pkgs; [
        lib.bitbucket.push-with-pr 
      ];
    })
  ]);
}