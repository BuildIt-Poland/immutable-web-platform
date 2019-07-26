{ 
  pkgs, 
  kubenix, 
  callPackage, 
  writeScriptBin, 
  lib, 
  docker,
  project-config
}@args:
with kubenix.lib;
rec {
  package = callPackage ./package.nix {};

  config = (kubenix.evalModules {
    inherit args;
    module = ./module.nix;
  }).config;

  images = config.docker.export;
  yaml = helm.jsons-to-yaml config.kubernetes.objects;
}