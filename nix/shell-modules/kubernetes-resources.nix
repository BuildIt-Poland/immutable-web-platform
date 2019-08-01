{config, pkgs, kubenix, k8s-resources, lib, inputs, ...}:
let
  cfg = config;
in
with lib;
{

  imports = [
    ./kubernetes.nix
  ];

  options.kubernetes = {
    resources = { 
      list = mkOption {
        default = {};
      };
      generated = mkOption {
        default = {};
      };
    };
  };

  config = 
    (mkMerge [
      { checks = ["Enabling kubenix module"]; }
      {
        kubernetes.resources.generated = 
          let
            eval-kubenix = 
              name: modules: (kubenix.evalModules {
                args = {
                  inherit kubenix k8s-resources;
                  project-config = config;
                };
                inherit modules;
              });

            objects = 
              builtins.mapAttrs
                (name: modules: 
                  with kubenix.lib;
                  let
                    evaluated = (eval-kubenix name modules).config;
                    static = 
                      if builtins.hasAttr "static" evaluated.kubernetes
                        then helm.concat-json { jsons = evaluated.kubernetes.static; }
                        else [];
                  in rec {
                   crd = 
                    if builtins.hasAttr "crd" evaluated.kubernetes
                      then evaluated.kubernetes.crd 
                      else [];

                    images = 
                      if builtins.hasAttr "docker" evaluated
                        then evaluated.docker.images
                        else {};

                    raw = evaluated;

                    resources = 
                      evaluated.kubernetes.objects ++
                        helm.concat-json { jsons = static; };

                    yaml = 
                      {
                        crd = helm.jsons-to-yaml (helm.concat-json { jsons = lib.reverseList crd; });
                        objects = helm.jsons-to-yaml (lib.reverseList resources);
                      };
                  }
                )
                config.kubernetes.resources.list;
          in
            objects;
      }
    ]);
}