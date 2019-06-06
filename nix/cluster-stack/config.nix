{ env-config, kubenix, pkgs, callPackage, brigade-extension, remote-worker }:
(kubenix.evalModules {
    modules = [
      ./module.nix
      { 
        docker.registry.url = env-config.docker.registry; 
      }
    ];
    args = {
      inherit env-config;
      inherit callPackage;
      inherit brigade-extension;
      inherit remote-worker;
    };
  }).config