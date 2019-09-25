{sources, pkgs ? import <nixpkgs> {}, args ? {}}:
with pkgs;
  pkgs.callPackage (pkgs.applyPatches {
    src = fetchFromGitHub {
      sha256 = sources.nixpkgs.sha256;
      repo = sources.nixpkgs.repo;
      owner = sources.nixpkgs.owner;
      rev = sources.nixpkgs.rev;
    };
    patches = [./go-modules.patch];
  }) ({} // args)