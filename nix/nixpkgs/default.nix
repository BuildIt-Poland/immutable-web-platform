{sources, extraArgs ? {}}:
let
  hostPkgs = import <nixpkgs> {};
  patches = [./go-modules.patch];
  pinnedPkgs = sources.nixpkgs;
  # exactly the same what applyPatches is doing but applyPatches does not work on hydra - not for nixpkgs - investigate
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