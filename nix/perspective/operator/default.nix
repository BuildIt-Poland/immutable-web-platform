{config, pkgs, lib, kubenix, integration-modules, ...}: 
let
  resources = config.kubernetes.resources;
  priority = resources.priority;
in
with lib;
{
  imports = with integration-modules.modules; [
    bitbucket
    terraform
    brigade
  ];

  config = mkMerge [
    { 
      checks = ["Running operator perspective."]; 

      # FIXME align wording
      kubernetes.enabled = false;
      brigade.enabled = false;

      storage.enable = false;
      terraform.enable = true;

      packages = with pkgs; [
        nixos-generators
        kubectl-virtctl
        kube-psp-advisor
      ];
    }
  ];
}