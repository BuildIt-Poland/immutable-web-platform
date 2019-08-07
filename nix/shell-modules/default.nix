{ 
  lib, 
  pkgs, 
  modules ? import ./modules.nix, 
  extraLibs ? (pkgs.callPackage ./lib {}) 
}:
let
  defaultSpecialArgs = {
    inherit shell-modules;
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

  shell-modules = {
    inherit eval modules;
  };
in
  shell-modules