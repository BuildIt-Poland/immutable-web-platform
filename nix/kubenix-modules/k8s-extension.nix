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
    # FIXME
    skip = mkOption {
      default = false;
      description = ''
        Whether kubernetes resource should be automatically applied.
      '';
    };

    crd = mkOption {
      default = [];
    };
    static = mkOption {
      default = [];
    };
    patches = mkOption {
      default = [];
      description = ''
        Patches agains defined kubernetes resources - try to customize with helm first.
      '';
    };
  };

  options.module = {
    packages = mkOption {
      default = {};
    };
    tests = mkOption {
      default = [];
    };
    scripts = mkOption {
      default = [];
    };
  };

  config = {
    kubernetes.resourceOrder = [
      "CustomResourceDefinition" 
      "Namespace" 
    ];
  };
}