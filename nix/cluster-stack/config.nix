{ env-config, kubenix, pkgs, callPackage }:
(kubenix.evalModules {
    modules = [
      ./module.nix 
    ];
    args = {
      inherit env-config;
      inherit callPackage;
    };
  }).config