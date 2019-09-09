{sources}:
self: super: rec {
  lib = super.lib.recursiveUpdate super.lib (import ./helpers { callPackage = super.callPackage; });

  kubenix = 
    let
      kube = (super.callPackage sources.kubenix {});
      extra-modules = import ../modules/kubernetes;
      extra-lib = super.callPackage ../lib/kubenix {};
      kubenix = super.lib.recursiveUpdate 
        kube   
        ({ 
          modules = extra-modules;
          lib = extra-lib;
          # INFO: wrapping function and injecting extended kubenix module version
          evalModules = {...}@args: kube.evalModules (args // {
            specialArgs = {inherit kubenix;};
          });
        });
    in
      kubenix;
}