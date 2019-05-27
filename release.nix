{
  nixpkgs ? (import ./nix/sources.nix).nixpkgs
}:
{
  integrationTest = import ./test.nix {
    inherit nixpkgs;
  };
}