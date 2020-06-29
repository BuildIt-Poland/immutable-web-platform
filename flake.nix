{
  description = "A flake for building polyglot platform";

  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-20.03;

  outputs = { self, nixpkgs } : {
    defaultPackage.x86_64-linux = {};
    defaultPackage.x86_64-darwin = 
      with import nixpkgs { system = "x86_64-darwin"; };
      stdenv.mkDerivation {
        name = "polyglot-platform";
        src = self;
        buildPhase = "echo 'test'";
        installPhase = "mkdir -p $out/bin";
      };
  };
}
