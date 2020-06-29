{ 
  lib, 
  pkgs, 
  modules ? import ./modules.nix, 
  extraLibs ? (pkgs.callPackage ./lib {}) 
}:
let
  defaultSpecialArgs = {
    inherit integration-modules;
    lib = lib // extraLibs;
  };

  eval = {
    module ? null,
    modules ? [module],
    specialArgs ? defaultSpecialArgs,
    ...
  }@attrs: 
    let
      attrs' = lib.filterAttrs (n: _: n != "module") attrs;
    in 
    lib.evalModules (lib.recursiveUpdate {
      inherit specialArgs;
      modules = [];
      args = {
        inherit pkgs;
      };
    } attrs');

  integration-modules = {
    inherit eval modules;
    lib = lib // extraLibs;
  };
in
  integration-modules
