{pkgs, docker, ...}: [
  (pkgs.callPackage ./configuration-tests.nix { inherit docker; })
]