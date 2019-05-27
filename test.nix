# INFO not going to use make-test since it requrie kvm - will be run in kind -> docker
{ nixpkgs }:
let
  pkgs = (import ./nix {}).pkgs;
  testFunction = { pkgs, ... }: {
    name = "test";

    nodes = {
    };

    testScript = ''
    '';
  };
  nixosTesting = import "${nixpkgs}/lib/testing.nix" {
    inherit pkgs;
    system = "x86_64-linux";
  };
in nixosTesting.makeTest testFunction