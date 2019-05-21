{ env-config, kubenix, callPackage }:
(kubenix.evalModules {
    modules = [
      ./module.nix 
    ];
    args = {
      inherit env-config;
      inherit callPackage;
    };
  }).config