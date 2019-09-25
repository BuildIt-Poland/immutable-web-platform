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
    { checks = ["Running builder perspective."]; }
    ({
      bitbucket.k8s-resources = {
        enable = true;
        repository = "k8s-infra-descriptors";
      };
    })
  ];
}