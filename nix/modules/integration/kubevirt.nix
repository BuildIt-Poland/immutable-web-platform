# https://github.com/kubevirt/kubevirt/issues/2221
# https://github.com/kubevirt/kubevirt/files/3197582/psp.yaml.txt
{config, pkgs, lib, inputs, ...}:
let
  cfg = config;
in
with lib;
rec {

  options.kubevirt = {
    enabled = mkOption {
      default = true;
    };
  };

  config = mkIf cfg.bitbucket.enabled (mkMerge [{
      checks = ["Enabling kubevirt module"];
    }

    ({
      packages = [
        kubectl-virtctl 
      ];
    })
  ]);
}