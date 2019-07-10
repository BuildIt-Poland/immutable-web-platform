{ env-config, kubenix, pkgs, kubenix-infra-modules, callPackage, brigade-extension, remote-worker, charts }:
(kubenix.evalModules {
    modules = [
      ./module.nix
      { 
        docker.registry.url = env-config.docker.registry; 
      }
    ] ++ kubenix-infra-modules;
    args = {
      inherit env-config;
      inherit callPackage;
      inherit brigade-extension;
      inherit remote-worker;
      inherit charts;
    };
  }).config