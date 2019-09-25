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
    { checks = ["Running hydra perspective."]; }
    ({
      # kubernetes.enabled = false;
      # aws.enabled = true;
      storage.enable = false;
      terraform.enable = false;
    })
  ];
}