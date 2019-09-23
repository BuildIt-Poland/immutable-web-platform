{config, pkgs, lib, kubenix, integration-modules, ...}: 
let
  resources = config.kubernetes.resources;
  priority = resources.priority;
in
with lib;
{
  imports = with integration-modules.modules; [
    bitbucket
  ];

  config = mkMerge [
    { 
      checks = ["Running operator perspective."]; 
      # FIXME align wording
      kubernetes.enabled = false;
      storage.enable = false;
      terraform.enable = true;
      packages = with pkgs; [
        nix-generators
      ];
    }
  ];
}