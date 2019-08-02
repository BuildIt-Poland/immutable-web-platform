{config, pkgs, kubenix, k8s-resources, lib, inputs, ...}:
let
  cfg = config;
in
with lib;
{

  imports = [
    ./kubernetes.nix
    ./module-descriptor.nix
  ];

  options.kubernetes = {
    resources = { 
      list = mkOption {
        default = {};
      };
    };
  };

  config = 
    (mkMerge [
      { checks = ["Enabling kubenix modules: ${builtins.attrNames config.kubernetes.resources.list}"]; }
      (let
        eval-kubenix = 
          name: modules: (kubenix.evalModules {
            args = {
              inherit kubenix k8s-resources;
              project-config = config;
            };
            inherit modules;
          });
        # evaluate configs only once
        evaluated-modules = 
          builtins.mapAttrs
            (name: modules: 
              with kubenix.lib;
              (eval-kubenix name modules).config
            )
            config.kubernetes.resources.list;
      in
      {
        modules = 
          let
            kubernetes-resources = 
              builtins.mapAttrs
                (name: evaluated: 
                  with kubenix.lib;
                  let
                    static = 
                      if builtins.hasAttr "static" evaluated.kubernetes
                        then helm.concat-json { jsons = evaluated.kubernetes.static; }
                        else [];
                  in rec {
                      crd = 
                        if builtins.hasAttr "crd" evaluated.kubernetes
                          then evaluated.kubernetes.crd 
                          else [];

                        raw = evaluated;

                        resources = 
                          evaluated.kubernetes.objects ++ static;

                        yaml = 
                          {
                            crd = helm.jsons-to-yaml (helm.concat-json { jsons = lib.reverseList crd; });
                            objects = helm.jsons-to-yaml (lib.reverseList resources);
                          };
                      })
                evaluated-modules;

            modules-content = 
              builtins.mapAttrs
                (name: evaluated:
                  {
                    packages = 
                      if lib.hasAttrByPath ["module" "packages"] evaluated
                        then evaluated.module.packages
                        else {};

                    tests = 
                      if lib.hasAttrByPath ["module" "tests"] evaluated
                        then {"${name}" = evaluated.module.tests;}
                        else {};

                  docker = 
                    if builtins.hasAttr "docker" evaluated
                      then evaluated.docker.images
                      else {};
                  }
                )
              evaluated-modules;
          in
            (lib.foldl lib.recursiveUpdate {} (builtins.attrValues modules-content)) 
          // { kubernetes = kubernetes-resources; };
      })
    ]);
}