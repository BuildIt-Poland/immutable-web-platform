{ env-config, kubenix, callPackage }:
(kubenix.evalModules {
    modules = [
      ./module.nix 
    ];
    # check = true;
    args = {
      inherit env-config;
      inherit callPackage;
    };
  }).config