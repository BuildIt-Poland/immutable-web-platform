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

    upload-images = lib.mkOption {
      default = [];
      type = enum ["functions" "cluster"];
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

  config = mkIf cfg.docker.enabled (mkMerge [
    { checks = ["Enabling docker module"]; }
    ({
      packages = with pkgs; [
        docker
        k8s-operations.push-docker-images-to-local-cluster
      ];
      actions.queue = [{ 
        priority = cfg.actions.priority.crd; 
        action = ''
          push-docker-images-to-local-cluster
        '';
      }];
    })
  ]);
}