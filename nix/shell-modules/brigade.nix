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

    secret-key = mkOption {
      default = "";
    };

    customization = {
      extension = mkOption {
        default = pkgs.callPackage "../../packages/brigade-extension/nix" {}; 
      };
      remote-worker = mkOption {
        default = pkgs.callPackage ../../packages/remote-worker {};
      };
    };
  };
  # s3 = {
  #   worker-cache = "${projectName}-worker-binary-store";
  # };

  # # brigade = {
  # #   sharedSecret = brigadeSharedSecret;
  # #   project-name = "embracing-nix-docker-k8s-helm-knative";
  # #   pipeline = "${rootFolder}/pipeline/infrastructure.ts"; 
  # # };

  # info = rec {
  #   warnings = lib.dischargeProperties (
  #     lib.mkMerge [
  #       (lib.mkIf 
  #         (!(ssh-keys.bitbucket.priv != ""))
  #         "Bitbucket key does not exists") 
  #     ]
  #   );


  config = mkIf cfg.brigade.enabled (mkMerge [
    ({
      packages = with pkgs;[
        brigade
        brigadeterm
      ];

      shellHook = ''
        ${pkgs.log.message "Running integration with brigade"}
      '';

      help = ''
        echo "-- Brigade integration --"
        echo "To expose brigade gateway for BitBucket events, run '${pkgs.k8s-operations.local.expose-brigade-gateway.name}'"
        echo "To make gateway accessible from outside, run '${pkgs.k8s-operations.local.create-localtunnel-for-brigade.name}'"
      '';

      warnings = mkIf (cfg.brigade.secret-key == "") [
        "You have to provide brigade shared secret to listen the repo hooks"
      ];
    })
  ]);
}