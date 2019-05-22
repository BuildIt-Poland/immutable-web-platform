{ env-config, kubenix, callPackage }:
(kubenix.evalModules {
    modules = [
      ./module.nix 
    ];
    # check = false;
    args = {
      inherit env-config;
      inherit callPackage;
    };
  }).config