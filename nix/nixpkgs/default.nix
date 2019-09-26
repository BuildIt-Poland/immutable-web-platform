{sources, pkgs ? import <nixpkgs> {}, args ? {}}:
with pkgs;
let
  hostPkgs = import <nixpkgs> {};
  pinned = import (hostPkgs.applyPatches {
    src = fetchFromGitHub {
      sha256 = sources.nixpkgs.sha256;
      repo = sources.nixpkgs.repo;
      owner = sources.nixpkgs.owner;
      rev = sources.nixpkgs.rev;
    };
    patches = [./go-modules.patch];
  }) ({} // args);
in
  pinned