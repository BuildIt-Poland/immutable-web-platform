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
      kubernetes.enabled = false;
      kubernetes.tools.enable = false;
      storage.enable = false;
      terraform.enable = false;
    }
  ];
}