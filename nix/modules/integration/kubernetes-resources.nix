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
      getByName = mkOption {
        default = x: null;
      };
      priority = 
        let
          mkPriority = x: name: "${toString x}-${name}";
        in
        mkOption {
          default = {
            high = mkPriority 0;
            mid = mkPriority 1;
            low = mkPriority 2;
            skip = name: "skip-${name}";
          };
        };
    };
  };

  config = 
    mkIf cfg.kubernetes.enabled (mkMerge [
      { checks = ["Enabling kubenix modules: ${toString (builtins.attrNames config.kubernetes.resources.list)}"]; }
      ({
        binary-store-cache = builtins.filter lib.isDerivation (builtins.attrValues k8s-resources);
      })
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
                    get-value = path: fallback:
                      if lib.hasAttrByPath path evaluated
                        then lib.getAttrFromPath path evaluated
                        else fallback;
                  in
                  {
                    packages = get-value ["module" "packages"] {};
                    docker = get-value ["docker" "images"] {};
                    tests = {"${name}" = get-value ["module" "tests"] [];};
                    scripts = {"${name}" = get-value ["module" "scripts"] [];};
                    patches = {"${name}" = get-value ["kubernetes" "patches"] [];};
                  }
                )
              evaluated-modules;
            
            merged = (lib.foldl lib.recursiveUpdate {} (builtins.attrValues modules-content));
            flatten = x: lib.flatten (builtins.attrValues x);
            # script and tests to array
            # FIXME ... no comment
            combine-script-and-tests = lib.mapAttrs (name: v: 
              if name == "scripts" then (flatten v)
              else if name == "tests" then (flatten v)
              else if name == "patches" then (flatten v)
              else v
            ) merged;
          in
          combine-script-and-tests // { kubernetes = kubernetes-resources; };
        
        packages = 
          with cfg.modules;
            (tests ++ scripts ++ patches);

        test.run =
          lib.concatMapStringsSep "\n" 
            (test: "${test}/bin/${test.name}") 
            cfg.modules.tests;

      })

      # patches
      (let
          patches = lib.concatMapStringsSep "\n" 
            (patch: "${patch}/bin/${patch.name}") 
            cfg.modules.patches;
        in
        {
          packages = [(pkgs.writeScriptBin "apply-kubernetes-patches" ''${patches}'')];
          kubernetes.patches.run = patches;
      })

      ({
        # FIXME BUG this should be improved as if folder does not have priority and have - then
        # name will be simplified
        # WORKAROUND use lodash _
        kubernetes.resources.getByName = 
          let
            modules = cfg.kubernetes.resources.list;
            names = builtins.attrNames modules;
            removePriority = x: lib.last (lib.splitString "-" x);
            modulesArr = builtins.map (x: {"${removePriority x}"= "${x}";}) names;
            modulesMap = lib.fold lib.mergeAttrs {} modulesArr;
          in
            byName:
              lib.getAttr (lib.getAttr byName modulesMap) config.modules.kubernetes;
      })
    ]);
}