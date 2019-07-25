{config, pkgs, lib,...}:
with lib;
let
  cfg = config;

  # TODO get packages and traverse it's names
  get-help = pkgs.writeScriptBin "get-help" ''
    echo "You've got in shell some extra spells under your hand ..."
    echo "-- Brigade integration --"
    echo "To expose brigade gateway for BitBucket events, run '${pkgs.k8s-local.expose-brigade-gateway.name}'"
    echo "To make gateway accessible from outside, run '${pkgs.k8s-local.create-localtunnel-for-brigade.name}'"
  '';
in
{
  options.kubernetes.cluster = {
    fresh-instance = mkOption {
      default = true;
    };
  };

  options.kubernetes.resources.apply = lib.mkOption {
    default = true;
  };

  options.environment = with types; mkOption {
    default = "local";
    type = enum ["local" "nixos"];
  };

  options.docker = {
    enable-registry = lib.mkOption {
      default = true;
    };
    upload-images = lib.mkOption {
      default = [];
      type = enum ["functions" "cluster"];
    };
  };

  options.brigade = {
    enable = lib.mkOption {
      default = true;
    };

    secret-key = lib.mkOption {
      default = "";
    };
  };
  options.bitbucket = {};

  options.shellHook = lib.mkOption {
    default = "";
    type = lib.types.lines;
  };

  options.packages = with types; lib.mkOption {
    default = [];
    type = listOf package;
  };

  options.warnings = with types; lib.mkOption {
    default = [];
  };

  options.errors = with types; lib.mkOption {
    default = [];
  };

  # k8s-cluster-operations.push-docker-images-to-local-cluster
  config = mkMerge [
    (mkIf true {
      packages = [
        get-help
      ];
      shellHook = ''
        ${pkgs.log.important "Your environment is: ${config.environment}"}
      '';
    })

    (mkIf (cfg.environment == "local") {
      packages = [
        pkgs.k8s-local.create-local-cluster-if-not-exists
        pkgs.k8s-cluster-operations.save-resources
      ];
      shellHook = ''
        ${pkgs.log.message "Checking existence of local cluster"}
        save-resources
      '';
    })

    (mkIf cfg.kubernetes.cluster.fresh-instance {
      packages = [
        pkgs.k8s-local.delete-local-cluster
      ];

      shellHook = ''
        ${pkgs.log.message "Running fresh instance of local cluster"}
      '';
    })

    (mkIf cfg.brigade.enable {
      packages = [
        pkgs.k8s-local.create-localtunnel-for-brigade
      ];

      shellHook = ''
        ${pkgs.log.message "Running integration with brigade"}
      '';

      warnings = mkIf (cfg.brigade.secret-key == "") [
        "You have to provide brigade shared secret to listen the repo hooks"
      ];
    })

    (mkIf cfg.kubernetes.resources.apply {
      packages = [
        pkgs.k8s-cluster-operations.apply-cluster-stack
        pkgs.k8s-cluster-operations.apply-functions-to-cluster
      ];

      shellHook = ''
        ${pkgs.log.message "Applying resources"}
      '';
    })
  ];
}