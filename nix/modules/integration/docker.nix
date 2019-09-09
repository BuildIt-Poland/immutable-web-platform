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

    imageName = mkOption {
      default = name: name;
    };

    imageTag = mkOption {
      default = name: name;
    };

    destination = mkOption {
      default = "docker://damianbaar"; # skopeo path transport://repo
    };

    tag = mkOption {
      default = "latest";
    };
  };

  # FIXME if local - it should live in separate module - minikube-env
  config = mkIf (cfg.docker.enabled) (mkMerge [
    { checks = ["Enabling docker module"]; }
    ({
      packages = with pkgs; [
        docker
        dgoss
      ];
    })
  ]);
}