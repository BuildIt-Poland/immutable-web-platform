{pkgs}: {
  bitbucket = pkgs.callPackage ./bitbucket.nix {};
  sops = pkgs.callPackage ./sops.nix {};
}