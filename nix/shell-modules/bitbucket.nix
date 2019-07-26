{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
  ssh-location = cfg.bitbucket.ssh-keys.location;
  ssh-exists = builtins.pathExists ssh-location;
in
with lib;
rec {

  options.bitbucket = {
    enabled = mkOption {
      default = true;
    };

    ssh-keys = {
      location = mkOption {
        default = "";
        type = types.path;
      };
      pub = mkOption {
        default = "";
      };
      priv = mkOption {
        default = "";
      };
    };
  };

  config = mkIf cfg.bitbucket.enabled (mkMerge [
    (mkIf ssh-exists {
      bitbucket.ssh-keys.pub = builtins.readFile "${cfg.ssh-keys.location}.pub";
      bitbucket.ssh-keys.priv = builtins.readFile "${cfg.ssh-keys.location}";
    })

    (mkIf (!ssh-exists) {
      warnings = [
        "There is no ssh keys related to bitbucket, defined location in config '${toString ssh-location}'"
      ];
    })
  ]);
}