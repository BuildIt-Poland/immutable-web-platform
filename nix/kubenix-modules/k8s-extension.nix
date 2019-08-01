# this is a bridge between shell-modules and kubenix
{ 
  config, 
  pkgs,
  lib, 
  kubenix, 
  k8s-resources ? pkgs.k8s-resources,
  project-config,
  ... 
}:
with pkgs;
with lib;
rec {

  imports = with kubenix.modules; [ 
    k8s
  ];

  options.kubernetes = {
    crd = mkOption {
      default = [];
    };
    static = mkOption {
      default = [];
    };
    packages = mkOption {
      default = {};
    };
  };

  config = {
    kubernetes.resourceOrder = [
      "CustomResourceDefinition" 
      "Namespace" 
    ];
  };
}