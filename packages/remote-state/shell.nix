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
    pkgs.nodejs
  ];
  PROJECT_NAME = env-config.projectName;
  shellHook = '''';
}