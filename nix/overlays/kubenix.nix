{sources}:
self: super: rec {
  kubenix = 
    let
      kube = (super.callPackage sources.kubenix {});
      extra-modules = import ../kubenix-modules;
      extra-lib = super.callPackage ../kubenix-lib {};
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