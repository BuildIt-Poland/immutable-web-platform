{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
in
with lib;
rec {

  options.brigade = {
    enabled = mkOption {
      default = true;
    };

    # INFO https://github.com/lukepatrick/brigade-bitbucket-gateway#bitbucket-integration
    secret-key = mkOption {
      default = "";
    };

    # TODO
    # projects = mkOption {
      # project-template {
      #   project-name = "embracing-nix-docker-k8s-helm-knative";
      #   pipeline-file = ../../pipeline/infrastructure.ts; # think about these long paths
      #   clone-url = project-config.project.repositories.code-repository;
      # };
    # };

    customization = {
      extension = mkOption {
        default = pkgs.callPackage ../../packages/brigade-extension/nix {}; 
      };
      remote-worker = mkOption {
        default = pkgs.callPackage ../remote-worker {};
      };
    };
  };

  config = mkIf cfg.brigade.enabled (mkMerge [
    { checks = ["Enabling brigade module"]; }
    ({
      packages = with pkgs;[
        brigade
        brigadeterm
        k8s-operations.local.expose-brigade-gateway
        k8s-operations.local.create-localtunnel-for-brigade
      ];

      help = [
        "-- Brigade integration --"
        "To expose brigade gateway for BitBucket events, run '${pkgs.k8s-operations.local.expose-brigade-gateway.name}'"
        "To make gateway accessible from outside, run '${pkgs.k8s-operations.local.create-localtunnel-for-brigade.name}'"
      ];

      warnings = mkIf (cfg.brigade.secret-key == "") [
        "You have to provide brigade shared secret to listen the repo hooks"
      ];
    })
  ]);
}