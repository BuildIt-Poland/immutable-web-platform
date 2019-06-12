{
  pkgs ? (import ../../nix {}).pkgs,
}:
with pkgs;
let
  package = (pkgs.callPackage ./nix {}).package;
in
mkShell {
  buildInputs = [
    package.remote-state-cli
    package.remote-state-aws-infra
  ];
  shellHook = ''
  '';
}