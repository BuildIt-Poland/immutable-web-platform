{sources, pkgs ? import <nixpkgs> {}, extraArgs ? {}}:
with pkgs;
let
  hostPkgs = import <nixpkgs> {};
  # pinned = import (hostPkgs.applyPatches {
  #   src = fetchFromGitHub {
  #     sha256 = sources.nixpkgs.sha256;
  #     repo = sources.nixpkgs.repo;
  #     owner = sources.nixpkgs.owner;
  #     rev = sources.nixpkgs.rev;
  #   };
  # }) ({} // extraArgs);
  patches = [./go-modules.patch];
  pinnedPkgs = sources.nixpkgs;
  patchedPkgs = hostPkgs.runCommand "nixpkgs-${pinnedPkgs.rev}"
    {
      inherit pinnedPkgs;
      inherit patches;
    }
    ''
      cp -r $pinnedPkgs $out
      chmod -R +w $out
      for p in $patches; do
        echo "Applying patch $p";
        patch -d $out -p1 < "$p";
      done
    '';
in
  import patchedPkgs extraArgs