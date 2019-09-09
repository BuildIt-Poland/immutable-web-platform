{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
in
with lib;
rec {

  options.shell = {
    enable = {
      tools = mkOption {
        default = true;
      };
    };

    tools = {
      enable = mkOption {
        default = true;
      };
      packages = mkOption {
        default = with pkgs;[
          watch
          remarshal
          yq
        ];
      };
    };
  };

  config = mkIf cfg.shell.tools.enable (mkMerge [
    ({
      checks = ["Enabling shell tools module"];

      packages = cfg.shell.tools.packages;

      # WHY: https://superuser.com/questions/1195553/installing-python3-on-macos-using-homebrew-has-error-failed-to-import-the-site
      shellHook = ''
        unset PYTHONPATH
      '';
    })
  ]);
}