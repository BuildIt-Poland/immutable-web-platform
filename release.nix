{
  nixpkgs ? (import ./nix/sources.nix).nixpkgs
}:
{
  integrationTest = import ./infra.test.nix {
    inherit nixpkgs;
  };
}