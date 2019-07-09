{config, lib, ...}:
with lib;
let
  cfg = config;
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

  options.shellHook = lib.mkOption {
    default = "";
  };

  config = {
    shellHook = mkMerge [
      (mkIf cfg.kubernetes.cluster.fresh-instance ''
        echo "running fresh instance"
      '')
      (mkIf cfg.kubernetes.resources.apply ''
        echo "applying resources"
      '')
    ];
  };
}