{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
in
with lib;
rec {

  options.terraform = {
    enable = mkOption {
      default = true;
    };

    # TODO make it more descriptive - what kind of fields it expec
    vars = mkOption {
      default = {};
    };

    backend-vars = mkOption {
      default = {};
    };

    # TODO think about it
    outputs = mkOption {
      default = {};
    };
  };

  config = mkIf (cfg.terraform.enable) (mkMerge [
    { checks = ["Enabling terraform module"]; }
    ({
      packages = with pkgs; [
        pkgs.terraform-with-plugins
      ];
    })
  ]);
}