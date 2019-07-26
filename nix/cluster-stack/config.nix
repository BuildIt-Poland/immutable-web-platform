{ 
  config, 
  kubenix, 
  pkgs, 
  project-config,
  k8s-resources,
  ...
}@args:
(kubenix.evalModules {
  inherit args;
  modules = [
    ./module.nix
  ];
}).config