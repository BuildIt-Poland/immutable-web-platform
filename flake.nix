{
  description = "A flake for building polyglot platform";

  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-20.03;

  # inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs } : {
    # defaultPackage.legacyPackages.x86_64-darwin.devShell = (import ./shell.nix { pkgs = nixpkgs; });
    # defaultPackage.x86_64-darwin.

    defaultPackage.x86_64-darwin = 
      let 
        pkgs = import nixpkgs { system = "x86_64-darwin"; };
      in
      with pkgs;
      stdenv.mkDerivation {
        name = "polyglot-platform";
        src = self;
        devShell = (import ./shell.nix { inherit pkgs; });
        # buildPhase = "echo 'test'";
        # installPhase = "mkdir -p $out/bin";
      };
  };
    # flake-utils.lib.eachDefaultSystem (system:
    # let pkgs = nixpkgs.legacyPackages.${system}; in {
    #   # defaultPackage = (import ./shell.nix { inherit pkgs; });
    #   devShell = (import ./shell.nix { inherit pkgs; });
    # });
  # {
  #   defaultPackage.x86_64-linux = {};
  # };
}
