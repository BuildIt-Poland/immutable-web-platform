{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
in
with lib;
rec {
  options.project = {
    name = mkOption {
      default = "";
    };

    version = mkOption {
      default = "";
    };

    author-email = mkOption {
      default = "";
    };

    domain = mkOption {
      default = "";
    };

    hash = mkOption {
      default = ""; 
    };

    resources.yaml.folder = mkOption {
      default = "";
    };

    repositories = {
      k8s-resources = mkOption {
        default = "";
      };
      code-repository = mkOption {
        default = "";
      };
    };
  };

  config = {
    project.hash = 
      builtins.hashString "sha1" 
        (builtins.toJSON cfg.kubernetes.resources.list);
  };
}