{
  description = "A flake for building polyglot platform";

  # inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-20.03;

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils } : 
    flake-utils.lib.eachDefaultSystem (system:
    let pkgs = nixpkgs.legacyPackages.${system}; in {
      # defaultPackage = (import ./shell.nix { inherit pkgs; });
      devShell = (import ./shell.nix { inherit pkgs; });
    });
  # {
  #   defaultPackage.x86_64-linux = {};
  #   defaultPackage.x86_64-darwin = 
  #     with import nixpkgs { system = "x86_64-darwin"; };
  #     stdenv.mkDerivation {
  #       name = "polyglot-platform";
  #       src = self;
  #       buildPhase = "echo 'test'";
  #       installPhase = "mkdir -p $out/bin";
  #     };
  # };
}
