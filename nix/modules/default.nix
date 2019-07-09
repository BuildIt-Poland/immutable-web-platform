{ lib, pkgs }:
{
  # INFO: i.e. config => ({config,...}: { config.kubernetes.resources.apply = true; })
  bootstrap =
    config:
      (lib.evalModules {
        modules = [
          ./bootstrap-module.nix
          config 
        ];
        args = {
          inherit pkgs;
        };
      });
}