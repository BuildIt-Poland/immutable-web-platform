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

    authorEmail = mkOption {
      default = "";
    };

    rootFolder = mkOption {
      default = "";
    };

    domain = mkOption {
      default = "";
    };

    subdomains = mkOption {
      default = ["*"];
    };

    make-sub-domain = mkOption {
      default = null;      
    };

    hash = mkOption {
      default = ""; 
    };

    resources.yaml.folder = mkOption {
      default = "";
    };

    save-config = mkOption {
      default = true;
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

  config = mkMerge [
    ({ project.hash = 
        builtins.hashString "sha1" 
          (builtins.toJSON cfg.kubernetes.resources.list);
    })

    (mkIf cfg.project.save-config {
      packages = [
        (pkgs.writeScriptBin "save-config" ''
          echo ${builtins.toJSON (lib.filterAttrs (n: v: !(lib.isFunction v)) cfg.project)} \
            | ${pkgs.jq}/bin/jq . \
            > config.json
        '')
      ];

      actions.queue = [
        { priority = cfg.actions.priority.low; 
          action = ''
            save-config
          '';
        }
      ];
    })
  ];
}