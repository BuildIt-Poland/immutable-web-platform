{sources, callPackage, applyPatches}:
  callPackage (applyPatches {
    src = super.fetchFromGitHub {
      sha256 = sources.yarn2nix.sha256;
      repo = sources.yarn2nix.repo;
      owner = sources.yarn2nix.owner;
      rev = sources.yarn2nix.rev;
    };
    patches = [./yarn2nix.patch];
  }) {};