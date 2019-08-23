{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
in
with lib;
rec {

  options.load-balancer = {
    enabled = mkOption {
      default = true;
    };
    service-annotations = mkOption {
      # this is function now - so so
      default = {};
    };
  };

  config = mkIf cfg.load-balancer.enabled (mkMerge [
    ({
      checks = ["Enabling load-balancer module"];
    })
  ]);
}