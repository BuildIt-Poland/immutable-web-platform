{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
in
with lib;
rec {

  options.docker = {
    enabled = mkOption {
      default = true;
    };

    upload-images-type = lib.mkOption {
      default = [];
      type = enum ["functions" "cluster"];
    };

    upload = lib.mkOption {
      default = false;
    };

    namespace = mkOption {
      default = "";
    };

    registry = mkOption {
      default = "docker.io/gatehub";
    };

    destination = mkOption {
      default = "docker://damianbaar"; # skopeo path transport://repo
    };

    tag = mkOption {
      default = "latest";
    };
  };

  # FIXME if local
  config = mkIf (cfg.docker.enabled && cfg.environment.isLocal) (mkMerge [
    { checks = ["Enabling docker module"]; }
    ({
      packages = with pkgs; [
        docker
        dgoss
      ];
    })
    (mkIf cfg.docker.upload {
      packages = with pkgs; [
        k8s-operations.push-docker-images-to-docker-deamon
      ];

      actions.queue = [{ 
        priority = cfg.actions.priority.docker; 
        action = ''
          push-docker-images-to-docker-deamon
        '';
      }];
    })
  ]);
}