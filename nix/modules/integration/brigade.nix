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

    # FIXME add submodules type
    projects = mkOption {
      default = {};
      description = ''
        Brigade projects
      '';
    };

    customization = {
      extension = mkOption {
        default = pkgs.callPackage ../../../packages/brigade-extension/nix {}; 
      };
      remote-worker = mkOption {
        default = pkgs.callPackage ../../remote-worker {};
      };
    };
  };

  config = mkIf cfg.brigade.enabled (mkMerge [
    { checks = ["Enabling brigade module"]; }

    ({
      environment.vars = {
        BRIGADE_NAMESPACE = cfg.kubernetes.namespace.brigade;
      };

      packages = with pkgs;[
        brigade
        brigadeterm
      ];

      # warnings = mkIf (cfg.brigade.secret-key == "") [
      #   "You have to provide brigade shared secret to listen the repo hooks"
      # ];
    })
  ]);
}