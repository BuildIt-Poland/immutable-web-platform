{ lib }:
{
  # INFO: i.e. config => ({config,...}: { config.kubernetes.resources.apply = true; })
  bootstrap =
    config:
      (lib.evalModules {
        modules = [
          ./shell-module.nix
          config 
        ];
      }).config;
}