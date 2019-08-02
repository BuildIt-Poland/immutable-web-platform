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
      { checks = ["Enabling kubenix modules: ${toString (builtins.attrNames config.kubernetes.resources.list)}"]; }
      (let
        eval-kubenix = 
          name: modules: (kubenix.evalModules {
            args = {
              inherit kubenix k8s-resources;
              project-config = config;
            };
            modules = modules;
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
                            crd = helm.jsons-to-yaml (helm.concat-json { jsons = crd; });
                            objects = helm.jsons-to-yaml (resources);
                          };
                      })
                evaluated-modules;

            modules-content = 
              builtins.mapAttrs
                (name: evaluated:
                  let
                    get-value = path: 
                      if lib.hasAttrByPath path evaluated
                        then lib.getAttrFromPath path evaluated
                        else {};
                  in
                  {
                    packages = get-value ["module" "packages"];
                    tests = get-value ["module" "tests"] ;
                    scripts = get-value ["module" "scripts"];
                    docker = get-value ["docker" "images"];
                  }
                )
              evaluated-modules;
          in
            (lib.foldl lib.recursiveUpdate {} (builtins.attrValues modules-content)) 
          // { kubernetes = kubernetes-resources; };
        
        packages = 
          with cfg.modules;
            (tests ++ scripts);

        test.run =
          lib.concatMapStringsSep "\n" 
            (test: "${test}/bin/${test.name}") 
            cfg.modules.tests;
      })
    ]);
}