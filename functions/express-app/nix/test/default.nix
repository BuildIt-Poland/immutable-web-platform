{pkgs, ...}: [
  (pkgs.callPackage ./configuration-tests.nix {})
]