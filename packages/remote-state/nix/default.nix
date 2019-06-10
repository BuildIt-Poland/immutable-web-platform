{ callPackage }:
let
  package = callPackage ./package.nix {};
in {
  inherit package;
}