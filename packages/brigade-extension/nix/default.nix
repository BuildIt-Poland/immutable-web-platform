{ callPackage }:
let
  docker-image = callPackage ./image.nix {};
in {
  inherit docker-image;
}