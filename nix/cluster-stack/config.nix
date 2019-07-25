{ 
  env-config, 
  kubenix, 
  pkgs, 
  callPackage, 
  brigade-extension, 
  remote-worker, 
  k8s-resources,
  ...
}@args:
(kubenix.evalModules {
  inherit args;
  modules = [
    ./module.nix
  ];
}).config