{config, pkgs, lib, kubenix, integration-modules, ...}: 
let
  resources = config.kubernetes.resources;
  priority = resources.priority;
in
with lib;
{
  imports = with integration-modules.modules; [
  ];

  config = mkMerge [
    { 
      checks = ["Running lorri perspective."]; 
      # FIXME align wording
      packages = with pkgs; [
        nixos-generators
        kubectl-virtctl
      ];
    }
  ];
}