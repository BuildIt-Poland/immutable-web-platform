self: super: 
let
  functionPackages = super.find-files-in-folder "/functions" "nix/default.nix";
in
rec {
  functions = builtins.mapAttrs (x: y: super.callPackage y {}) functionPackages;
}